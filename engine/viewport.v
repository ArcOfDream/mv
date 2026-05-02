module engine

import raylib as rl

/*
Viewport - usage example

Viewport renders its children into a private RenderTexture2D. Retrieve the
resulting texture to use as input elsewhere - a minimap, a mirror surface,
a portal effect, or a render target for post-processing.

	mut minimap_vp := Viewport.new(app, 128, 128)
	minimap_vp.clear_color = rl.Color{20, 20, 20, 255}
	scene_root.add_child(mut minimap_vp)

	// add a scaled-down camera and relevant geometry as children
	// of minimap_vp - they render into its texture, not the main viewport

After the draw pass, read the texture back for use in a Sprite or shader:

	tex := minimap_vp.get_texture()  // returns rl.Texture2D
	// texture y-axis is flipped - negate source height in draw_texture_pro:
	src := rl.Rectangle{0, 0, f32(tex.width), f32(-tex.height)}
	rl.draw_texture_pro(tex, src, dest, origin, 0, rl.white)

Note that Viewport clears `process_flags` to `.draw` only - its children
participate in the draw pass but not the update/transform pass of the main
tree. Add a separate update path if children of the viewport need per-frame
logic.
*/

@[heap]
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

pub fn Viewport.instantiate(app &App, name string) &Viewport {
	return &Viewport{
		app:       app
		node_name: name
	}
}

pub fn Viewport.new(app &App, width int, height int) &Viewport {
	return &Viewport{
		app:            app
		width:          width
		height:         height
		render_texture: rl.load_render_texture(width, height)
	}
}

fn (n &Viewport) wren_class_name() string {
	return 'Viewport'
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

// get_texture returns the Texture2D rendered into by this Viewport's children.
// call after the draw pass; the texture is valid for the lifetime of the Viewport.
// Note: the texture's y-axis is flipped relative to screen space: negate the
// source rect height in rl.draw_texture_pro to correct it if needed.
pub fn (v &Viewport) get_texture() rl.Texture2D {
	return rl.Texture2D(v.render_texture.texture)
}

pub fn (mut v Viewport) push_mat_internal() {
	rl.begin_texture_mode(v.render_texture)
	rl.clear_background(v.clear_color)
	// no matrix push: children render in viewport-local space
}

pub fn (mut v Viewport) pop_mat_internal() {
	rl.end_texture_mode()
}
