module mv

import math { clamp, max }
import raylib as rl { Color }

pub enum GradientInterpolation {
	constant
	linear
	cubic          // Catmull-Rom per channel
	monotone_cubic // Fritsch-Carlson, prevents overshoots
}

pub struct GradientStop {
pub mut:
	offset f32
	color  Color
}

pub struct Gradient {
pub mut:
	stops               []GradientStop
	interpolation       GradientInterpolation = .linear
	interpolation_curve ?&BakedCurve
}

pub fn Gradient.new() Gradient {
	return Gradient{}
}

// evenly space a list of colors across a range of 0..1
pub fn Gradient.from_colors(colors []Color) Gradient {
	mut g := Gradient{}
	n := colors.len
	if n == 0 {
		return g
	}
	for i, c in colors {
		g.stops << GradientStop{
			offset: f32(i) / f32(max(n - 1, 1))
			color:  c
		}
	}
	return g
}

// bakes the gradient to a n×1 Texture2D, sampling left to right across 0..1.
// the returned texture must be unloaded with rl.unload_texture when done.
pub fn (g &Gradient) bake(resolution int) rl.Texture2D {
	assert resolution >= 2
	img := gen_image_gradient_linear(resolution, 1, g, Vec2{0.0, 0.5}, Vec2{1.0, 0.5})
	tex := rl.load_texture_from_image(img)
	rl.unload_image(img)
	return tex
}

pub fn (mut g Gradient) add_stop(offset f32, color Color) {
	g.stops << GradientStop{
		offset: f32(clamp(offset, 0.0, 1.0))
		color:  color
	}
	g.sort_stops()
}

pub fn (mut g Gradient) remove_stop(idx int) {
	g.stops.delete(idx)
}

pub fn (mut g Gradient) set_stop_color(idx int, color Color) {
	g.stops[idx].color = color
}

pub fn (mut g Gradient) set_stop_offset(idx int, offset f32) {
	g.stops[idx].offset = f32(clamp(offset, 0.0, 1.0))
	g.sort_stops()
}

pub fn (mut g Gradient) sort_stops() {
	g.stops.sort(a.offset < b.offset)
}

pub fn (g &Gradient) sample(t f32) Color {
	if g.stops.len == 0 {
		return Color{}
	}
	if g.stops.len == 1 {
		return g.stops[0].color
	}

	tc := f32(clamp(t, 0.0, 1.0))

	if tc <= g.stops[0].offset {
		return g.stops[0].color
	}
	last := g.stops[g.stops.len - 1]
	if tc >= last.offset {
		return last.color
	}

	// finding bracketing segment
	mut lo := 0
	for i in 0 .. g.stops.len - 1 {
		if tc >= g.stops[i].offset && tc <= g.stops[i + 1].offset {
			lo = i
			break
		}
	}
	hi := lo + 1
	span := g.stops[hi].offset - g.stops[lo].offset
	mut seg_t := if span > 0.0 { (tc - g.stops[lo].offset) / span } else { 0.0 }

	if curve := g.interpolation_curve {
		seg_t = curve.sample(seg_t)
	}

	return match g.interpolation {
		.constant { g.stops[lo].color }
		.linear { rl.color_lerp(g.stops[lo].color, g.stops[hi].color, seg_t) }
		.cubic { g.sample_cubic(lo, hi, seg_t) }
		.monotone_cubic { g.sample_monotone(lo, hi, seg_t) }
	}
}

// Catmull-Rom: fetch four control points, clamping at boundaries
fn (g &Gradient) sample_cubic(lo int, hi int, t f32) Color {
	p1 := g.stops[lo].color
	p2 := g.stops[hi].color
	p0 := if lo > 0 { g.stops[lo - 1].color } else { p1 }
	p3 := if hi < g.stops.len - 1 { g.stops[hi + 1].color } else { p2 }
	return catmull_rom_color(p0, p1, p2, p3, t)
}

fn catmull_rom_f(p0 f32, p1 f32, p2 f32, p3 f32, t f32) f32 {
	t2 := t * t
	t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 +
		3.0 * p1 - 3.0 * p2 + p3) * t3)
}

fn catmull_rom_color(p0 Color, p1 Color, p2 Color, p3 Color, t f32) Color {
	return Color{
		r: u8(clamp(catmull_rom_f(p0.r, p1.r, p2.r, p3.r, t), 0.0, 255.0))
		g: u8(clamp(catmull_rom_f(p0.g, p1.g, p2.g, p3.g, t), 0.0, 255.0))
		b: u8(clamp(catmull_rom_f(p0.b, p1.b, p2.b, p3.b, t), 0.0, 255.0))
		a: u8(clamp(catmull_rom_f(p0.a, p1.a, p2.a, p3.a, t), 0.0, 255.0))
	}
}

// Fritsch-Carlson monotone cubic interpolation for one channel.
// Takes the full slice of (x, y) knots plus the already-found segment [lo, hi]
// and local t, so we only allocate tangents once per sample call via the
// per-channel wrapper below.
fn fc_channel_with_tangents(ys []f32, ms []f32, xs []f32, lo int, hi int, t f32) f32 {
	span := xs[hi] - xs[lo]
	return hermite(ys[lo], ms[lo] * span, ys[hi], ms[hi] * span, t)
}

fn fc_tangents(xs []f32, ys []f32) []f32 {
	n := xs.len
	mut d := []f32{len: n - 1}
	for k in 0 .. n - 1 {
		dx := xs[k + 1] - xs[k]
		d[k] = if dx > 1e-9 { (ys[k + 1] - ys[k]) / dx } else { f32(0.0) }
	}
	mut m := []f32{len: n}
	m[0] = d[0]
	m[n - 1] = d[n - 2]
	for k in 1 .. n - 1 {
		m[k] = (d[k - 1] + d[k]) * 0.5
	}
	for k in 0 .. n - 1 {
		if math.abs(d[k]) < 1e-9 {
			m[k] = 0.0
			m[k + 1] = 0.0
			continue
		}
		alpha := m[k] / d[k]
		beta := m[k + 1] / d[k]
		h := math.sqrtf(alpha * alpha + beta * beta)
		if h > 3.0 {
			tau := 3.0 / h
			m[k] = tau * alpha * d[k]
			m[k + 1] = tau * beta * d[k]
		}
	}
	return m
}

fn (g &Gradient) sample_monotone(lo int, hi int, t f32) Color {
	mut xs := []f32{len: g.stops.len}
	mut rs := []f32{len: g.stops.len}
	mut gs_ := []f32{len: g.stops.len}
	mut bs := []f32{len: g.stops.len}
	mut as_ := []f32{len: g.stops.len}
	for i, s in g.stops {
		xs[i] = s.offset
		rs[i] = f32(s.color.r)
		gs_[i] = f32(s.color.g)
		bs[i] = f32(s.color.b)
		as_[i] = f32(s.color.a)
	}
	mr := fc_tangents(xs, rs)
	mg := fc_tangents(xs, gs_)
	mb := fc_tangents(xs, bs)
	ma := fc_tangents(xs, as_)

	return Color{
		r: u8(clamp(fc_channel_with_tangents(rs, mr, xs, lo, hi, t), 0.0, 255.0))
		g: u8(clamp(fc_channel_with_tangents(gs_, mg, xs, lo, hi, t), 0.0, 255.0))
		b: u8(clamp(fc_channel_with_tangents(bs, mb, xs, lo, hi, t), 0.0, 255.0))
		a: u8(clamp(fc_channel_with_tangents(as_, ma, xs, lo, hi, t), 0.0, 255.0))
	}
}
