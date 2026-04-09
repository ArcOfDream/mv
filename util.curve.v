module mv

import math { clamp }

// CurvePoint stores a position in curve space and left/right tangents for assymetric handles
pub struct CurvePoint {
pub mut:
	pos       Vec2
	tangent_l f32
	tangent_r f32
}

pub struct Curve {
pub mut:
	points []CurvePoint
	// ranges to clamp output against after sampling
	min_value f32
	max_value f32 = 1.0
}

pub fn Curve.new() Curve {
	return Curve{}
}

// flat line at y = 0.5
pub fn Curve.flat(y f32) Curve {
	mut c := Curve{}
	c.add_point(Vec2{0.0, y}, 0.0, 0.0)
	c.add_point(Vec2{1.0, y}, 0.0, 0.0)
	return c
}

// straight diagonal — identity remap, same as no curve at all
pub fn Curve.linear() Curve {
	mut c := Curve{}
	c.add_point(Vec2{0.0, 0.0}, 1.0, 1.0)
	c.add_point(Vec2{1.0, 1.0}, 1.0, 1.0)
	return c
}

// smooth S-curve (ease-in-out)
pub fn Curve.ease_in_out() Curve {
	mut c := Curve{}
	c.add_point(Vec2{0.0, 0.0}, 0.0, 0.0)
	c.add_point(Vec2{0.5, 0.5}, 1.0, 1.0)
	c.add_point(Vec2{1.0, 1.0}, 0.0, 0.0)
	return c
}

pub fn (mut c Curve) add_point(pos Vec2, tangent_l f32, tangent_r f32) {
	c.points << CurvePoint{
		pos:       Vec2{f32(clamp(pos.x, 0, 1)), pos.y}
		tangent_l: tangent_l
		tangent_r: tangent_r
	}
	c.sort_points()
}

pub fn (mut c Curve) remove_point(idx int) {
	c.points.delete(idx)
}

pub fn (mut c Curve) set_point_position(idx int, pos Vec2) {
	c.points[idx].pos = Vec2{f32(clamp(pos.x, 0.0, 1.0)), pos.y}
	c.sort_points()
}

pub fn (mut c Curve) set_point_tangents(idx int, left f32, right f32) {
	c.points[idx].tangent_l = left
	c.points[idx].tangent_r = right
}

pub fn (mut c Curve) sort_points() {
	c.points.sort(a.pos.x < b.pos.x)
}

// samples the curve's y value at position x, clamps to min and max values
pub fn (c &Curve) sample(x f32) f32 {
	if c.points.len == 0 {
		return 0
	}

	if c.points.len == 1 {
		return f32(clamp(c.points[0].pos.y, c.min_value, c.max_value))
	}

	tx := f32(clamp(x, 0, 1))

	// edge clamping
	if tx <= c.points[0].pos.x {
		return f32(clamp(c.points[0].pos.y, c.min_value, c.max_value))
	}
	last := c.points.last()
	if tx >= last.pos.x {
		return f32(clamp(last.pos.y, c.min_value, c.max_value))
	}

	// finding the bracketing segment
	mut lo := 0
	for i in 0 .. c.points.len - 1 {
		if tx >= c.points[i].pos.x && tx <= c.points[i + 1].pos.x {
			lo = i
			break
		}
	}

	hi := lo + 1
	p0 := c.points[lo]
	p1 := c.points[hi]
	span := p1.pos.x - p0.pos.x
	t := if !span.eq_epsilon(0) { (tx - p0.pos.x) / span } else { 0 }
	y := hermite(p0.pos.y, p0.tangent_r * span, p1.pos.y, p1.tangent_l * span, t)
	return f32( clamp(y, c.min_value, c.max_value) )
}

// same sampling, but without clamping to bounds
pub fn (c &Curve) sample_unbound(x f32) f32 {
	if c.points.len == 0 { return 0.0 }
	if c.points.len == 1 { return c.points[0].pos.y }

	tx := f32( clamp(x, 0.0, 1.0) )

	if tx <= c.points[0].pos.x { return c.points[0].pos.y }
	last := c.points.last()
	if tx >= last.pos.x { return last.pos.y }

	mut lo := 0
	for i in 0 .. c.points.len - 1 {
		if tx >= c.points[i].pos.x && tx <= c.points[i + 1].pos.x {
			lo = i
			break
		}
	}
	hi := lo + 1
	p0 := c.points[lo]
	p1 := c.points[hi]
	span := p1.pos.x - p0.pos.x
	t := if !span.eq_epsilon(0) { (tx - p0.pos.x) / span } else { 0 }
	return hermite(p0.pos.y, p0.tangent_r * span, p1.pos.y, p1.tangent_l * span, t)
}

// cubic hermite basis
fn hermite(y0 f32, m0 f32, y1 f32, m1 f32, t f32) f32 {
	t2 := t * t
	t3 := t2 * t
	h00 := 2.0 * t3 - 3.0 * t2 + 1.0
	h10 := t3 - 2.0 * t2 + t
	h01 := -2.0 * t3 + 3.0 * t2
	h11 := t3 - t2
	return h00 * y0 + h10 * m0 + h01 * y1 + h11 * m1
}
