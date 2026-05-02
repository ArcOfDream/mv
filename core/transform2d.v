module core

import raylib as rl
import math

pub struct Transform2D {
pub mut:
	rotation    f32
	translation Vec2
	scale       Vec2
	dirty       bool
}

// to_matrix builds the 4x4 column-major TRS matrix directly from the stored
// components.  this avoids chaining matrix_translate * matrix_rotate_z *
// matrix_scale through three full 4x4 multiplies - the 2D closed form is just
// two trig calls and four scalar multiplies.
//
// column-major layout (Raylib convention):
//   col 0: [ cos*sx,  sin*sx, 0, 0 ]
//   col 1: [-sin*sy,  cos*sy, 0, 0 ]
//   col 2: [      0,       0, 1, 0 ]
//   col 3: [     tx,      ty, 0, 1 ]
pub fn (t &Transform2D) to_matrix() rl.Matrix {
	cos_r := math.cosf(t.rotation)
	sin_r := math.sinf(t.rotation)
	// vfmt off
	return rl.Matrix{
		m0:  cos_r * t.scale.x   m4: -sin_r * t.scale.y   m8:  0   m12: t.translation.x
		m1:  sin_r * t.scale.x   m5:  cos_r * t.scale.y   m9:  0   m13: t.translation.y
		m2:  0                   m6:  0                   m10: 1   m14: 0
		m3:  0                   m7:  0                   m11: 0   m15: 1
	}
	// vfmt on
}

pub fn decompose_matrix(mat rl.Matrix) Transform2D {
	t := Vec2{mat.m12, mat.m13}

	// vfmt off
	s := Vec2{
		math.sqrtf(mat.m0 * mat.m0 + mat.m1 * mat.m1),
		math.sqrtf(mat.m4 * mat.m4 + mat.m5 * mat.m5)
	}
	// vfmt on

	mut r := f32(math.atan2(mat.m1, mat.m0))
	if math.is_nan(r) {
		r = 0
	}

	return Transform2D{
		rotation:    r
		translation: t
		scale:       s
		dirty:       false
	}
}
