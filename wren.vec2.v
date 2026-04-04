module mv

import wren

// read a typed pointer to the Vec2 stored in Wren's foreign bytes at `slot`.
@[inline]
fn wren_get_vec2(vm &wren.VM, slot int) &Vec2 {
	return unsafe { &Vec2(vm.get_slot_foreign(slot)) }
}

// write a new Vec2 foreign object into `slot`, using `class_slot` as scratch
// for the Vec2 class variable. Always call this *after* reading any values you
// need from existing slots, since it may overwrite them.
fn wren_push_vec2(vm &wren.VM, slot int, class_slot int, val Vec2) {
	vm.ensure_slots(class_slot + 1)
	vm.get_variable('main', 'Vec2', class_slot)
	raw := vm.set_slot_new_foreign(slot, class_slot, sizeof(Vec2))

	unsafe {
		mut ptr := &Vec2(raw)
		*ptr = val
	}
}

fn vec2_wren_allocate(vm &wren.VM) {
	raw := vm.set_slot_new_foreign(0, 0, sizeof(Vec2))
	x := f32(vm.get_slot_double(1))
	y := f32(vm.get_slot_double(2))
	unsafe {
		mut ptr := &Vec2(raw)
		*ptr = Vec2{x, y}
	}
}

fn vec2_wren_finalize(_data voidptr) {}

pub fn vec2_wren_class_methods() wren.ForeignClassMethods {
	return wren.ForeignClassMethods{
		allocate: vec2_wren_allocate
		finalize: vec2_wren_finalize
	}
}

fn vec2_wren_get_x(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_vec2(vm, 0).x)
}

fn vec2_wren_get_y(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_vec2(vm, 0).y)
}

fn vec2_wren_set_x(vm &wren.VM) {
	wren_get_vec2(vm, 0).x = f32(vm.get_slot_double(1))
}

fn vec2_wren_set_y(vm &wren.VM) {
	wren_get_vec2(vm, 0).y = f32(vm.get_slot_double(1))
}

// arithmetic operators
// read both operands into V locals first, then overwrite slot 0 with result.
// slot 2 is used as the Vec2 class scratch slot.

fn vec2_wren_add(vm &wren.VM) {
	result := *wren_get_vec2(vm, 0) + *wren_get_vec2(vm, 1)
	wren_push_vec2(vm, 0, 2, result)
}

fn vec2_wren_sub(vm &wren.VM) {
	result := *wren_get_vec2(vm, 0) - *wren_get_vec2(vm, 1)
	wren_push_vec2(vm, 0, 2, result)
}

fn vec2_wren_mul(vm &wren.VM) {
	result := *wren_get_vec2(vm, 0) * *wren_get_vec2(vm, 1)
	wren_push_vec2(vm, 0, 2, result)
}

fn vec2_wren_div(vm &wren.VM) {
	result := *wren_get_vec2(vm, 0) / *wren_get_vec2(vm, 1)
	wren_push_vec2(vm, 0, 2, result)
}

fn vec2_wren_to_string(vm &wren.VM) {
	v := wren_get_vec2(vm, 0)
	vm.set_slot_string(0, 'Vec2(${v.x}, ${v.y})')
}

pub fn vec2_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		'x' { vec2_wren_get_x }
		'y' { vec2_wren_get_y }
		'x=(_)' { vec2_wren_set_x }
		'y=(_)' { vec2_wren_set_y }
		'+(_)' { vec2_wren_add }
		'-(_)' { vec2_wren_sub }
		'*(_)' { vec2_wren_mul }
		'/(_)' { vec2_wren_div }
		'toString' { vec2_wren_to_string }
		else { unsafe { nil } }
	}
}
