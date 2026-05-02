module engine

import raylib as rl
import resourcemanager { Handle, TextureResource }
import core { Vec2 }

// Polygon renders a filled convex polygon in local space.
// for concave polygons the centroid-fan triangulation may produce incorrect
// fill; use a pre-triangulated mesh or ear-clip the points before assigning.
@[heap]
pub struct Polygon {
	Node
pub mut:
	points []Vec2
	color  rl.Color = rl.white

	// per-vertex UV coordinates, same length as points.
	// if empty at draw time, UVs are auto-generated frUom the AABB of points.
	uv []Vec2

	texture Handle[TextureResource]
}

pub fn Polygon.instantiate(app &App, name string) &Polygon {
	return &Polygon{
		app:       app
		node_name: name
	}
}

pub fn Polygon.new(app &App, name string) &Polygon {
	return Polygon.instantiate(app, name)
}

fn (n &Polygon) wren_class_name() string {
	return 'Polygon'
}

// --- point management ---

pub fn (mut p Polygon) add_point(pos Vec2) {
	p.points << pos
}

pub fn (mut p Polygon) remove_point(idx int) {
	if idx >= 0 && idx < p.points.len {
		p.points.delete(idx)
		if p.uv.len == p.points.len + 1 {
			p.uv.delete(idx)
		}
	}
}

pub fn (mut p Polygon) set_point_position(idx int, pos Vec2) {
	if idx >= 0 && idx < p.points.len {
		p.points[idx] = pos
	}
}

pub fn (mut p Polygon) clear_points() {
	p.points.clear()
	p.uv.clear()
}

pub fn (p &Polygon) get_point_count() int {
	return p.points.len
}

// --- UV helpers ---

// compute_uv fills the uv array by mapping each point into 0..1 space
// over the AABB of all points. Call after finalising the point list when
// you want pre-baked UVs rather than per-frame computation.
pub fn (mut p Polygon) compute_uv() {
	if p.points.len == 0 {
		p.uv = []Vec2{}
		return
	}
	min_x, min_y, max_x, max_y := aabb_of(p.points)
	w := max_x - min_x
	h := max_y - min_y
	p.uv = p.points.map(Vec2{
		x: if w > 0 { (it.x - min_x) / w } else { f32(0.5) }
		y: if h > 0 { (it.y - min_y) / h } else { f32(0.5) }
	})
}

// --- texture ---

pub fn (mut p Polygon) unload() {
	p.texture.release()
}

pub fn (mut p Polygon) set_texture_id(val string) !Handle[TextureResource] {
	p.texture.release()
	p.texture = p.app.textures.get_handle(val) or {
		p.texture = Handle[TextureResource]{}
		return error('texture not found: ${val}')
	}
	return p.texture
}

pub fn (mut p Polygon) set_texture_handle(h Handle[TextureResource]) {
	p.texture.release()
	p.texture = h
}

pub fn (p &Polygon) get_texture_id() ?string {
	if !p.texture.is_valid() {
		return none
	}
	return p.app.textures.name_of(p.texture.id)
}

@[inline]
pub fn (p &Polygon) get_texture() ?&TextureResource {
	return p.texture.get()
}

// --- draw ---

fn (mut p Polygon) draw_internal() {
	n := p.points.len
	if n < 3 {
		return
	}

	// compute centroid
	mut cx := f32(0)
	mut cy := f32(0)
	for pt in p.points {
		cx += pt.x
		cy += pt.y
	}
	cx /= f32(n)
	cy /= f32(n)

	// resolve UVs: use p.uv if fully populated, otherwise derive from AABB
	has_uv := p.uv.len == n
	mut uv_pts := p.uv.clone()
	mut uv_cx := f32(0.5)
	mut uv_cy := f32(0.5)

	if !has_uv {
		min_x, min_y, max_x, max_y := aabb_of(p.points)
		w := max_x - min_x
		h := max_y - min_y
		uv_pts = p.points.map(Vec2{
			x: if w > 0 { (it.x - min_x) / w } else { f32(0.5) }
			y: if h > 0 { (it.y - min_y) / h } else { f32(0.5) }
		})
		uv_cx = if w > 0 { (cx - min_x) / w } else { f32(0.5) }
		uv_cy = if h > 0 { (cy - min_y) / h } else { f32(0.5) }
	} else {
		// centroid UV = average of all vertex UVs
		for uv in p.uv {
			uv_cx += uv.x
			uv_cy += uv.y
		}
		uv_cx /= f32(n)
		uv_cy /= f32(n)
	}

	// Detect winding using shoelace formula.
	// In screen space (Y-down): positive signed area = CW winding.
	// Raylib culls CW triangles, so CW polygons need reversed vertex order.
	mut signed_area := f32(0)
	for i in 0 .. n {
		j := (i + 1) % n
		signed_area += p.points[i].x * p.points[j].y - p.points[j].x * p.points[i].y
	}
	is_cw := signed_area > 0

	draw_render_batch_active()

	mut tex_id := u32(0)
	mut blend_mode := rl.BlendMode.blend_alpha
	if t := p.texture.get() {
		tex_id = t.tex.id
		blend_mode = t.blend_mode
	}

	rl.begin_blend_mode(int(blend_mode))
	begin(rl_triangles)
	set_texture(tex_id)

	r, g, b, a := p.color.r, p.color.g, p.color.b, p.color.a

	for i in 0 .. n {
		next := (i + 1) % n
		// Swap vertex order for CW polygons to produce CCW triangles in screen space.
		a_idx := if is_cw { next } else { i }
		b_idx := if is_cw { i } else { next }
		uv0 := uv_pts[a_idx]
		uv1 := uv_pts[b_idx]

		// centroid
		color4ub(r, g, b, a)
		tex_coord2f(uv_cx, uv_cy)
		vertex2f(cx, cy)

		color4ub(r, g, b, a)
		tex_coord2f(uv0.x, uv0.y)
		vertex2f(p.points[a_idx].x, p.points[a_idx].y)

		color4ub(r, g, b, a)
		tex_coord2f(uv1.x, uv1.y)
		vertex2f(p.points[b_idx].x, p.points[b_idx].y)
	}

	end()
	rl.end_blend_mode()
	set_texture(0)
}

// --- internal helpers ---

fn aabb_of(pts []Vec2) (f32, f32, f32, f32) {
	mut min_x := pts[0].x
	mut min_y := pts[0].y
	mut max_x := pts[0].x
	mut max_y := pts[0].y
	for pt in pts {
		if pt.x < min_x {
			min_x = pt.x
		}
		if pt.y < min_y {
			min_y = pt.y
		}
		if pt.x > max_x {
			max_x = pt.x
		}
		if pt.y > max_y {
			max_y = pt.y
		}
	}
	return min_x, min_y, max_x, max_y
}
