module clay

import raylib as rl
import math

pub enum Direction {
	row
	col
}

// Ordinals must match make_sizing() switch cases in clay_shim.c (0=fit,1=grow,2=fixed,3=percent).
pub enum SizingType {
	fit     = 0
	grow    = 1
	fixed   = 2
	percent = 3
}

pub struct Sizing {
pub:
	typ   SizingType = .grow
	value f32
}

pub fn fixed(px f32) Sizing {
	return Sizing{
		typ:   .fixed
		value: px
	}
}

pub fn grow() Sizing {
	return Sizing{
		typ: .grow
	}
}

pub fn fit() Sizing {
	return Sizing{
		typ: .fit
	}
}

pub fn percent(p f32) Sizing {
	return Sizing{
		typ:   .percent
		value: p
	}
}

// w and h default to .grow (fill remaining space). Use fixed()/fit()/percent() helpers to override.
pub struct ElemConfig {
pub:
	id         string
	dir        Direction = .row
	w          Sizing    = grow()
	h          Sizing    = grow()
	pad_x      int
	pad_y      int
	gap        int
	bg         rl.Color
	has_bg     bool
	corner     f32
	border_w   f32
	border_col rl.Color
}

// C function declarations
fn C.clay_shim_init(width f32, height f32)
fn C.clay_shim_resize(width f32, height f32)
fn C.clay_shim_free()
fn C.clay_shim_begin()
fn C.clay_shim_end() int
fn C.clay_shim_render_count() int
fn C.clay_shim_pointer(x f32, y f32, pressed bool)
fn C.clay_shim_scroll(dx f32, dy f32, dt f32)
fn C.clay_shim_push(id &char, direction int,
	wt int, wv f32, ht int, hv f32,
	px int, py int, gap int,
	has_bg int,
	bg_r u8, bg_g u8, bg_b u8, bg_a u8,
	corner_r f32,
	border_w f32,
	bo_r u8, bo_g u8, bo_b u8, bo_a u8)
fn C.clay_shim_push_scroll(id &char, wt int, wv f32, ht int, hv f32, padding int)
fn C.clay_shim_push_float(id &char, x f32, y f32, w f32, h f32)
fn C.clay_shim_pop()
fn C.clay_shim_get_rect(id &char, x &f32, y &f32, w &f32, h &f32) bool
fn C.clay_shim_get_scroll(id &char, sx &f32, sy &f32) bool
fn C.clay_shim_set_scroll_y(id &char, sy f32)
fn C.clay_shim_render_get(i int, typ &int,
	x &f32, y &f32, w &f32, h &f32,
	cr &f32, cg &f32, cb &f32, ca &f32,
	corner_r &f32, border_w &f32,
	br &f32, bg_out &f32, bb &f32, ba &f32) bool

// Public API
pub fn init(width f32, height f32) {
	C.clay_shim_init(width, height)
}

pub fn resize(width f32, height f32) {
	C.clay_shim_resize(width, height)
}

pub fn free_mem() {
	C.clay_shim_free()
}

pub fn begin() {
	C.clay_shim_begin()
}

pub fn end() int {
	return C.clay_shim_end()
}

pub fn render_count() int {
	return C.clay_shim_render_count()
}

pub fn pointer(x f32, y f32, pressed bool) {
	C.clay_shim_pointer(x, y, pressed)
}

pub fn scroll(dx f32, dy f32, dt f32) {
	C.clay_shim_scroll(dx, dy, dt)
}

pub fn push(cfg ElemConfig) {
	C.clay_shim_push(cfg.id.str, int(cfg.dir), int(cfg.w.typ), cfg.w.value, int(cfg.h.typ),
		cfg.h.value, cfg.pad_x, cfg.pad_y, cfg.gap, if cfg.has_bg { 1 } else { 0 }, cfg.bg.r,
		cfg.bg.g, cfg.bg.b, cfg.bg.a, cfg.corner, cfg.border_w, cfg.border_col.r, cfg.border_col.g,
		cfg.border_col.b, cfg.border_col.a)
}

pub fn push_scroll(id string, w Sizing, h Sizing, padding int) {
	C.clay_shim_push_scroll(id.str, int(w.typ), w.value, int(h.typ), h.value, padding)
}

pub fn push_float(id string, x f32, y f32, w f32, h f32) {
	C.clay_shim_push_float(id.str, x, y, w, h)
}

pub fn pop() {
	C.clay_shim_pop()
}

pub fn get_rect(id string) ?rl.Rectangle {
	mut x, mut y, mut w, mut h := f32(0), f32(0), f32(0), f32(0)
	if C.clay_shim_get_rect(id.str, &x, &y, &w, &h) {
		return rl.Rectangle{x, y, w, h}
	}
	return none
}

pub fn get_scroll_y(id string) ?f32 {
	mut sx, mut sy := f32(0), f32(0)
	if C.clay_shim_get_scroll(id.str, &sx, &sy) {
		return sy
	}
	return none
}

pub fn set_scroll_y(id string, sy f32) {
	C.clay_shim_set_scroll_y(id.str, sy)
}

@[inline]
fn to_u8(v f32) u8 {
	return u8(math.min(f32(255), math.max(f32(0), v)))
}

// render_rl draws all pending render commands via Raylib.
// Call after clay.end() and before raygui widgets.
pub fn render_rl() {
	n := C.clay_shim_render_count()
	for i in 0 .. n {
		mut typ := 0
		mut x, mut y, mut w, mut h := f32(0), f32(0), f32(0), f32(0)
		mut cr, mut cg, mut cb, mut ca := f32(0), f32(0), f32(0), f32(0)
		mut corner_r, mut bw := f32(0), f32(0)
		mut br, mut bg_out, mut bb, mut ba := f32(0), f32(0), f32(0), f32(0)
		if !C.clay_shim_render_get(i, &typ, &x, &y, &w, &h, &cr, &cg, &cb, &ca, &corner_r,
			&bw, &br, &bg_out, &bb, &ba) {
			continue
		}
		r := rl.Rectangle{x, y, w, h}
		match typ {
			1 { // RECTANGLE
				col := rl.Color{to_u8(cr), to_u8(cg), to_u8(cb), to_u8(ca)}
				if corner_r > 0 && w > 0 && h > 0 {
					half_min := if w < h { w * 0.5 } else { h * 0.5 }
					rl.draw_rectangle_rounded(r, corner_r / half_min, 8, col)
				} else {
					rl.draw_rectangle_rec(r, col)
				}
			}
			2 { // BORDER
				col := rl.Color{to_u8(br), to_u8(bg_out), to_u8(bb), to_u8(ba)}
				rl.draw_rectangle_lines_ex(r, bw, col)
			}
			5 { // SCISSOR_START
				rl.begin_scissor_mode(int(x), int(y), int(w), int(h))
			}
			6 { // SCISSOR_END
				rl.end_scissor_mode()
			}
			else {}
		}
	}
}
