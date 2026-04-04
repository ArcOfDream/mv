module mv

import raylib as rl
import raylib.raymath as rm

// rlgl specific functions needed for this to work
#include "rlgl.h"

fn C.rlPushMatrix()
@[inline]
pub fn push_matrix() {
	C.rlPushMatrix()
}

fn C.rlPopMatrix()
@[inline]
pub fn pop_matrix() {
	C.rlPopMatrix()
}

fn C.rlTranslatef(x f32, y f32, z f32)
@[inline]
pub fn translatef(x f32, y f32, z f32) {
	C.rlTranslatef(x, y, z)
}

fn C.rlRotatef(angle f32, x f32, y f32, z f32)
@[inline]
pub fn rotatef(angle f32, x f32, y f32, z f32) {
	C.rlRotatef(angle, x, y, z)
}

fn C.rlScalef(x f32, y f32, z f32)
@[inline]
pub fn scalef(x f32, y f32, z f32) {
	C.rlScalef(x, y, z)
}

fn C.rlGetMatrixTransform() rl.Matrix
@[inline]
pub fn get_matrix_transform() rl.Matrix {
	return C.rlGetMatrixTransform()
}

fn C.rlMultMatrixf(float [16]f32)
@[inline]
pub fn mult_matrix_f(float rm.Float16) {
	C.rlMultMatrixf(float.v)
}

fn C.rlLoadIdentity()
@[inline]
pub fn load_identity() {
	C.rlLoadIdentity()
}