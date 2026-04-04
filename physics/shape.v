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
