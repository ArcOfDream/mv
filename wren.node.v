module mv

import wren

fn wren_ensure_node_handle(vm &wren.VM, slot int, class_slot int, mut node INode) {
	if handle := node.wren_handle {
		vm.set_slot_handle(slot, handle)
		return
	}

	class_name := node.wren_class_name()
	vm.ensure_slots(class_slot + 1)
	vm.get_variable('main', class_name, class_slot)

	raw := vm.set_slot_new_foreign(slot, class_slot, sizeof(voidptr))
	unsafe {
		mut ptr := &&INode(raw)
		*ptr = &node
	}
	node.wren_handle = vm.get_slot_handle(slot)
}

fn node_wren_allocate(vm &wren.VM) {
    mut n := wren_alloc[Node](vm)
    n.init_from_wren(vm)
}

pub fn node_wren_class_methods() wren.ForeignClassMethods {
	return wren_class(node_wren_allocate, wren_noop_finalize)
}

// wrapper

fn node_wren_set_wrapper(vm &wren.VM) {
    mut n := wren_get_object[Node](vm, 0)
    if old_h := n.wren_handle {
        vm.release_handle(old_h)
    }
    n.wren_handle = vm.get_slot_handle(1)
}

// identity

fn node_wren_get_name(vm &wren.VM) {
	vm.set_slot_string(0, wren_get_object[Node](vm, 0).name())
}

// local transform

fn node_wren_get_pos(vm &wren.VM) {
	pos := wren_get_object[Node](vm, 0).get_pos()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', pos)
}

fn node_wren_set_pos(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_pos(*wren_get_object[Vec2](vm, 1))
}

fn node_wren_get_scale(vm &wren.VM) {
	scale := wren_get_object[Node](vm, 0).get_scale()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', scale)
}

fn node_wren_set_scale(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_scale(*wren_get_object[Vec2](vm, 1))
}

fn node_wren_get_angle_deg(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Node](vm, 0).get_angle_deg())
}

fn node_wren_set_angle_deg(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_angle_deg(wren_get_f32(vm, 1))
}

fn node_wren_get_angle_rad(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Node](vm, 0).get_angle_rad())
}

fn node_wren_set_angle_rad(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_angle_rad(wren_get_f32(vm, 1))
}

// global transform (read)

fn node_wren_get_global_pos(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	pos := node.get_global_pos()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', pos)
}

fn node_wren_get_global_scale(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	scale := node.get_global_scale()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', scale)
}

fn node_wren_get_global_angle_deg(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	vm.set_slot_double(0, node.get_global_angle_deg())
}

fn node_wren_get_global_angle_rad(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	vm.set_slot_double(0, node.get_global_angle_rad())
}

// global transform (write)

fn node_wren_set_global_pos(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_global_pos(*wren_get_object[Vec2](vm, 1))
}

fn node_wren_set_global_scale(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_global_scale(*wren_get_object[Vec2](vm, 1))
}

fn node_wren_set_global_angle_deg(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_global_angle_deg(wren_get_f32(vm, 1))
}

fn node_wren_set_global_angle_rad(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.set_global_angle_rad(wren_get_f32(vm, 1))
}

// tree traversal

fn node_wren_get_parent(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	mut parent := node.parent or {
		vm.set_slot_null(0)
		return
	}

	wren_ensure_node_handle(vm, 0, 1, mut parent)
}

fn node_wren_get_children(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	mut children := node.get_children() // []&INode

	vm.ensure_slots(3) // 0=list, 1=element, 2=class scratch for lazy mint
	vm.set_slot_new_list(0)

	for mut child in children {
		wren_ensure_node_handle(vm, 1, 2, mut *child)
		vm.insert_in_list(0, -1, 1)
	}
}

fn node_wren_get_child_count(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Node](vm, 0).get_child_count())
}

fn node_wren_add_child(vm &wren.VM) {
	mut parent := wren_get_object[Node](vm, 0)
	mut child := unsafe { &Node(vm.get_slot_foreign(1)) }
	parent.add_child(mut child)
}

fn node_wren_remove_child(vm &wren.VM) {
	mut parent := wren_get_object[Node](vm, 0)
	child := unsafe { &Node(vm.get_slot_foreign(1)) }
	idx := parent.find_child(child)
	if idx != -1 {
		parent.remove_child(idx)
	}
}

fn node_wren_get_child_at(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	idx := wren_get_int(vm, 1)
	mut children := node.get_children()
	if idx < 0 || idx >= children.len {
		vm.set_slot_null(0)
		return
	}
	wren_ensure_node_handle(vm, 0, 1, mut *children[idx])
}

fn node_wren_find_child(vm &wren.VM) {
	node := wren_get_object[Node](vm, 0)
	child := unsafe { &Node(vm.get_slot_foreign(1)) }
	vm.set_slot_double(0, node.find_child(child))
}

fn node_wren_reparent(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	mut new_parent := unsafe { &Node(vm.get_slot_foreign(1)) }
	node.reparent(mut new_parent)
}

fn node_wren_move_child(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.move_child(wren_get_int(vm, 1), wren_get_int(vm, 2))
}

fn node_wren_swap_children(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.swap_children(wren_get_int(vm, 1), wren_get_int(vm, 2))
}

// lifecycle

fn node_wren_queue_free(vm &wren.VM) {
	mut node := wren_get_object[Node](vm, 0)
	node.queue_free()
}

// dispatch

pub fn node_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		'setWrapper(_)' { node_wren_set_wrapper }
		'name' { node_wren_get_name }
		'pos' { node_wren_get_pos }
		'pos=(_)' { node_wren_set_pos }
		'scale' { node_wren_get_scale }
		'scale=(_)' { node_wren_set_scale }
		'angleDeg' { node_wren_get_angle_deg }
		'angleDeg=(_)' { node_wren_set_angle_deg }
		'angleRad' { node_wren_get_angle_rad }
		'angleRad=(_)' { node_wren_set_angle_rad }
		'globalPos' { node_wren_get_global_pos }
		'globalPos=(_)' { node_wren_set_global_pos }
		'globalScale' { node_wren_get_global_scale }
		'globalScale=(_)' { node_wren_set_global_scale }
		'globalAngleDeg' { node_wren_get_global_angle_deg }
		'globalAngleDeg=(_)' { node_wren_set_global_angle_deg }
		'globalAngleRad' { node_wren_get_global_angle_rad }
		'globalAngleRad=(_)' { node_wren_set_global_angle_rad }
		'parent' { node_wren_get_parent }
		'children' { node_wren_get_children }
		'childCount' { node_wren_get_child_count }
		'addChild(_)' { node_wren_add_child }
		'removeChild(_)' { node_wren_remove_child }
		'getChildAt(_)' { node_wren_get_child_at }
		'findChild(_)' { node_wren_find_child }
		'reparent(_)' { node_wren_reparent }
		'moveChild(_,_)' { node_wren_move_child }
		'swapChildren(_,_)' { node_wren_swap_children }
		'queueFree()' { node_wren_queue_free }
		else { unsafe { nil } }
	}
}
