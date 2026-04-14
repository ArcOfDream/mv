module mv

import wren

type WrenBindFn = fn (string) wren.ForeignMethodFn

pub struct WrenClassDef {
pub:
	name           string
	class          ?fn () wren.ForeignClassMethods
	methods        ?WrenBindFn // instance methods
	static_methods ?WrenBindFn // static methods (RL, etc.)
}

pub fn wren_get_object[T](vm &wren.VM, slot int) &T {
	return unsafe { &T(vm.get_slot_foreign(slot)) }
}

pub fn wren_push_foreign[T](vm &wren.VM, slot int, class_slot int, class_name string, val T) {
	vm.ensure_slots(class_slot + 1)
	vm.get_variable('main', class_name, class_slot)
	raw := vm.set_slot_new_foreign(slot, class_slot, sizeof(T))
	unsafe {
		//mut ptr := &T(raw) // getting unused variable here
		//*ptr = val
		*(&T(raw)) = val
	}
}

pub fn wren_alloc[T](vm &wren.VM) &T {
	raw := vm.set_slot_new_foreign(0, 0, sizeof(T))
	return unsafe { &T(raw) }
}

pub fn wren_class(alloc fn (&wren.VM), fin fn (voidptr)) wren.ForeignClassMethods {
	return wren.ForeignClassMethods{
		allocate: alloc
		finalize: fin
	}
}

@[inline]
pub fn wren_nothing(_ &wren.VM) {}

pub fn wren_noop_finalize(_ voidptr) {}

@[inline]
pub fn wren_get_f32(vm &wren.VM, slot int) f32 {
	return f32(vm.get_slot_double(slot))
}

@[inline]
pub fn wren_get_int(vm &wren.VM, slot int) int {
	return int(vm.get_slot_double(slot))
}

@[inline]
pub fn wren_get_u8(vm &wren.VM, slot int) u8 {
	return u8(vm.get_slot_double(slot))
}

// NativeApp static bind

fn native_app_wren_set_root(vm &wren.VM) {
	mut app := unsafe { &App(vm.get_user_data()) }
	app.scene_root = wren_get_object[Node](vm, 1)
}

fn native_app_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		'setRoot(_)' { native_app_wren_set_root }
		else { unsafe { nil } }
	}
}

// class defs

const wren_class_defs = [
	WrenClassDef{
		name:    'Vec2'
		class:   vec2_wren_class_methods
		methods: vec2_wren_bind_method
	},
	WrenClassDef{
		name:    'Color'
		class:   color_wren_class_methods
		methods: color_wren_bind_method
	},
	WrenClassDef{
		name:    'NativeNode'
		class:   node_wren_class_methods
		methods: node_wren_bind_method
	},
	WrenClassDef{
		name:    'NativeSprite'
		class:   sprite_wren_class_methods
		methods: sprite_wren_bind_method
	},
	WrenClassDef{
		name:           'NativeApp'
		static_methods: native_app_wren_bind_method
	},
	WrenClassDef{
		name:           'RL'
		static_methods: rl_wren_bind_method
	},
]

// wren error funcs

fn wren_write(_vm &wren.VM, text &char) {
	print(unsafe { cstring_to_vstring(text) })
}

fn wren_error(_vm &wren.VM, typ wren.ErrorType, mod_ &char, line int, msg &char) {
	module_str := if mod_ != unsafe { nil } {
		unsafe { cstring_to_vstring(mod_) }
	} else {
		'<unknown>'
	}
	msg_str := if msg != unsafe { nil } {
		unsafe { cstring_to_vstring(msg) }
	} else {
		'<no message>'
	}
	match typ {
		.compile { eprintln('[wren compile] ${module_str}:${line}: ${msg_str}') }
		.runtime { eprintln('[wren runtime] ${msg_str}') }
		.stack_trace { eprintln('  at ${module_str}:${line}') }
	}
}

// top-level dispatchers

pub fn wren_bind_method(vm &wren.VM, mod_ &char, cls_ &char, is_static bool, sig_ &char) wren.ForeignMethodFn {
	class_name := unsafe { cstring_to_vstring(cls_) }
	signature := unsafe { cstring_to_vstring(sig_) }
	app := unsafe { &App(vm.get_user_data()) }

	mut all_defs := wren_class_defs.clone()
	if setup := app.wren {
		all_defs << setup.class_defs
	}

	for def in all_defs {
		if def.name != class_name {
			continue
		}
		if is_static {
			return if methods := def.static_methods { methods(signature) } else { wren_nothing }
		}
		return if methods := def.methods { methods(signature) } else { wren_nothing }
	}
	return wren_nothing
}

pub fn wren_bind_class(vm &wren.VM, mod_ &char, cls_ &char) wren.ForeignClassMethods {
	if unsafe { cstring_to_vstring(mod_) } != 'main' {
		return wren.ForeignClassMethods{}
	}
	class_name := unsafe { cstring_to_vstring(cls_) }
	app := unsafe { &App(vm.get_user_data()) }

	mut all_defs := wren_class_defs.clone()
	if setup := app.wren {
		all_defs << setup.class_defs
	}

	for def in all_defs {
		if def.name == class_name {
			if cls := def.class {
				return cls()
			}
		}
	}
	return wren.ForeignClassMethods{}
}
