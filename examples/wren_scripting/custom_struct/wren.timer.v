module main

import wren
import mv

fn timer_wren_allocate(vm &wren.VM) {
	mut t := mv.wren_alloc[Timer](vm)
	t.duration = mv.wren_get_f32(vm, 1)
	t.looping = vm.get_slot_bool(2)
	t.elapsed = 0
	t.running = false
}

pub fn timer_wren_class_methods() wren.ForeignClassMethods {
	return mv.wren_class(timer_wren_allocate, mv.wren_noop_finalize)
}

// control 

fn timer_wren_start(vm &wren.VM) {
	mut t := mv.wren_get_object[Timer](vm, 0)
	t.start()
}

fn timer_wren_stop(vm &wren.VM) {
	mut t := mv.wren_get_object[Timer](vm, 0)
	t.stop()
}

fn timer_wren_reset(vm &wren.VM) {
	mut t := mv.wren_get_object[Timer](vm, 0)
	t.reset()
}

fn timer_wren_tick(vm &wren.VM) {
	mut t := mv.wren_get_object[Timer](vm, 0)
	vm.set_slot_bool(0, t.tick(mv.wren_get_f32(vm, 1)))
}

// getters

fn timer_wren_get_progress(vm &wren.VM) {
	vm.set_slot_double(0, mv.wren_get_object[Timer](vm, 0).progress())
}

fn timer_wren_get_is_done(vm &wren.VM) {
	vm.set_slot_bool(0, mv.wren_get_object[Timer](vm, 0).is_done())
}

fn timer_wren_get_time_left(vm &wren.VM) {
	vm.set_slot_double(0, mv.wren_get_object[Timer](vm, 0).time_left())
}

fn timer_wren_get_running(vm &wren.VM) {
	vm.set_slot_bool(0, mv.wren_get_object[Timer](vm, 0).running)
}

fn timer_wren_get_duration(vm &wren.VM) {
	vm.set_slot_double(0, mv.wren_get_object[Timer](vm, 0).duration)
}

fn timer_wren_get_looping(vm &wren.VM) {
	vm.set_slot_bool(0, mv.wren_get_object[Timer](vm, 0).looping)
}

// setters

fn timer_wren_set_duration(vm &wren.VM) {
	mut t := mv.wren_get_object[Timer](vm, 0)
	t.duration = mv.wren_get_f32(vm, 1)
}

fn timer_wren_set_looping(vm &wren.VM) {
	mut t := mv.wren_get_object[Timer](vm, 0)
	t.looping = vm.get_slot_bool(1)
}

// dispatch

pub fn timer_wren_bind_method(signature string) wren.ForeignMethodFn {
	return match signature {
		'start()' { timer_wren_start }
		'stop()' { timer_wren_stop }
		'reset()' { timer_wren_reset }
		'tick(_)' { timer_wren_tick }
		'progress' { timer_wren_get_progress }
		'isDone' { timer_wren_get_is_done }
		'timeLeft' { timer_wren_get_time_left }
		'running' { timer_wren_get_running }
		'duration' { timer_wren_get_duration }
		'duration=(_)' { timer_wren_set_duration }
		'looping' { timer_wren_get_looping }
		'looping=(_)' { timer_wren_set_looping }
		else { unsafe { nil } }
	}
}
