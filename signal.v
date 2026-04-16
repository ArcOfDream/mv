module mv

import core { Vec2 }
import wren

/*
SignalTable — usage example
 
Declare signals as plain string constants on the owning type:
 
	pub const sig_health_changed = 'health_changed'
	pub const sig_died           = 'died'
 
Embed a SignalTable and emit from within the owning struct:
 
	pub struct Enemy {
		Node
	pub mut:
		health  int = 100
		signals SignalTable
	}
 
	pub fn (mut e Enemy) take_damage(amount int) {
		e.health -= amount
		e.signals.emit(sig_health_changed, e, [SignalArg(e.health)], none, app.wren_call_handles)
 
		if e.health <= 0 {
			e.signals.emit(sig_died, e, [], none, app.wren_call_handles)
		}
	}
 
Connect a persistent V handler (receiver required so the callback has a self pointer):
 
	e.signals.connect(sig_health_changed, VSignalHandler{
		func:     on_health_changed
		receiver: hud        // &HUD, passed as receiver in the callback
	})
 
	fn on_health_changed(receiver voidptr, sender voidptr, args []SignalArg) {
		mut hud := unsafe { &HUD(receiver) }
		if args.len > 0 {
			if hp := args[0] as int {
				hud.update_bar(hp)
			}
		}
	}
 
Connect a fire-once handler (auto-removed after the first emit):
 
	e.signals.connect(sig_died, VSignalHandler{
		func:     on_first_death
		receiver: achievement_tracker
		once:     true
	})
 
Disconnect a specific handler without clearing others on the same signal:
 
	e.signals.disconnect(sig_health_changed, on_health_changed, hud)
 
Connect a Wren handler (the Wren method receives args as positional parameters):
 
	// In Wren:
	//   enemy.connect("health_changed", Fn.new { |hp| HealthBar.update(hp) })
	e.signals.connect(sig_health_changed, WrenSignalHandler{ handle: wren_fn_handle })
*/

// SignalArg covers the value types that can cross the V/Wren boundary.
// voidptr is intentionally excluded — pass node references by name or handle instead.
pub type SignalArg = bool | int | f32 | string | Vec2

// Handler types

pub type SignalHandlerFn = fn (receiver voidptr, sender voidptr, args []SignalArg)

pub struct VSignalHandler {
pub:
	func     SignalHandlerFn @[required]
	receiver ?voidptr        // if none, voidptr(0) is passed as receiver at call time
	once     bool            // if true, removed after first fire
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
	t.handlers[signal] << handler
}

// disconnect removes the specific V handler identified by func + receiver.
// Wren handlers are unaffected; use disconnect_all to clear those.
pub fn (mut t SignalTable) disconnect(signal string, func SignalHandlerFn, receiver ?voidptr) {
	mut existing := t.handlers[signal] or { return }
	t.handlers[signal] = existing.filter(fn [func, receiver] (h SignalHandler) bool {
		if h is VSignalHandler {
			return !(h.func == func && h.receiver == receiver)
		}
		return true
	})
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
// Handlers with once: true are removed after the full dispatch pass completes.
// call_handles is indexed by arg count 0..N and must be pre-populated by the caller.
pub fn (mut t SignalTable) emit(signal string, sender voidptr, args []SignalArg, vm ?&wren.VM, call_handles []?&wren.Handle) {
	mut handlers := t.handlers[signal] or { return }

	for mut h in handlers {
		match mut h {
			VSignalHandler {
				// receiver: none is treated as voidptr(0) rather than silently skipping
				receiver := h.receiver or { voidptr(0) }
				h.func(receiver, sender, args)
			}
			WrenSignalHandler {
				if mut vm_ := vm {
					wren_call_signal(vm_, h.handle, args, call_handles)
				}
			}
		}
	}

	// remove once-handlers after full dispatch so all subscribers fire before any are dropped
	if handlers.any(fn (h SignalHandler) bool {
		return h is VSignalHandler && (h as VSignalHandler).once
	}) {
		t.handlers[signal] = handlers.filter(fn (h SignalHandler) bool {
			if h is VSignalHandler {
				return !h.once
			}
			return true
		})
	}
}

// Wren slot helpers

// wren_push_signal_arg pushes a non-Vec2 SignalArg into a Wren slot.
// Vec2 is handled separately in wren_call_signal because it requires a scratch slot.
fn wren_push_signal_arg(vm &wren.VM, slot int, arg SignalArg) {
	match arg {
		bool   { vm.set_slot_bool(slot, arg) }
		int    { vm.set_slot_double(slot, arg) }
		f32    { vm.set_slot_double(slot, arg) }
		string { vm.set_slot_string(slot, arg) }
		Vec2   {} // handled by caller
	}
}

fn wren_call_signal(vm &wren.VM, handle &wren.Handle, args []SignalArg, call_handles []?&wren.Handle) {
	n := args.len
	if n >= call_handles.len {
		println('warning: signal arg count ${n} exceeds supported wren call handle count')
		return
	}

	// Vec2 args each need one scratch slot, allocated after all argument slots
	// to avoid collisions (e.g. two Vec2 args at slots 1 and 2 would otherwise
	// both try to use their neighbour as a scratch slot)
	vec2_count := args.count(it is Vec2)
	vm.ensure_slots(n + 1 + vec2_count)
	vm.set_slot_handle(0, handle)

	mut scratch := n + 1
	for i, arg in args {
		slot := i + 1
		if arg is Vec2 {
			wren_push_foreign[Vec2](vm, slot, scratch, 'Vec2', arg)
			scratch++
		} else {
			wren_push_signal_arg(vm, slot, arg)
		}
	}

	if ch := call_handles[n] {
		vm.call(ch)
	}
}