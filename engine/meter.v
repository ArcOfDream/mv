module engine

import raylib as rl
import core { Vec2 }
import resourcemanager { Handle, TextureResource }

pub enum MeterFillMode {
	left_to_right
	right_to_left
	top_to_bottom
	bottom_to_top
}

// Meter is a three-texture progress bar node.
// Set value (0.0--1.0) to control how much of texture_progress is visible.
// texture_under draws behind the fill; texture_over draws on top.
// All three textures are optional -- omit any you don't need.
//
// By default Meter draws in screen space (ignores camera transform). Set
// screen_space = false to draw at its node position in world space instead.
@[heap]
pub struct Meter {
	Node
mut:
	texture_under    Handle[TextureResource]
	texture_progress Handle[TextureResource]
	texture_over     Handle[TextureResource]
pub mut:
	value     f32           = 1.0
	fill_mode MeterFillMode = .left_to_right
	tint      rl.Color      = rl.white
	// size overrides texture dimensions for the draw destination. Zero = use texture size.
	size         Vec2
	screen_space bool = true
}

pub fn Meter.instantiate(app &App, name string) &Meter {
	return &Meter{
		app:       app
		node_name: name
	}
}

pub fn (mut m Meter) set_texture_under_id(id string) ! {
	m.texture_under.release()
	m.texture_under = m.app.textures.get_handle(id) or {
		m.app.textures.load(id, id) or { return error('texture not found: ${id}') }
	}
}

pub fn (mut m Meter) set_texture_progress_id(id string) ! {
	m.texture_progress.release()
	m.texture_progress = m.app.textures.get_handle(id) or {
		m.app.textures.load(id, id) or { return error('texture not found: ${id}') }
	}
}

pub fn (mut m Meter) set_texture_over_id(id string) ! {
	m.texture_over.release()
	m.texture_over = m.app.textures.get_handle(id) or {
		m.app.textures.load(id, id) or { return error('texture not found: ${id}') }
	}
}

pub fn (mut m Meter) unload() {
	m.texture_under.release()
	m.texture_progress.release()
	m.texture_over.release()
}

fn (m &Meter) wren_class_name() string {
	return 'Meter'
}

fn (m &Meter) draw_size() Vec2 {
	if m.size.x > 0 || m.size.y > 0 {
		return m.size
	}
	if res := m.texture_progress.get() {
		return Vec2{f32(res.tex.width), f32(res.tex.height)}
	}
	if res := m.texture_under.get() {
		return Vec2{f32(res.tex.width), f32(res.tex.height)}
	}
	return Vec2{}
}

fn (m &Meter) progress_src_dst(tw f32, th f32, sz Vec2, v f32) (rl.Rectangle, rl.Rectangle) {
	return match m.fill_mode {
		.left_to_right {
			rl.Rectangle{0, 0, tw * v, th}, rl.Rectangle{0, 0, sz.x * v, sz.y}
		}
		.right_to_left {
			rl.Rectangle{tw * (1 - v), 0, tw * v, th}, rl.Rectangle{sz.x * (1 - v), 0, sz.x * v, sz.y}
		}
		.top_to_bottom {
			rl.Rectangle{0, 0, tw, th * v}, rl.Rectangle{0, 0, sz.x, sz.y * v}
		}
		.bottom_to_top {
			rl.Rectangle{0, th * (1 - v), tw, th * v}, rl.Rectangle{0, sz.y * (1 - v), sz.x, sz.y * v}
		}
	}
}

fn (mut m Meter) draw_internal() {
	v := if m.value < 0 {
		f32(0)
	} else if m.value > 1 {
		f32(1)
	} else {
		m.value
	}
	sz := m.draw_size()

	if res := m.texture_under.get() {
		tw := f32(res.tex.width)
		th := f32(res.tex.height)
		src := rl.Rectangle{0, 0, tw, th}
		dst := rl.Rectangle{0, 0, sz.x, sz.y}
		rl.draw_texture_pro(res.tex, src, dst, rl.Vector2{}, 0, m.tint)
	}

	if res := m.texture_progress.get() {
		tw := f32(res.tex.width)
		th := f32(res.tex.height)
		src, dst := m.progress_src_dst(tw, th, sz, v)
		rl.draw_texture_pro(res.tex, src, dst, rl.Vector2{}, 0, m.tint)
	}

	if res := m.texture_over.get() {
		tw := f32(res.tex.width)
		th := f32(res.tex.height)
		src := rl.Rectangle{0, 0, tw, th}
		dst := rl.Rectangle{0, 0, sz.x, sz.y}
		rl.draw_texture_pro(res.tex, src, dst, rl.Vector2{}, 0, m.tint)
	}
}

fn (mut m Meter) push_mat_internal() {
	if m.screen_space {
		push_matrix()
		load_identity()
		translatef(m.pos.x, m.pos.y, 0)
	} else {
		m.push_local_matrix()
	}
}

fn (mut m Meter) pop_mat_internal() {
	pop_matrix()
}
