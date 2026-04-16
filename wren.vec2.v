module mv

import core { Vec2 }
import wren

fn vec2_wren_allocate(vm &wren.VM) {
	mut ptr := wren_alloc[Vec2](vm)
	ptr.x = wren_get_f32(vm, 1)
	ptr.y = wren_get_f32(vm, 2)
}

pub fn vec2_wren_class_methods() wren.ForeignClassMethods {
	return wren_class(vec2_wren_allocate, wren_noop_finalize)
}

// component access

fn vec2_wren_get_x(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).x)
}

fn vec2_wren_get_y(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).y)
}

fn vec2_wren_set_x(vm &wren.VM) {
	mut v := wren_get_object[Vec2](vm, 0)
	v.x = wren_get_f32(vm, 1)
}

fn vec2_wren_set_y(vm &wren.VM) {
	mut v := wren_get_object[Vec2](vm, 0)
	v.y = wren_get_f32(vm, 1)
}

// scalar queries

fn vec2_wren_length(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).length())
}

fn vec2_wren_length_sqr(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).length_sqr())
}

fn vec2_wren_dot(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).dot(*wren_get_object[Vec2](vm,
		1)))
}

fn vec2_wren_cross(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).cross(*wren_get_object[Vec2](vm,
		1)))
}

fn vec2_wren_distance(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).distance(*wren_get_object[Vec2](vm,
		1)))
}

fn vec2_wren_distance_sqr(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).distance_sqr(*wren_get_object[Vec2](vm,
		1)))
}

fn vec2_wren_angle(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).angle(*wren_get_object[Vec2](vm,
		1)))
}

fn vec2_wren_line_angle(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Vec2](vm, 0).line_angle(*wren_get_object[Vec2](vm,
		1)))
}

// no-arg Vec2 -> Vec2 (exposed as getters)

fn vec2_wren_normalize(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).normalize()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_invert(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).invert()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_negate(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).negate()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_perpendicular(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).perpendicular()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_abs(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).abs()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_floor(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).floor()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_ceil(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).ceil()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_round(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).round()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

// single scalar-arg Vec2 -> Vec2

fn vec2_wren_scale(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).scale(wren_get_f32(vm, 1))
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_rotate(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).rotate(wren_get_f32(vm, 1))
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_add_value(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).add_value(wren_get_f32(vm, 1))
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

fn vec2_wren_subtract_value(vm &wren.VM) {
	result := wren_get_object[Vec2](vm, 0).subtract_value(wren_get_f32(vm, 1))
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', result)
}

// single Vec2-arg Vec2 -> Vec2

fn vec2_wren_reflect(vm &wren.VM) {
	a, b := *wren_get_object[Vec2](vm, 0), *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', a.reflect(b))
}

fn vec2_wren_min(vm &wren.VM) {
	a, b := *wren_get_object[Vec2](vm, 0), *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', a.min(b))
}

fn vec2_wren_max(vm &wren.VM) {
	a, b := *wren_get_object[Vec2](vm, 0), *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', a.max(b))
}

// two-arg methods

fn vec2_wren_lerp(vm &wren.VM) {
	// copy all inputs before wren_push_foreign overwrites slot 0
	self := *wren_get_object[Vec2](vm, 0)
	target := *wren_get_object[Vec2](vm, 1)
	t := wren_get_f32(vm, 2)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', self.lerp(target, t))
}

fn vec2_wren_move_towards(vm &wren.VM) {
	self := *wren_get_object[Vec2](vm, 0)
	target := *wren_get_object[Vec2](vm, 1)
	max_dist := wren_get_f32(vm, 2)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', self.move_towards(target, max_dist))
}

fn vec2_wren_clamp(vm &wren.VM) {
	// slots: 0=self, 1=min Vec2, 2=max Vec2
	self := *wren_get_object[Vec2](vm, 0)
	mn := *wren_get_object[Vec2](vm, 1)
	mx := *wren_get_object[Vec2](vm, 2)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', self.clamp(mn, mx))
}

fn vec2_wren_clamp_value(vm &wren.VM) {
	self := *wren_get_object[Vec2](vm, 0)
	mn := wren_get_f32(vm, 1)
	mx := wren_get_f32(vm, 2)
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', self.clamp_value(mn, mx))
}

// operators

fn vec2_wren_add(vm &wren.VM) {
	result := *wren_get_object[Vec2](vm, 0) + *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 2, 'Vec2', result)
}

fn vec2_wren_sub(vm &wren.VM) {
	result := *wren_get_object[Vec2](vm, 0) - *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 2, 'Vec2', result)
}

fn vec2_wren_mul(vm &wren.VM) {
	result := *wren_get_object[Vec2](vm, 0) * *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 2, 'Vec2', result)
}

fn vec2_wren_div(vm &wren.VM) {
	result := *wren_get_object[Vec2](vm, 0) / *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 2, 'Vec2', result)
}

fn vec2_wren_mod(vm &wren.VM) {
	result := *wren_get_object[Vec2](vm, 0) % *wren_get_object[Vec2](vm, 1)
	wren_push_foreign[Vec2](vm, 0, 2, 'Vec2', result)
}

fn vec2_wren_eq(vm &wren.VM) {
	vm.set_slot_bool(0, *wren_get_object[Vec2](vm, 0) == *wren_get_object[Vec2](vm, 1))
}

// misc

fn vec2_wren_to_string(vm &wren.VM) {
	v := wren_get_object[Vec2](vm, 0)
	vm.set_slot_string(0, 'Vec2(${v.x}, ${v.y})')
}

pub fn vec2_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		// component access
		'x' { vec2_wren_get_x }
		'y' { vec2_wren_get_y }
		'x=(_)' { vec2_wren_set_x }
		'y=(_)' { vec2_wren_set_y }
		// scalar queries
		'length' { vec2_wren_length }
		'lengthSqr' { vec2_wren_length_sqr }
		'dot(_)' { vec2_wren_dot }
		'cross(_)' { vec2_wren_cross }
		'distance(_)' { vec2_wren_distance }
		'distanceSqr(_)' { vec2_wren_distance_sqr }
		'angle(_)' { vec2_wren_angle }
		'lineAngle(_)' { vec2_wren_line_angle }
		// no-arg Vec2 getters
		'normalize' { vec2_wren_normalize }
		'invert' { vec2_wren_invert }
		'negate' { vec2_wren_negate }
		'perpendicular' { vec2_wren_perpendicular }
		'abs' { vec2_wren_abs }
		'floor' { vec2_wren_floor }
		'ceil' { vec2_wren_ceil }
		'round' { vec2_wren_round }
		// single scalar arg
		'scale(_)' { vec2_wren_scale }
		'rotate(_)' { vec2_wren_rotate }
		'addValue(_)' { vec2_wren_add_value }
		'subtractValue(_)' { vec2_wren_subtract_value }
		// single Vec2 arg
		'reflect(_)' { vec2_wren_reflect }
		'min(_)' { vec2_wren_min }
		'max(_)' { vec2_wren_max }
		// two-arg
		'lerp(_,_)' { vec2_wren_lerp }
		'moveTowards(_,_)' { vec2_wren_move_towards }
		'clamp(_,_)' { vec2_wren_clamp }
		'clampValue(_,_)' { vec2_wren_clamp_value }
		// operators
		'+(_)' { vec2_wren_add }
		'-(_)' { vec2_wren_sub }
		'*(_)' { vec2_wren_mul }
		'/(_)' { vec2_wren_div }
		'%(_)' { vec2_wren_mod }
		'==(_)' { vec2_wren_eq }
		// misc
		'toString' { vec2_wren_to_string }
		else { unsafe { nil } }
	}
}
