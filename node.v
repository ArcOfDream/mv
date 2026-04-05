module mv

import raylib as rl
import raylib.raymath as rm
import math
import wren

pub struct Node implements INode {
mut:
	dirty          bool = true
	node_name      string
	app            &App
	parent         ?&INode
	children       []&INode
	local_matrix   rl.Matrix
	global_matrix  rl.Matrix
	local_matrix_f rm.Float16

	// Set by the Wren allocator; its presence means "call back into Wren
	// for update/draw". Doubles as the persistent Wren object handle.
	wren_handle ?&wren.Handle
pub mut:
	process_flags ProcessFlags = .transform | .draw
	angle_deg     f32
	angle_rad     f32
	pos           Vec2
	scale         Vec2 = Vec2{1, 1}
	transform     Transform2D = Transform2D{ dirty: true }
}

@[inline]
pub fn (n &Node) name() string {
	return n.node_name
}

@[inline]
pub fn (n &Node) app() &App {
	return n.app
}

@[inline]
pub fn (n &Node) get_pos() Vec2 {
	return n.pos
}

pub fn (mut n Node) set_pos(val Vec2) {
	if n.pos != val {
		n.dirty = true
		n.transform.dirty = true
		n.pos = val
	}
}

@[inline]
pub fn (n &Node) get_scale() Vec2 {
	return n.scale
}

pub fn (mut n Node) set_scale(val Vec2) {
	if n.scale != val {
		n.dirty = true
		n.transform.dirty = true
		n.scale = val
	}
}

@[inline]
pub fn (n &Node) get_angle_deg() f32 {
	return n.angle_deg
}

pub fn (mut n Node) set_angle_deg(val f32) {
	if n.angle_deg != val {
		n.dirty = true
		n.transform.dirty = true
		n.angle_deg = val
		n.angle_rad = f32(math.radians(val))
	}
}

@[inline]
pub fn (n &Node) get_angle_rad() f32 {
	return n.angle_rad
}

pub fn (mut n Node) set_angle_rad(val f32) {
	if n.angle_rad != val {
		n.dirty = true
		n.transform.dirty = true
		n.angle_deg = f32(math.degrees(val))
		n.angle_rad = val
	}
}

@[inline]
pub fn (mut n Node) get_global_matrix() rl.Matrix {
	if mut p := n.parent {
		n.global_matrix = rm.matrix_multiply(n.get_local_matrix(), p.get_global_matrix())
	} else {
		n.global_matrix = n.get_local_matrix()
	}
	return n.global_matrix
}

@[inline]
pub fn (mut n Node) get_local_matrix() rl.Matrix {
	if n.dirty {
		n.rebuild_local_matrix()
	}
	return n.local_matrix
}

@[inline]
fn (mut n Node) rebuild_local_matrix() {
	mut mat := rm.matrix_identity()
	mat = rm.matrix_multiply(mat, rm.matrix_scale(n.scale.x, n.scale.y, 1))
	mat = rm.matrix_multiply(mat, rm.matrix_rotate_z(n.angle_rad))
	mat = rm.matrix_multiply(mat, rm.matrix_translate(n.pos.x, n.pos.y, 0))
	n.local_matrix = mat
	n.local_matrix_f = rm.matrix_to_float_v(mat)
	n.dirty = false
}

@[inline]
fn (mut n Node) sync_transform() {
	if n.transform.dirty {
		n.transform = decompose_matrix(n.get_global_matrix())
	}
}

@[inline]
pub fn (mut n Node) get_global_pos() Vec2 {
	n.sync_transform()
	return n.transform.translation
}

@[inline]
pub fn (mut n Node) get_global_scale() Vec2 {
	n.sync_transform()
	return n.transform.scale
}

@[inline]
pub fn (mut n Node) get_global_angle_rad() f32 {
	n.sync_transform()
	return n.transform.rotation
}

@[inline]
pub fn (mut n Node) get_global_angle_deg() f32 {
	n.sync_transform()
	return f32(math.degrees(n.transform.rotation))
}

pub fn (mut n Node) set_global_pos(val Vec2) {
	if p := n.parent {
		inv_mat := rm.matrix_invert(p.global_matrix)
		n.set_pos(rm.vector2_transform(val, inv_mat))
	} else {
		n.set_pos(val)
	}
	n.transform.dirty = true
}

pub fn (mut n Node) set_global_scale(val Vec2) {
	if p := n.parent {
		n.set_scale(val - p.transform.scale)
	} else {
		n.set_scale(val)
	}
	n.transform.dirty = true
}

pub fn (mut n Node) set_global_angle_rad(val f32) {
	if p := n.parent {
		n.set_angle_rad(val - p.transform.rotation)
	} else {
		n.set_angle_rad(val)
	}
	n.transform.dirty = true
}

pub fn (mut n Node) set_global_angle_deg(val f32) {
	if p := n.parent {
		n.set_angle_deg(val - f32(math.degrees(p.transform.rotation)))
	} else {
		n.set_angle_deg(val)
	}
	n.transform.dirty = true
}

fn (mut n Node) push_mat_internal() {
	push_matrix()
	mult_matrix_f(n.local_matrix_f)
}

fn (mut n Node) pop_mat_internal() {
	pop_matrix()
}

fn (mut n Node) ready_internal() {}

pub fn (mut n Node) ready() {}

fn (mut n Node) update_internal(_dt f32) {}

pub fn (mut n Node) update(_dt f32) {}

fn (mut n Node) draw_internal() {}

pub fn (mut n Node) draw() {}

@[inline]
pub fn (n &Node) get_children() []&INode {
	return n.children
}

pub fn (mut n Node) add_child(mut child INode) {
	child.parent = n
	n.children << child
	emit_notification(mut child, .ready, n.app.state)
	println('New count: ${n.children.len}')
}

pub fn (mut n Node) create_and_add_child[T](name string) &T {
	mut node := &T{
		node_name: name
		app:       n.app
	}
	n.add_child(mut node)

	return node
}

@[inline]
pub fn (n &Node) find_child(child &INode) int {
	// working around a cgen bug by casting to voidptr here
	target := voidptr(child)
	for i, c in n.children {
		if voidptr(c) == target {
			return i
		}
	}
	
	return -1
}

@[inline]
pub fn (mut n Node) remove_child(index int) {
	if index < 0 || index >= n.children.len {
		return
	}

	mut child := n.children[index]
	child.parent = ?&INode(none)
	n.children.delete(index)
}

pub fn emit_notification(mut node INode, notification Notification, state &GameState) {
	match notification {
		.draw {
			if node.process_flags.has(.draw) {
				notify(mut node, .push_mat, state)
				notify(mut node, .draw, state)

				for mut child in node.get_children() {
					emit_notification(mut child, .draw, state)
				}
				notify(mut node, .pop_mat, state)
			}
		}
		.update {
			notify(mut node, notification, state)

			if node.process_flags.has(.transform) {
				if p := node.parent {
					if p.dirty {
						node.dirty = true
					}
				}

				if node.dirty {
					node.rebuild_local_matrix()
				}

				if p := node.parent {
					node.global_matrix = rm.matrix_multiply(node.local_matrix, p.global_matrix)
				} else {
					node.global_matrix = node.local_matrix
				}

				if node.dirty || node.transform.dirty {
					node.transform = decompose_matrix(node.global_matrix)
				}
			}

			for mut child in node.get_children() {
				emit_notification(mut child, notification, state)
			}

			node.dirty = false
		}
		else {
			for mut child in node.get_children() {
				emit_notification(mut child, notification, state)
			}
			notify(mut node, notification, state)
		}
	}
}

pub fn notify(mut node INode, notification Notification, state &GameState) {
	match notification {
		.push_mat {
			node.push_mat_internal()
		}
		.draw {
			node.draw_internal()
			node.draw()

			if handle := node.wren_handle {
				if mut vm := node.app.wren_vm {
					if draw_h := node.app.wren_draw_handle {
						vm.ensure_slots(1)
						vm.set_slot_handle(0, handle)
						vm.call(draw_h)
					}
				}
			}
		}
		.pop_mat {
			node.pop_mat_internal()
		}
		.ready {
			node.ready_internal()
			node.ready()
		}
		.update {
			node.update_internal(state.dt)
			node.update(state.dt)

			if handle := node.wren_handle {
				if mut vm := node.app.wren_vm {
					if update_h := node.app.wren_update_handle {
						vm.ensure_slots(2)
						vm.set_slot_handle(0, handle)
						vm.set_slot_double(1, state.dt)
						vm.call(update_h)
					}
				}
			}
		}
		.make_dirty {
			node.dirty = true
		}
		else {}
	}
}
