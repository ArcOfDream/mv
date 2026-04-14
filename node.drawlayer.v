module mv

import raylib as rl

// DrawLayer renders its children in a fixed coordinate space that is
// independent of the parent transform chain — exactly like Godot's DrawLayer.
@[heap]
pub struct DrawLayer {
	Node
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
