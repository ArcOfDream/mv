module engine

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

// RL_TRIANGLES mode constant for begin()
pub const rl_triangles = 4
pub const rl_quads = 7

fn C.rlBegin(mode int)
@[inline]
pub fn begin(mode int) {
	C.rlBegin(mode)
}

fn C.rlEnd()
@[inline]
pub fn end() {
	C.rlEnd()
}

fn C.rlVertex2f(x f32, y f32)
@[inline]
pub fn vertex2f(x f32, y f32) {
	C.rlVertex2f(x, y)
}

fn C.rlColor4ub(r u8, g u8, b u8, a u8)
@[inline]
pub fn color4ub(r u8, g u8, b u8, a u8) {
	C.rlColor4ub(r, g, b, a)
}

fn C.rlTexCoord2f(x f32, y f32)
@[inline]
pub fn tex_coord2f(x f32, y f32) {
	C.rlTexCoord2f(x, y)
}

// set_texture binds a texture by its OpenGL id for subsequent rlgl draw calls.
// pass 0 to unbind (reverts to the default 1x1 white pixel).
fn C.rlSetTexture(id u32)
@[inline]
pub fn set_texture(id u32) {
	C.rlSetTexture(id)
}

// draw_render_batch_active flushes all pending geometry in the current batch
// to the GPU immediately. Call this before direct rlgl draw sequences to
// guarantee a clean batch state, avoiding texture bleed from prior Raylib draws.
fn C.rlDrawRenderBatchActive()
@[inline]
pub fn draw_render_batch_active() {
	C.rlDrawRenderBatchActive()
}
