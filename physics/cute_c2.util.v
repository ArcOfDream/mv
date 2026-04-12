module physics

import math { cosf, sinf }

pub const xtransform_identity = XTransform{Vec{0, 0}, Rotation{1, 0}}

// XTransform.from constructs a world-space transform from a position and
// angle in radians.
// this is the bridge from the engine's Transform2D to cute_c2's
// transform representation.
// note: scale is not representable in XTransform -- pre-scale polygon
// vertices in local space instead
pub fn XTransform.from(pos Vec, angle f32) XTransform {
	return XTransform{
		p: pos
		r: Rotation{
			c: cosf(angle)
			s: sinf(angle)
		}
	}
}
