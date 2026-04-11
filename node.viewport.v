module mv

import raylib as rl

pub struct Viewport {
	Node
mut:
	render_texture rl.RenderTexture2D
pub mut:
	process_flags ProcessFlags = .draw
	width         int
	height        int
	clear_color   rl.Color = rl.Color{0, 0, 0, 255}
}

pub fn Viewport.new(app &App, width int, height int) &Viewport {
	return &Viewport{
		app:            app
		width:          width
		height:         height
		render_texture: rl.load_render_texture(width, height)
	}
}

pub fn (mut v Viewport) free() {
	rl.unload_render_texture(v.render_texture)
}

pub fn (mut v Viewport) resize(width int, height int) {
	rl.unload_render_texture(v.render_texture)
	v.width = width
	v.height = height
	v.render_texture = rl.load_render_texture(width, height)
}

pub fn (mut v Viewport) push_mat_internal() {
	rl.begin_texture_mode(v.render_texture)
	rl.clear_background(v.clear_color)
	// no matrix push — children render in viewport-local space
}

pub fn (mut v Viewport) pop_mat_internal() {
	rl.end_texture_mode()
}
