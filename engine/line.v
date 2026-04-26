module engine

import raylib as rl
import math { clamp }
import core { BakedCurve, Gradient, Vec2 }
import resourcemanager { Handle, TextureResource }

pub enum LineJointMode as u8 {
	// extends both segment edges to their intersection point.
	// spikes are clamped to line_max_miter_scale * half_width
	miter
	// cuts the joint with a flat bevel triangle
	bevel
	// fills the joint with a small triangle fan (smooth, more geometry)
	round
}

pub enum LineCapMode as u8 {
	// no extension beyond the endpoint
	flat
	// extends the endpoint outward by half_width, producing a square tip
	square
	// rounds the endpoint with a triangle fan
	round
}

pub enum LineTextureMode as u8 {
	// texture is stretched to fit the full length of the line once
	stretch
	// texture repeats along the line based on its pixel width
	tile
}

const line_max_miter_scale = f32(4.0)
const line_round_cap_segs = int(10)
const line_round_joint_segs = int(6)

// internal vertex type
struct LineVertex {
	left   Vec2
	right  Vec2
	color  rl.Color
	half_w f32
	arc_t  f32 // normalised arc-length position (0..1) used for UV mapping
}

@[heap]
pub struct Line {
	Node
pub mut:
	// control points in local space
	points []Vec2

	// stroke width in pixels (at default scale)
	width f32 = 4.0

	// fallback color used when no gradient is set
	default_color rl.Color = rl.Color{255, 255, 255, 255}

	// optional gradient sampled along the line's arc-length (t = 0..1).
	// when none, default_color is used uniformly.
	gradient ?&Gradient

	// pre-baked LUT for gradient lookups. call bake_gradient() after setting
	// or modifying `gradient`. when not empty, used instead of calling
	// gradient.sample() per vertex - important for monotone_cubic gradients
	// that rebuild tangent slices on every sample call.
	gradient_lut []rl.Color

	// optional curve that multiplies `width` along the line (t = 0..1 -> scale).
	// a curve falling 1 -> 0 tapers the stroke from head to tail.
	width_curve ?&BakedCurve

	joint_mode LineJointMode = .miter
	cap_mode   LineCapMode   = .flat

	// if true, the last point connects back to the first (no caps drawn)
	closed bool

	// when false (default) the start cap is drawn before the segments so it
	// stays underneath at self-intersections, with the trail head always on top.
	// set to true to draw both caps last (old behaviour, tail renders over).
	tail_over bool

	// texture mapped along the stroke; set via set_texture_id()
	texture      Handle[TextureResource]
	texture_mode LineTextureMode = .stretch
}

pub fn Line.instantiate(app &App, name string) &Line {
	return &Line{
		app:       app
		node_name: name
	}
}

pub fn Line.new(app &App, name string) &Line {
	return &Line{
		app:       app
		node_name: name
	}
}

// --- point management API ---

// add_point inserts `pos` at `index`.
// a negative or out-of-range index appends to the end,
// matching Godot's behaviour
pub fn (mut l Line) add_point(pos Vec2, index int) {
	if index < 0 || index >= l.points.len {
		l.points << pos
	} else {
		l.points.insert(index, pos)
	}
}

pub fn (mut l Line) remove_point(index int) {
	if index >= 0 && index < l.points.len {
		l.points.delete(index)
	}
}

pub fn (mut l Line) set_point_position(index int, pos Vec2) {
	if index >= 0 && index < l.points.len {
		l.points[index] = pos
	}
}

pub fn (l &Line) get_point_position(index int) Vec2 {
	if index >= 0 && index < l.points.len {
		return l.points[index]
	}
	return Vec2{}
}

pub fn (mut l Line) clear_points() {
	l.points.clear()
}

@[inline]
pub fn (l &Line) get_point_count() int {
	return l.points.len
}

// --- texture ---

pub fn (mut l Line) unload() {
	l.texture.release()
}

pub fn (mut l Line) set_texture_id(val string) !Handle[TextureResource] {
	l.texture.release()
	l.texture = l.app.textures.get_handle(val) or {
		l.texture = Handle[TextureResource]{}
		return error('texture not found: ${val}')
	}
	return l.texture
}

pub fn (mut l Line) set_texture_handle(h Handle[TextureResource]) {
	l.texture.release()
	l.texture = h
}

pub fn (l &Line) get_texture_id() ?string {
	if !l.texture.is_valid() {
		return none
	}
	return l.app.textures.name_of(l.texture.id)
}

@[inline]
pub fn (l &Line) get_texture() ?&TextureResource {
	return l.texture.get()
}

// --- gradient LUT ---

// bake_gradient populates gradient_lut from the current gradient.
// call once after assigning or modifying the gradient.
// resolution=256 is a good default for smooth gradients.
pub fn (mut l Line) bake_gradient(resolution int) {
	if g := l.gradient {
		l.gradient_lut = g.to_lut(resolution)
	} else {
		l.gradient_lut = []rl.Color{}
	}
}

// --- sampling helpers ---

@[inline]
fn (l &Line) sample_color(t f32) rl.Color {
	if l.gradient_lut.len > 0 {
		idx := int(t * f32(l.gradient_lut.len - 1) + 0.5)
		return l.gradient_lut[int(clamp(idx, 0, l.gradient_lut.len - 1))]
	}
	if g := l.gradient {
		return g.sample(t)
	}
	return l.default_color
}

@[inline]
fn (l &Line) sample_width(t f32) f32 {
	if c := l.width_curve {
		return l.width * c.sample(t)
	}
	return l.width
}

// --- vertex buffer construction ---

// returns the expanded vertex buffer and the total arc length.
fn (l &Line) build_vertices() ([]LineVertex, f32) {
	n := l.points.len
	if n < 2 {
		return []LineVertex{}, 0.0
	}

	// arc-length parameterisation for gradient / width-curve sampling.
	mut lengths := []f32{len: n, init: 0}
	for i in 1 .. n {
		lengths[i] = lengths[i - 1] + l.points[i].distance(l.points[i - 1])
	}
	total := lengths[n - 1]

	mut verts := []LineVertex{len: n}

	for i in 0 .. n {
		t := if total > 0 { lengths[i] / total } else { f32(0) }
		half_w := l.sample_width(t) * 0.5
		col := l.sample_color(t)

		has_prev := i > 0 || l.closed
		has_next := i < n - 1 || l.closed
		prev_i := if i == 0 { n - 1 } else { i - 1 }
		next_i := if i == n - 1 { 0 } else { i + 1 }

		seg_in := if has_prev { (l.points[i] - l.points[prev_i]).normalize() } else { Vec2{} }
		seg_out := if has_next { (l.points[next_i] - l.points[i]).normalize() } else { Vec2{} }

		n_in := Vec2{-seg_in.y, seg_in.x}
		n_out := Vec2{-seg_out.y, seg_out.x}

		mut offset := Vec2{}
		if !has_prev {
			offset = n_out
		} else if !has_next {
			offset = n_in
		} else {
			match l.joint_mode {
				.miter, .round {
					bisector := (n_in + n_out).normalize()
					dot := bisector.dot(n_in)
					if dot > 0.001 {
						miter_scale := math.min(1.0 / dot, line_max_miter_scale)
						offset = Vec2{bisector.x * miter_scale, bisector.y * miter_scale}
					} else {
						offset = bisector
					}
				}
				.bevel {
					offset = (n_in + n_out).normalize()
				}
			}
		}

		verts[i] = LineVertex{
			left:   Vec2{l.points[i].x + offset.x * half_w, l.points[i].y + offset.y * half_w}
			right:  Vec2{l.points[i].x - offset.x * half_w, l.points[i].y - offset.y * half_w}
			color:  col
			half_w: half_w
			arc_t:  t
		}
	}

	return verts, total
}

// --- rlgl draw helpers (all called between begin() / end()) ---

@[inline]
fn set_color(c rl.Color) {
	color4ub(c.r, c.g, c.b, c.a)
}

// in RL_QUADS mode each primitive needs exactly 4 vertices.
// indices [0,1,2, 0,2,3] form two triangles that together fill the quad.
// vertex order is r0,l0,l1,r1 - reversed from the intuitive l0,r0,r1,l1 - so
// that both resulting triangles are CCW in NDC space after Raylib's Y-flipping
// ortho projection. the l0,r0,r1,l1 order produces CW triangles in NDC which
// get back-face culled.
@[inline]
fn emit_quad(l0 Vec2, r0 Vec2, c0 rl.Color, l1 Vec2, r1 Vec2, c1 rl.Color, u0 f32, u1 f32) {
	set_color(c0)
	tex_coord2f(u0, 1)
	vertex2f(r0.x, r0.y) // 0: r0
	set_color(c0)
	tex_coord2f(u0, 0)
	vertex2f(l0.x, l0.y) // 1: l0
	set_color(c1)
	tex_coord2f(u1, 0)
	vertex2f(l1.x, l1.y) // 2: l1
	set_color(c1)
	tex_coord2f(u1, 1)
	vertex2f(r1.x, r1.y) // 3: r1
}

fn emit_round_cap(center Vec2, tangent Vec2, half_w f32, col rl.Color, u f32) {
	base := f32(math.atan2(tangent.y, tangent.x))
	for seg in 0 .. line_round_cap_segs {
		// Sweep CW in screen (high->low angle) -> CCW in NDC -> front face
		a0 := base + math.pi * 0.5 - f32(seg) / f32(line_round_cap_segs) * math.pi
		a1 := base + math.pi * 0.5 - f32(seg + 1) / f32(line_round_cap_segs) * math.pi
		v0x := center.x + math.cosf(a0) * half_w
		v0y := center.y + math.sinf(a0) * half_w
		v1x := center.x + math.cosf(a1) * half_w
		v1y := center.y + math.sinf(a1) * half_w
		// reversed sweep (a0 > a1) already gives CW in screen -> CCW in NDC -> front face
		set_color(col)
		tex_coord2f(u, 0.5)
		vertex2f(center.x, center.y)
		set_color(col)
		tex_coord2f(u, 0)
		vertex2f(v0x, v0y)
		set_color(col)
		tex_coord2f(u, 0)
		vertex2f(v1x, v1y)
	}
}

fn emit_square_cap(v LineVertex, tangent Vec2, u f32) {
	ext_l := Vec2{v.left.x + tangent.x * v.half_w, v.left.y + tangent.y * v.half_w}
	ext_r := Vec2{v.right.x + tangent.x * v.half_w, v.right.y + tangent.y * v.half_w}
	emit_quad(ext_l, ext_r, v.color, v.left, v.right, v.color, u, u)
}

fn emit_bevel_joint(center Vec2, n_in Vec2, n_out Vec2, half_w f32, col rl.Color, u f32) {
	p_in_x := center.x + n_in.x * half_w
	p_in_y := center.y + n_in.y * half_w
	p_out_x := center.x + n_out.x * half_w
	p_out_y := center.y + n_out.y * half_w
	set_color(col)
	tex_coord2f(u, 0.5)
	vertex2f(center.x, center.y)
	set_color(col)
	tex_coord2f(u, 0)
	vertex2f(p_in_x, p_in_y)
	set_color(col)
	tex_coord2f(u, 1)
	vertex2f(p_out_x, p_out_y)
	set_color(col)
	tex_coord2f(u, 1)
	vertex2f(p_out_x, p_out_y) // repeat -> degenerate 4th vertex
}

fn emit_round_joint(center Vec2, n_in Vec2, n_out Vec2, half_w f32, col rl.Color, u f32) {
	a_start := f32(math.atan2(n_in.y, n_in.x))
	a_end := f32(math.atan2(n_out.y, n_out.x))
	mut delta := a_end - a_start
	if delta > math.pi {
		delta -= 2 * math.pi
	}
	if delta < -math.pi {
		delta += 2 * math.pi
	}
	for seg in 0 .. line_round_joint_segs {
		a0 := a_start + delta * f32(seg) / f32(line_round_joint_segs)
		a1 := a_start + delta * f32(seg + 1) / f32(line_round_joint_segs)
		v0x := center.x + math.cosf(a0) * half_w
		v0y := center.y + math.sinf(a0) * half_w
		v1x := center.x + math.cosf(a1) * half_w
		v1y := center.y + math.sinf(a1) * half_w
		// delta < 0: sweep CW -> CCW in NDC (front face)
		// delta > 0: swap v0/v1 to restore CW sweep -> CCW in NDC
		if delta < 0 {
			set_color(col)
			tex_coord2f(u, 0.5)
			vertex2f(center.x, center.y)
			set_color(col)
			tex_coord2f(u, 0)
			vertex2f(v0x, v0y)
			set_color(col)
			tex_coord2f(u, 0)
			vertex2f(v1x, v1y)
			set_color(col)
			tex_coord2f(u, 0)
			vertex2f(v1x, v1y)
		} else {
			set_color(col)
			tex_coord2f(u, 0.5)
			vertex2f(center.x, center.y)
			set_color(col)
			tex_coord2f(u, 0)
			vertex2f(v1x, v1y)
			set_color(col)
			tex_coord2f(u, 0)
			vertex2f(v0x, v0y)
			set_color(col)
			tex_coord2f(u, 0)
			vertex2f(v0x, v0y)
		}
	}
}

// --- Node override ---

fn (mut l Line) draw_internal() {
	n := l.points.len
	if n < 2 {
		return
	}

	verts, total := l.build_vertices()

	// flush any pending Raylib batch geometry before our direct rlgl calls
	draw_render_batch_active()

	// resolve texture
	mut tex_id := u32(0)
	mut tex_w := f32(1)
	mut blend_mode := rl.BlendMode.blend_alpha
	if t := l.texture.get() {
		tex_id = t.tex.id
		tex_w = f32(t.tex.width)
		blend_mode = t.blend_mode
	}

	// u_for maps a vertex's arc_t to the U texture coordinate based on texture_mode
	u_for := fn [l, total, tex_w] (v LineVertex) f32 {
		return match l.texture_mode {
			.stretch {
				v.arc_t
			}
			.tile {
				if tex_w > 0 { v.arc_t * total / tex_w } else { v.arc_t }
			}
		}
	}

	// blend mode MUST be set before set_texture - begin_blend_mode calls
	// rlDrawRenderBatchActive which resets the bound texture to the default.
	rl.begin_blend_mode(int(blend_mode))
	set_texture(tex_id)
	begin(rl_quads)

	// Start cap drawn first (tail underneath) unless tail_over is set.
	if !l.closed && !l.tail_over {
		t_start := (l.points[0] - l.points[1]).normalize()
		match l.cap_mode {
			.square {
				emit_square_cap(verts[0], t_start, u_for(verts[0]))
			}
			.round {
				emit_round_cap(l.points[0], t_start, verts[0].half_w, verts[0].color,
					u_for(verts[0]))
			}
			.flat {}
		}
	}

	// segment quads
	limit := if l.closed { n } else { n - 1 }
	for i in 0 .. limit {
		v0 := verts[i]
		v1 := verts[(i + 1) % n]
		emit_quad(v0.left, v0.right, v0.color, v1.left, v1.right, v1.color, u_for(v0),
			u_for(v1))
	}

	// joint fill (bevel / round only; miter is baked into vertex offsets)
	if l.joint_mode != .miter {
		joint_limit := if l.closed { n } else { n - 2 }
		for i in 0 .. joint_limit {
			mid := (i + 1) % n
			nxt := (i + 2) % n
			s_in := (l.points[mid] - l.points[i]).normalize()
			s_out := (l.points[nxt] - l.points[mid]).normalize()
			ni := Vec2{-s_in.y, s_in.x}
			no := Vec2{-s_out.y, s_out.x}
			hw := verts[mid].half_w
			col := verts[mid].color
			u := u_for(verts[mid])
			match l.joint_mode {
				.bevel { emit_bevel_joint(l.points[mid], ni, no, hw, col, u) }
				.round { emit_round_joint(l.points[mid], ni, no, hw, col, u) }
				else {}
			}
		}
	}

	// End cap last (head on top). When tail_over is set, also draw start cap here.
	if !l.closed {
		t_end := (l.points[n - 1] - l.points[n - 2]).normalize()
		if l.tail_over {
			t_start := (l.points[0] - l.points[1]).normalize()
			match l.cap_mode {
				.square {
					emit_square_cap(verts[0], t_start, u_for(verts[0]))
				}
				.round {
					emit_round_cap(l.points[0], t_start, verts[0].half_w, verts[0].color,
						u_for(verts[0]))
				}
				.flat {}
			}
		}
		match l.cap_mode {
			.square {
				emit_square_cap(verts[n - 1], t_end, u_for(verts[n - 1]))
			}
			.round {
				emit_round_cap(l.points[n - 1], t_end, verts[n - 1].half_w, verts[n - 1].color,
					u_for(verts[n - 1]))
			}
			.flat {}
		}
	}

	end()
	rl.end_blend_mode()
	set_texture(0)
}

// --- trail helper ---

// push_trail_point appends the current position and culls the oldest point
// once the buffer exceeds max_points.
// call each frame from update().
// set max_points <= 0 to disable culling
pub fn (mut l Line) push_trail_point(pos Vec2, max_points int) {
	l.points << pos
	if max_points > 0 && l.points.len > max_points {
		l.points.delete(0)
	}
}
