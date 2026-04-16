module physics

import math as m

pub type Shape = AABB | Capsule | Circle | Polygon | Ray | Vec

// helper to get the internal C type ID for c2Collided
fn (s Shape) c2_type() CollisionType {
	return match s {
		Vec { .none }
		Circle { .circle }
		AABB { .aabb }
		Capsule { .capsule }
		Polygon { .poly }
		else { .none }
	}
}

// Polygon.from_rect builds a rectangle polygon centred at the origin
// with the given width and height. Vertices are wound counter-clockwise.
// Rotate at collision time via XTransform — do not bake rotation into vertices.
pub fn Polygon.from_rect(w f32, h f32) Polygon {
	hw := w * 0.5
	hh := h * 0.5
	mut p := Polygon{
		count: 4
	}
	p.verts[0] = Vec{-hw, -hh} // top-left
	p.verts[1] = Vec{ hw, -hh} // top-right
	p.verts[2] = Vec{ hw,  hh} // bottom-right
	p.verts[3] = Vec{-hw,  hh} // bottom-left
	make_poly(mut p)
	return p
}

// Polygon.from_aabb converts an existing AABB into an equivalent polygon.
// Useful when you need to rotate geometry that was originally defined as an AABB.
pub fn Polygon.from_aabb(aabb AABB) Polygon {
	w := aabb.max.x - aabb.min.x
	h := aabb.max.y - aabb.min.y
	mut p := Polygon{
		count: 4
	}
	p.verts[0] = Vec{aabb.min.x, aabb.min.y}
	p.verts[1] = Vec{aabb.max.x, aabb.min.y}
	p.verts[2] = Vec{aabb.max.x, aabb.max.y}
	p.verts[3] = Vec{aabb.min.x, aabb.max.y}
	// re-centre so rotation is around the shape's own centre,
	// consistent with from_rect behaviour
	cx := aabb.min.x + w * 0.5
	cy := aabb.min.y + h * 0.5
	for i in 0 .. p.count {
		p.verts[i] = Vec{p.verts[i].x - cx, p.verts[i].y - cy}
	}
	make_poly(mut p)
	return p
}

@[inline]
pub fn check_collision(s1 Shape, s2 Shape) bool {
	// identity transform for primitives (c2 ignores these for non-polygons)
	xf := xtransform_identity

	// we use unsafe to get the address of the shape data
	// because c2Collided expects a voidptr to the raw struct.
	unsafe {
		return C.c2Collided(&s1, &xf, int(s1.c2_type()), &s2, &xf, int(s2.c2_type())) != 0
	}
}

pub fn (s Shape) bounds() (f32, f32, f32, f32) {
	match s {
		Circle {
			return s.p.x - s.r, s.p.y - s.r, s.r * 2, s.r * 2
		}
		AABB {
			return s.min.x, s.min.y, s.max.x - s.min.x, s.max.y - s.min.y
		}
		Capsule {
			// simplified bounding box for capsule
			min_x := m.min(s.a.x, s.b.x) - s.r
			min_y := m.min(s.a.y, s.b.y) - s.r
			max_x := m.max(s.a.x, s.b.x) + s.r
			max_y := m.max(s.a.y, s.b.y) + s.r
			return min_x, min_y, max_x - min_x, max_y - min_y
		}
		Polygon {
			// polygons require iterating vertices to find min/max
			mut min_x, mut min_y := s.verts[0].x, s.verts[0].y
			mut max_x, mut max_y := s.verts[0].x, s.verts[0].y
			for i in 1 .. s.count {
				v := s.verts[i]
				if v.x < min_x {
					min_x = v.x
				}
				if v.x > max_x {
					max_x = v.x
				}
				if v.y < min_y {
					min_y = v.y
				}
				if v.y > max_y {
					max_y = v.y
				}
			}
			return min_x, min_y, max_x - min_x, max_y - min_y
		}
		Vec {
			return s.x, s.y, 1, 1
		}
		else {
			return 0, 0, 0, 0
		}
	}
}
