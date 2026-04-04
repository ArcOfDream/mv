module mv

import wren

fn wren_get_object[T](vm &wren.VM) &T {
	return unsafe { &T(vm.get_slot_foreign(0)) }
}

@[inline]
fn wren_nothing(_ &wren.VM) {}

fn wren_write(_vm &wren.VM, text &char) {
    print(unsafe { cstring_to_vstring(text) })
}

fn wren_error(_vm &wren.VM, typ wren.ErrorType, mod_ &char, line int, msg &char) {
    module_str := unsafe { cstring_to_vstring(mod_) }
    msg_str    := unsafe { cstring_to_vstring(msg) }
    match typ {
        .compile     { eprintln('[wren compile] ${module_str}:${line}: ${msg_str}') }
        .runtime     { eprintln('[wren runtime] ${msg_str}') }
        .stack_trace { eprintln('  at ${module_str}:${line}') }
    }
}

// top-level dispatchers

pub fn wren_bind_method(vm &wren.VM,
	mod_ &char,
	cls_ &char,
	is_static bool,
	sig_ &char) wren.ForeignMethodFn {
	class_name := unsafe { cstring_to_vstring(cls_) }
	_ := unsafe { cstring_to_vstring(mod_) } // mod
	signature := unsafe { cstring_to_vstring(sig_) }

	if is_static {
        return match class_name {
            'RL' { rl_wren_bind_method(signature) }
            else { unsafe { nil } }
        }
    }

	return match class_name {
		'Vec2' { vec2_wren_bind_method(signature) }
		'Color'   { color_wren_bind_method(signature) }
		'Node' { node_wren_bind_method(signature) }
		'Sprite' { sprite_wren_bind_method(signature) }
		else { unsafe { nil } }
	}
}

pub fn wren_bind_class(vm &wren.VM,
	mod_ &char,
	cls_ &char) wren.ForeignClassMethods {
	if unsafe { cstring_to_vstring(mod_) } != 'main' {
		return wren.ForeignClassMethods{}
	}
	return match unsafe { cstring_to_vstring(cls_) } {
		'Vec2' { vec2_wren_class_methods() }
		'Color'   { color_wren_class_methods() }
		'Node' { node_wren_class_methods() }
		'Sprite' { sprite_wren_class_methods() }
		else { wren.ForeignClassMethods{} }
	}
}
