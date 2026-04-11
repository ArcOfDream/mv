module physics

// manifold_between computes the collision manifold between any two shapes.
// the manifold normal always points from s1 to s2 for symmetric pairs.
// for asymmetric pairs (e.g. Circle vs AABB) where cute_c2 only provides
// one ordering, we swap arguments and negate the normal to maintain consistency.
pub fn manifold_between(s1 Shape, s2 Shape) Manifold {
	mut m := Manifold{}
	match s1 {
		Circle {
			match s2 {
				Circle { circle_to_circle_manifold(s1, s2, mut m) }
				AABB { circle_to_aabb_manifold(s1, s2, mut m) }
				Capsule { circle_to_capsule_manifold(s1, s2, mut m) }
				Polygon { circle_to_poly_manifold(s1, &s2, &xtransform_identity, mut m) }
				else {}
			}
		}
		AABB {
			match s2 {
				Circle {
					// cute_c2 has no aabb_to_circle — swap and negate normal
					circle_to_aabb_manifold(s2, s1, mut m)
					m.n = Vec{-m.n.x, -m.n.y}
				}
				AABB {
					aabb_to_aabb_manifold(s1, s2, mut m)
				}
				Capsule {
					aabb_to_capsule_manifold(s1, s2, mut m)
				}
				Polygon {
					aabb_to_poly_manifold(s1, &s2, &xtransform_identity, mut m)
				}
				else {}
			}
		}
		Capsule {
			match s2 {
				Circle {
					circle_to_capsule_manifold(s2, s1, mut m)
					m.n = Vec{-m.n.x, -m.n.y}
				}
				AABB {
					aabb_to_capsule_manifold(s2, s1, mut m)
					m.n = Vec{-m.n.x, -m.n.y}
				}
				Capsule {
					capsule_to_capsule_manifold(s1, s2, mut m)
				}
				Polygon {
					capsule_to_poly_manifold(s1, &s2, &xtransform_identity, mut m)
				}
				else {}
			}
		}
		Polygon {
			match s2 {
				Circle {
					circle_to_poly_manifold(s2, &s1, &xtransform_identity, mut m)
					m.n = Vec{-m.n.x, -m.n.y}
				}
				AABB {
					aabb_to_poly_manifold(s2, &s1, &xtransform_identity, mut m)
					m.n = Vec{-m.n.x, -m.n.y}
				}
				Capsule {
					capsule_to_poly_manifold(s2, &s1, &xtransform_identity, mut m)
					m.n = Vec{-m.n.x, -m.n.y}
				}
				Polygon {
					poly_to_poly_manifold(&s1, &xtransform_identity, &s2, &xtransform_identity, mut
						m)
				}
				else {}
			}
		}
		else {}
	}
	return m
}
