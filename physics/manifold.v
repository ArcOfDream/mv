module physics

// cute_c2 convention (from the c2Manifold docs):
//   .n           -- normal always points from shape A to shape B
//   .contact_points -- world-space contact positions on the surface of shape A
//   .depths      -- positive penetration depths at each contact point
//
// manifold_between_xf / manifold_between enforce a consistent convention:
//   .n           -- always points from s1 to s2
//   .contact_points -- always on the surface of s2
//
// For symmetric pairs (Circle<->Circle, AABB<->AABB, Capsule<->Capsule) the
// cute_c2 ordering already matches s1->s2, so no adjustment is needed.
// For asymmetric pairs where cute_c2 only provides one ordering, we swap
// arguments, then negate the normal AND project contact points from s2's
// surface onto s1's surface so they end up back on s2 after the swap.
// For non-polygon shapes whose coordinates are already in world space,
// pass xtransform_identity.

// fix_swapped_manifold corrects the manifold after swapping arguments.
// cute_c2 placed contact points on shape A's surface.  Since we swapped
// args (A = original s2, B = original s1), they're currently on s2's
// surface.  We negate the normal so it points from s1 to s2, then
// project contact points along the negated normal by depth to move them
// onto s1's surface.
@[inline]
fn fix_swapped_manifold(mut m Manifold) {
	m.n = Vec{-m.n.x, -m.n.y}
	for i in 0 .. int(m.count) {
		m.contact_points[i] = Vec{m.contact_points[i].x - m.n.x * m.depths[i], m.contact_points[i].y - m.n.y * m.depths[i]}
	}
}

pub fn manifold_between_xf(s1 Shape, xf1 XTransform, s2 Shape, xf2 XTransform) Manifold {
	mut m := Manifold{}
	match s1 {
		Circle {
			match s2 {
				Circle { circle_to_circle_manifold(s1, s2, mut m) }
				AABB { circle_to_aabb_manifold(s1, s2, mut m) }
				Capsule { circle_to_capsule_manifold(s1, s2, mut m) }
				Polygon { circle_to_poly_manifold(s1, &s2, &xf2, mut m) }
				else {}
			}
		}
		AABB {
			match s2 {
				Circle {
					circle_to_aabb_manifold(s2, s1, mut m)
					fix_swapped_manifold(mut m)
				}
				AABB {
					aabb_to_aabb_manifold(s1, s2, mut m)
				}
				Capsule {
					aabb_to_capsule_manifold(s1, s2, mut m)
				}
				Polygon {
					aabb_to_poly_manifold(s1, &s2, &xf2, mut m)
				}
				else {}
			}
		}
		Capsule {
			match s2 {
				Circle {
					circle_to_capsule_manifold(s2, s1, mut m)
					fix_swapped_manifold(mut m)
				}
				AABB {
					aabb_to_capsule_manifold(s2, s1, mut m)
					fix_swapped_manifold(mut m)
				}
				Capsule {
					capsule_to_capsule_manifold(s1, s2, mut m)
				}
				Polygon {
					capsule_to_poly_manifold(s1, &s2, &xf2, mut m)
				}
				else {}
			}
		}
		Polygon {
			match s2 {
				Circle {
					circle_to_poly_manifold(s2, &s1, &xf1, mut m)
					fix_swapped_manifold(mut m)
				}
				AABB {
					aabb_to_poly_manifold(s2, &s1, &xf1, mut m)
					fix_swapped_manifold(mut m)
				}
				Capsule {
					capsule_to_poly_manifold(s2, &s1, &xf1, mut m)
					fix_swapped_manifold(mut m)
				}
				Polygon {
					poly_to_poly_manifold(&s1, &xf1, &s2, &xf2, mut m)
				}
				else {}
			}
		}
		else {}
	}

	return m
}

// manifold_between computes the collision manifold between any two shapes.
// The returned manifold follows these conventions:
//   .n           -- always points from s1 to s2
//   .contact_points -- always on the surface of s2
//   .depths      -- positive penetration depths
pub fn manifold_between(s1 Shape, s2 Shape) Manifold {
	return manifold_between_xf(s1, xtransform_identity, s2, xtransform_identity)
}
