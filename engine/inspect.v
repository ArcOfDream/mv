module engine

import core { Vec2 }
import raylib as rl

pub interface IInspectCtx {
mut:
	row_f32(label string, v &f32) bool
	row_int(label string, v &int) bool
	row_bool(label string, v &bool) bool
	row_vec2(label string, v &Vec2) bool
	row_color(label string, v &rl.Color) bool
	row_u32(label string, v &u32) bool
	row_enum_btn(label string, opts []string, current int) int
	row_path(label string, current string) string
	row_resource(label string, current string, kind string) string
	row_bitfield(label string, v &u32, n_bits int) bool
}

pub type SceneInspectFn = fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool
