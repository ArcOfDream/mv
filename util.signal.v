module mv

import wren

// Signal argument type
// covers the value types that can cross the V/Wren boundary. voidptr is
// intentionally excluded, pass node references by name or handle instead
pub type SignalArg = bool | int | f32 | string | Vec2

// Handler types

pub type SignalHandlerFn = fn (receiver voidptr, sender voidptr, args []SignalArg)

pub struct VSignalHandler {
pub:
	func     SignalHandlerFn @[required]
	receiver ?voidptr
}

pub struct WrenSignalHandler {
pub mut:
	handle &wren.Handle
}

pub type SignalHandler = VSignalHandler | WrenSignalHandler

// Signal table

pub struct SignalTable {
mut:
	handlers map[string][]SignalHandler
}

pub fn (mut t SignalTable) connect(signal string, handler SignalHandler) {
	if signal !in t.handlers {
		t.handlers[signal] = []SignalHandler{}
	}
	t.handlers[signal] << handler
}

pub fn (mut t SignalTable) disconnect_all(signal string) {
	t.handlers.delete(signal)
}

pub fn (mut t SignalTable) clear() {
	t.handlers.clear()
}

pub fn (t &SignalTable) has_signal(signal string) bool {
	return signal in t.handlers
}

// emit dispatches to all V and Wren handlers registered for signal.
// call_handles is indexed by arg count 0..4
pub fn (mut t SignalTable) emit(signal string, sender voidptr, args []SignalArg, vm ?&wren.VM, call_handles []?&wren.Handle) {
	mut handlers := t.handlers[signal] or { return }
	for mut h in handlers {
		match mut h {
			VSignalHandler {
				if receiver := h.receiver {
					h.func(receiver, sender, args)
				}
			}
			WrenSignalHandler {
				if mut vm_ := vm {
					wren_call_signal(vm_, h.handle, args, call_handles)
				}
			}
		}
	}
}

// Wren slot helpers

fn wren_push_signal_arg(vm &wren.VM, slot int, arg SignalArg) {
	match arg {
		bool { vm.set_slot_bool(slot, arg) }
		int { vm.set_slot_double(slot, arg) }
		f32 { vm.set_slot_double(slot, arg) }
		string { vm.set_slot_string(slot, arg) }
		// Vec2 needs a class scratch slot, use slot+1, caller ensures capacity
		Vec2 { wren_push_foreign[Vec2](vm, slot, slot + 1, 'Vec2', arg) }
	}
}

fn wren_call_signal(vm &wren.VM, handle &wren.Handle, args []SignalArg, call_handles []?&wren.Handle) {
	n := args.len
	if n >= call_handles.len {
		println('warning: signal arg count exceeds supported wren arg count')
		return
	}
	// Vec2 args each need an extra scratch slot for the class variable
	vec2_count := args.count(it is Vec2)
	vm.ensure_slots(n + 1 + vec2_count)
	vm.set_slot_handle(0, handle)
	for i, arg in args {
		wren_push_signal_arg(vm, i + 1, arg)
	}
	if ch := call_handles[n] {
		vm.call(ch)
	}
}
