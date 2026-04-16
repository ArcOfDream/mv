module mv

import core { Vec2 }
import raylib as rl
import wren

// Color class

fn color_wren_allocate(vm &wren.VM) {
	mut c := wren_alloc[rl.Color](vm)
	c.r = wren_get_u8(vm, 1)
	c.g = wren_get_u8(vm, 2)
	c.b = wren_get_u8(vm, 3)
	c.a = wren_get_u8(vm, 4)
}

pub fn color_wren_class_methods() wren.ForeignClassMethods {
	return wren_class(color_wren_allocate, wren_noop_finalize)
}

// components are read-only from Wren; construct a new Color to modify

fn color_wren_get_r(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[rl.Color](vm, 0).r)
}

fn color_wren_get_g(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[rl.Color](vm, 0).g)
}

fn color_wren_get_b(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[rl.Color](vm, 0).b)
}

fn color_wren_get_a(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[rl.Color](vm, 0).a)
}

pub fn color_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		'r' { color_wren_get_r }
		'g' { color_wren_get_g }
		'b' { color_wren_get_b }
		'a' { color_wren_get_a }
		else { unsafe { nil } }
	}
}

// RL drawing - filled

fn rl_wren_draw_rectangle(vm &wren.VM) {
	rl.draw_rectangle(wren_get_int(vm, 1), wren_get_int(vm, 2), wren_get_int(vm, 3), wren_get_int(vm,
		4), *wren_get_object[rl.Color](vm, 5))
}

fn rl_wren_draw_rectangle_v(vm &wren.VM) {
	// drawRectangleV(pos, size, color)
	pos := *wren_get_object[Vec2](vm, 1)
	size := *wren_get_object[Vec2](vm, 2)
	color := *wren_get_object[rl.Color](vm, 3)
	rl.draw_rectangle_v(pos, size, color)
}

fn rl_wren_draw_rectangle_rounded(vm &wren.VM) {
	// drawRectangleRounded(x, y, w, h, roundness, segments, color)
	rect := rl.Rectangle{
		x:      wren_get_f32(vm, 1)
		y:      wren_get_f32(vm, 2)
		width:  wren_get_f32(vm, 3)
		height: wren_get_f32(vm, 4)
	}
	rl.draw_rectangle_rounded(rect, wren_get_f32(vm, 5), wren_get_int(vm, 6), *wren_get_object[rl.Color](vm,
		7))
}

fn rl_wren_draw_circle(vm &wren.VM) {
	rl.draw_circle(wren_get_int(vm, 1), wren_get_int(vm, 2), wren_get_f32(vm, 3), *wren_get_object[rl.Color](vm,
		4))
}

fn rl_wren_draw_circle_v(vm &wren.VM) {
	// drawCircleV(center, radius, color)
	center := *wren_get_object[Vec2](vm, 1)
	rl.draw_circle_v(center, wren_get_f32(vm, 2), *wren_get_object[rl.Color](vm, 3))
}

fn rl_wren_draw_ellipse(vm &wren.VM) {
	// drawEllipse(cx, cy, rx, ry, color)
	rl.draw_ellipse(wren_get_int(vm, 1), wren_get_int(vm, 2), wren_get_f32(vm, 3), wren_get_f32(vm,
		4), *wren_get_object[rl.Color](vm, 5))
}

fn rl_wren_draw_ring(vm &wren.VM) {
	// drawRing(center, innerRadius, outerRadius, startAngle, endAngle, segments, color)
	center := *wren_get_object[Vec2](vm, 1)
	rl.draw_ring(center, wren_get_f32(vm, 2), wren_get_f32(vm, 3), wren_get_f32(vm, 4),
		wren_get_f32(vm, 5), wren_get_int(vm, 6), *wren_get_object[rl.Color](vm, 7))
}

fn rl_wren_draw_triangle(vm &wren.VM) {
	// drawTriangle(v1, v2, v3, color) — winding: counter-clockwise
	v1 := *wren_get_object[Vec2](vm, 1)
	v2 := *wren_get_object[Vec2](vm, 2)
	v3 := *wren_get_object[Vec2](vm, 3)
	color := *wren_get_object[rl.Color](vm, 4)
	rl.draw_triangle(v1, v2, v3, color)
}

// RL drawing - outlines

fn rl_wren_draw_rectangle_lines(vm &wren.VM) {
	rl.draw_rectangle_lines(wren_get_int(vm, 1), wren_get_int(vm, 2), wren_get_int(vm,
		3), wren_get_int(vm, 4), *wren_get_object[rl.Color](vm, 5))
}

fn rl_wren_draw_rectangle_lines_ex(vm &wren.VM) {
	// drawRectangleLinesEx(x, y, w, h, lineThick, color)
	rect := rl.Rectangle{
		x:      wren_get_f32(vm, 1)
		y:      wren_get_f32(vm, 2)
		width:  wren_get_f32(vm, 3)
		height: wren_get_f32(vm, 4)
	}
	rl.draw_rectangle_lines_ex(rect, wren_get_f32(vm, 5), *wren_get_object[rl.Color](vm,
		6))
}

fn rl_wren_draw_circle_lines(vm &wren.VM) {
	rl.draw_circle_lines(wren_get_int(vm, 1), wren_get_int(vm, 2), wren_get_f32(vm, 3),
		*wren_get_object[rl.Color](vm, 4))
}

fn rl_wren_draw_triangle_lines(vm &wren.VM) {
	v1 := *wren_get_object[Vec2](vm, 1)
	v2 := *wren_get_object[Vec2](vm, 2)
	v3 := *wren_get_object[Vec2](vm, 3)
	color := *wren_get_object[rl.Color](vm, 4)
	rl.draw_triangle_lines(v1, v2, v3, color)
}

// RL drawing - lines 

fn rl_wren_draw_line(vm &wren.VM) {
	rl.draw_line(wren_get_int(vm, 1), wren_get_int(vm, 2), wren_get_int(vm, 3), wren_get_int(vm,
		4), *wren_get_object[rl.Color](vm, 5))
}

fn rl_wren_draw_line_v(vm &wren.VM) {
	// drawLineV(start, end, color)
	start := *wren_get_object[Vec2](vm, 1)
	end_ := *wren_get_object[Vec2](vm, 2)
	color := *wren_get_object[rl.Color](vm, 3)
	rl.draw_line_v(start, end_, color)
}

fn rl_wren_draw_line_ex(vm &wren.VM) {
	// drawLineEx(start, end, thick, color)
	start := *wren_get_object[Vec2](vm, 1)
	end_ := *wren_get_object[Vec2](vm, 2)
	thick := wren_get_f32(vm, 3)
	color := *wren_get_object[rl.Color](vm, 4)
	rl.draw_line_ex(start, end_, thick, color)
}

// RL drawing - text

fn rl_wren_draw_text(vm &wren.VM) {
	rl.draw_text(vm.get_slot_string(1), wren_get_int(vm, 2), wren_get_int(vm, 3), wren_get_int(vm,
		4), *wren_get_object[rl.Color](vm, 5))
}

fn rl_wren_draw_fps(vm &wren.VM) {
	rl.draw_fps(wren_get_int(vm, 1), wren_get_int(vm, 2))
}

fn rl_wren_measure_text(vm &wren.VM) {
	vm.set_slot_double(0, rl.measure_text(vm.get_slot_string(1), wren_get_int(vm, 2)))
}

// RL input - keyboard

fn rl_wren_is_key_down(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_key_down(wren_get_int(vm, 1)))
}

fn rl_wren_is_key_pressed(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_key_pressed(wren_get_int(vm, 1)))
}

fn rl_wren_is_key_released(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_key_released(wren_get_int(vm, 1)))
}

fn rl_wren_is_key_up(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_key_up(wren_get_int(vm, 1)))
}

// RL input - mouse

fn rl_wren_is_mouse_button_down(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_mouse_button_down(wren_get_int(vm, 1)))
}

fn rl_wren_is_mouse_button_pressed(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_mouse_button_pressed(wren_get_int(vm, 1)))
}

fn rl_wren_is_mouse_button_released(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_mouse_button_released(wren_get_int(vm, 1)))
}

fn rl_wren_get_mouse_position(vm &wren.VM) {
	pos := rl.get_mouse_position()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', Vec2{pos.x, pos.y})
}

fn rl_wren_get_mouse_delta(vm &wren.VM) {
	d := rl.get_mouse_delta()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', Vec2{d.x, d.y})
}

fn rl_wren_get_mouse_wheel_move(vm &wren.VM) {
	vm.set_slot_double(0, rl.get_mouse_wheel_move())
}

// RL input a gamepad 
// all gamepad functions take a gamepad index as their first argument
// (0 = first connected gamepad)
// button and axis constants follow Raylib's GamepadButton and GamepadAxis enums

fn rl_wren_is_gamepad_available(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_gamepad_available(wren_get_int(vm, 1)))
}

fn rl_wren_is_gamepad_button_down(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_gamepad_button_down(wren_get_int(vm, 1), wren_get_int(vm,
		2)))
}

fn rl_wren_is_gamepad_button_pressed(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_gamepad_button_pressed(wren_get_int(vm, 1), wren_get_int(vm,
		2)))
}

fn rl_wren_is_gamepad_button_released(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_gamepad_button_released(wren_get_int(vm, 1), wren_get_int(vm,
		2)))
}

fn rl_wren_is_gamepad_button_up(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_gamepad_button_up(wren_get_int(vm, 1), wren_get_int(vm,
		2)))
}

fn rl_wren_get_gamepad_axis_movement(vm &wren.VM) {
	// getGamepadAxisMovement(gamepad, axis) -> f32 in -1..1
	vm.set_slot_double(0, rl.get_gamepad_axis_movement(wren_get_int(vm, 1), wren_get_int(vm,
		2)))
}

fn rl_wren_get_gamepad_axis_count(vm &wren.VM) {
	vm.set_slot_double(0, rl.get_gamepad_axis_count(wren_get_int(vm, 1)))
}

// RL cursor

fn rl_wren_show_cursor(_ &wren.VM) {
	rl.show_cursor()
}

fn rl_wren_hide_cursor(_ &wren.VM) {
	rl.hide_cursor()
}

fn rl_wren_is_cursor_hidden(vm &wren.VM) {
	vm.set_slot_bool(0, rl.is_cursor_hidden())
}

fn rl_wren_enable_cursor(_ &wren.VM) {
	rl.enable_cursor()
}

fn rl_wren_disable_cursor(_ &wren.VM) {
	rl.disable_cursor()
}

// dispatch

pub fn rl_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		// filled shapes
		'drawRectangle(_,_,_,_,_)' { rl_wren_draw_rectangle }
		'drawRectangleV(_,_,_)' { rl_wren_draw_rectangle_v }
		'drawRectangleRounded(_,_,_,_,_,_,_)' { rl_wren_draw_rectangle_rounded }
		'drawCircle(_,_,_,_)' { rl_wren_draw_circle }
		'drawCircleV(_,_,_)' { rl_wren_draw_circle_v }
		'drawEllipse(_,_,_,_,_)' { rl_wren_draw_ellipse }
		'drawRing(_,_,_,_,_,_,_)' { rl_wren_draw_ring }
		'drawTriangle(_,_,_,_)' { rl_wren_draw_triangle }
		// outlines
		'drawRectangleLines(_,_,_,_,_)' { rl_wren_draw_rectangle_lines }
		'drawRectangleLinesEx(_,_,_,_,_,_)' { rl_wren_draw_rectangle_lines_ex }
		'drawCircleLines(_,_,_,_)' { rl_wren_draw_circle_lines }
		'drawTriangleLines(_,_,_,_)' { rl_wren_draw_triangle_lines }
		// lines
		'drawLine(_,_,_,_,_)' { rl_wren_draw_line }
		'drawLineV(_,_,_)' { rl_wren_draw_line_v }
		'drawLineEx(_,_,_,_)' { rl_wren_draw_line_ex }
		// text
		'drawText(_,_,_,_,_)' { rl_wren_draw_text }
		'drawFps(_,_)' { rl_wren_draw_fps }
		'measureText(_,_)' { rl_wren_measure_text }
		// keyboard
		'isKeyDown(_)' { rl_wren_is_key_down }
		'isKeyPressed(_)' { rl_wren_is_key_pressed }
		'isKeyReleased(_)' { rl_wren_is_key_released }
		'isKeyUp(_)' { rl_wren_is_key_up }
		// mouse
		'isMouseButtonDown(_)' { rl_wren_is_mouse_button_down }
		'isMouseButtonPressed(_)' { rl_wren_is_mouse_button_pressed }
		'isMouseButtonReleased(_)' { rl_wren_is_mouse_button_released }
		'getMousePosition()' { rl_wren_get_mouse_position }
		'getMouseDelta()' { rl_wren_get_mouse_delta }
		'getMouseWheelMove()' { rl_wren_get_mouse_wheel_move }
		// gamepad
		'isGamepadAvailable(_)' { rl_wren_is_gamepad_available }
		'isGamepadButtonDown(_,_)' { rl_wren_is_gamepad_button_down }
		'isGamepadButtonPressed(_,_)' { rl_wren_is_gamepad_button_pressed }
		'isGamepadButtonReleased(_,_)' { rl_wren_is_gamepad_button_released }
		'isGamepadButtonUp(_,_)' { rl_wren_is_gamepad_button_up }
		'getGamepadAxisMovement(_,_)' { rl_wren_get_gamepad_axis_movement }
		'getGamepadAxisCount(_)' { rl_wren_get_gamepad_axis_count }
		// cursor
		'showCursor()' { rl_wren_show_cursor }
		'hideCursor()' { rl_wren_hide_cursor }
		'isCursorHidden' { rl_wren_is_cursor_hidden }
		'enableCursor()' { rl_wren_enable_cursor }
		'disableCursor()' { rl_wren_disable_cursor }
		else { unsafe { nil } }
	}
}
