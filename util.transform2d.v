module mv

import raylib as rl
import math
import core { Vec2 }

pub struct Transform2D {
pub mut:
	rotation    f32
	translation Vec2
	scale       Vec2
	dirty       bool
}

pub fn decompose_matrix(mat rl.Matrix) Transform2D {
	t := Vec2{mat.m12, mat.m13}

	// vfmt off
	s := Vec2{
		math.sqrtf(mat.m0 * mat.m0 + mat.m1 * mat.m1),
		math.sqrtf(mat.m4 * mat.m4 + mat.m5 * mat.m5)
	}
	// vfmt on

	mut r := f32(math.atan2(mat.m1, mat.m1))
	if r == math.nan() {
		r = 0
	}

	return Transform2D{
		rotation:    r
		translation: t
		scale:       s
		dirty:       false
	}
}
