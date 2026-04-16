module mv

import core { Vec2 }
import raylib as rl
import raylib.raymath as rm
import wren

pub enum Notification {
	init
	ready
	exit_tree
	update
	draw
	push_mat
	pop_mat
	transform
}

@[flag]
pub enum ProcessFlags {
	transform
	draw
}

@[heap]
pub interface INode {
	name() string
	app() &App
	wren_class_name() string
	get_child_count() int
	find_child(child &INode) int
	get_pos() Vec2
	get_scale() Vec2
	get_angle_deg() f32
	get_angle_rad() f32
mut:
	process_flags  ProcessFlags
	dirty          bool
	wren_owned     bool
	app            &App
	angle_deg      f32
	angle_rad      f32
	pos            Vec2
	scale          Vec2
	transform      Transform2D
	local_matrix   rl.Matrix
	global_matrix  rl.Matrix
	local_matrix_f rm.Float16
	parent         ?&INode
	children       []&INode
	wren_handle    ?&wren.Handle

	get_global_matrix() rl.Matrix
	get_local_matrix() rl.Matrix

	get_global_pos() Vec2
	get_global_scale() Vec2
	get_global_angle_rad() f32
	get_global_angle_deg() f32

	set_pos(val Vec2)
	set_scale(val Vec2)
	set_angle_deg(val f32)
	set_angle_rad(val f32)
	set_global_pos(val Vec2)
	set_global_scale(val Vec2)
	set_global_angle_deg(val f32)
	set_global_angle_rad(val f32)

	rebuild_local_matrix()
	push_mat_internal()
	pop_mat_internal()

	get_children() []&INode
	add_child(mut child INode)
	remove_child(index int)
	insert_child_at(index int, mut child INode)
	reparent(mut new_parent INode)
	replace_by(mut node INode)
	move_child(index int, to int)
	swap_children(index_a int, index_b int)

	init_internal()
	init()
	ready_internal()
	ready()
	exit_tree_internal()
	exit_tree()
	update_internal(dt f32)
	update(dt f32)
	draw_internal()
	draw()

	queue_free()
}
