module input

import raylib as rl
import stringname { StringName, StringNameMap }

pub enum InputDevice {
	keyboard
	mouse_button
}

pub struct InputBinding {
pub:
	device InputDevice
	code int
}

// helper functions for constructing InputBindings
pub fn key(k rl.KeyboardKey) InputBinding {
	return InputBinding{
		device: .keyboard
		code: int(k)
	}
}

pub fn mouse_btn(b rl.MouseButton) InputBinding {
	return InputBinding{
		device: .keyboard
		code: int(b)
	}
}

pub struct InputMap {
mut:
	names &StringNameMap
	actions map[voidptr][]InputBinding
	pressed map[voidptr]bool
	just_pressed map[voidptr]bool
	just_released map[voidptr]bool
}

pub fn InputMap.new(names &StringNameMap) &InputMap {
	return &InputMap{ names: names }
}

fn (mut im InputMap) sn(val string) StringName {
	return im.names.new(val)
}

pub fn (mut im InputMap) add_action(name StringName, bindings ...InputBinding) {
	im.actions[name.ptr] = bindings
}

pub fn (mut im InputMap) add_binding(name StringName, binding InputBinding) {
	im.actions[name.ptr] << binding
}

pub fn (mut im InputMap) remove_action(name StringName) {
	im.actions.delete(name)
	im.pressed.delete(name)
	im.just_pressed.delete(name)
	im.just_released.delete(name)
}

pub fn (mut im InputMap) update() {
	for ptr, bindings in im.actions {
		mut any_down := false
		for b in bindings {
			down := match b.device {
				.keyboard     { rl.is_key_down(b.code) }
				.mouse_button { rl.is_mouse_button_down(b.code) }
			}
			if down {
				any_down = true
				break
			}
		}

		was := im.pressed[ptr] or { false }
		im.just_pressed[ptr]  = any_down && !was
		im.just_released[ptr] = !any_down && was
		im.pressed[ptr]       = any_down
	}
}

pub fn (im &InputMap) is_action_pressed(name StringName) bool {
	return im.pressed[name] or { false }
}

pub fn (im &InputMap) is_action_just_pressed(name StringName) bool {
	return im.just_pressed[name] or { false }
}

pub fn (im &InputMap) is_action_just_released(name StringName) bool {
	return im.just_released[name] or { false }
}