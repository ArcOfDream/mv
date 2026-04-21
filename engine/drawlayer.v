module engine

import raylib as rl

/*
DrawLayer: usage example

DrawLayer resets the matrix stack to identity before drawing its children,
so its subtree always renders in screen space regardless of camera transform
or parent node position. Use it for HUD elements, overlays, and UI that
should not move when the camera moves.

	mut hud := DrawLayer.new(app, 'HUD')
	scene_root.add_child(mut hud)

	// health bar, minimap, etc. added as children of hud
	// will always draw at their local positions in screen space
	mut health_bar := Sprite.new(app, 'health_bar', 'ui_health')
	health_bar.set_pos(Vec2{16, 16})
	hud.add_child(mut health_bar)

Contrast with a regular Node child of the scene root: if the camera pans,
that node's screen position changes. A DrawLayer child stays fixed.

Do not nest a DrawLayer inside another node that has a non-identity
transform expecting it to inherit that transform: DrawLayer explicitly
ignores the parent transform chain.
*/

// DrawLayer renders its children in a fixed coordinate space that is
// independent of the parent transform chain
@[heap]
pub struct DrawLayer {
	Node
}

pub fn DrawLayer.instantiate(app &App, name string) &DrawLayer {
	return &DrawLayer{
		app:       app
		node_name: name
	}
}

pub fn DrawLayer.new(app &App, name string) &DrawLayer {
	return &DrawLayer{
		app:       app
		node_name: name
	}
}

fn (n &DrawLayer) wren_class_name() string {
	return 'DrawLayer'
}

// get_global_matrix breaks the parent chain
pub fn (mut dl DrawLayer) get_global_matrix() rl.Matrix {
	dl.global_matrix = dl.get_local_matrix()
	return dl.global_matrix
}

// push_mat_internal resets to identity here
fn (mut dl DrawLayer) push_mat_internal() {
	push_matrix()
	load_identity()
	mult_matrix_f(dl.local_matrix_f)
}

fn (mut dl DrawLayer) pop_mat_internal() {
	pop_matrix()
}
