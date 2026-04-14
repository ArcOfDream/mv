module mv

import wren
import raylib as rl

fn sprite_wren_allocate(vm &wren.VM) {
	mut s := wren_alloc[Sprite](vm)
	s.init_from_wren(vm)
}

pub fn sprite_wren_class_methods() wren.ForeignClassMethods {
	return wren_class(sprite_wren_allocate, wren_noop_finalize)
}

// centered

fn sprite_wren_get_centered(vm &wren.VM) {
	vm.set_slot_bool(0, wren_get_object[Sprite](vm, 0).get_centered())
}

fn sprite_wren_set_centered(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.set_centered(vm.get_slot_bool(1))
}

// offset

fn sprite_wren_get_offset(vm &wren.VM) {
	offset := wren_get_object[Sprite](vm, 0).get_offset()
	wren_push_foreign[Vec2](vm, 0, 1, 'Vec2', offset)
}

fn sprite_wren_set_offset(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.set_offset(*wren_get_object[Vec2](vm, 1))
}

// texture

fn sprite_wren_get_texture_id(vm &wren.VM) {
	vm.set_slot_string(0, wren_get_object[Sprite](vm, 0).texture_id)
}

fn sprite_wren_set_texture_id(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.set_texture_id(vm.get_slot_string(1))
}

// shader

fn sprite_wren_get_shader_id(vm &wren.VM) {
	vm.set_slot_string(0, wren_get_object[Sprite](vm, 0).get_shader_id())
}

fn sprite_wren_set_shader_id(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.set_shader_id(vm.get_slot_string(1))
}

// tint

fn sprite_wren_get_tint(vm &wren.VM) {
	tint := wren_get_object[Sprite](vm, 0).tint
	wren_push_foreign[rl.Color](vm, 0, 1, 'Color', tint)
}

fn sprite_wren_set_tint(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.tint = *wren_get_object[rl.Color](vm, 1)
}

// frames

fn sprite_wren_get_h_frames(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Sprite](vm, 0).h_frames)
}

fn sprite_wren_set_h_frames(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.h_frames = wren_get_int(vm, 1)
}

fn sprite_wren_get_v_frames(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Sprite](vm, 0).v_frames)
}

fn sprite_wren_set_v_frames(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.v_frames = wren_get_int(vm, 1)
}

fn sprite_wren_get_current_frame(vm &wren.VM) {
	vm.set_slot_double(0, wren_get_object[Sprite](vm, 0).current_frame)
}

fn sprite_wren_set_current_frame(vm &wren.VM) {
	mut s := wren_get_object[Sprite](vm, 0)
	s.current_frame = wren_get_int(vm, 1)
}

// dispatch

pub fn sprite_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		'centered' { sprite_wren_get_centered }
		'centered=(_)' { sprite_wren_set_centered }
		'offset' { sprite_wren_get_offset }
		'offset=(_)' { sprite_wren_set_offset }
		'textureId' { sprite_wren_get_texture_id }
		'textureId=(_)' { sprite_wren_set_texture_id }
		'shaderId' { sprite_wren_get_shader_id }
		'shaderId=(_)' { sprite_wren_set_shader_id }
		'tint' { sprite_wren_get_tint }
		'tint=(_)' { sprite_wren_set_tint }
		'hFrames' { sprite_wren_get_h_frames }
		'hFrames=(_)' { sprite_wren_set_h_frames }
		'vFrames' { sprite_wren_get_v_frames }
		'vFrames=(_)' { sprite_wren_set_v_frames }
		'currentFrame' { sprite_wren_get_current_frame }
		'currentFrame=(_)' { sprite_wren_set_current_frame }
		// sprite embeds Node at offset zero: the recovered pointer is valid
		// for all Node fields, so inherited behaviour falls through cleanly
		else { node_wren_bind_method(signature) }
	}
}
