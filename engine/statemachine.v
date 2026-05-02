module engine

/*
StateMachine: named-state dispatcher with enter / update / exit callbacks.

Each state is a named slot with three optional callbacks. Transitions are
immediate and re-entrant calls within a transition are silently dropped to
prevent callback loops. The 'state_changed' signal fires after on_enter
completes, carrying (old_state string, new_state string) as args.

Basic usage:

	mut sm := app.new_node[StateMachine]('state', 0, 0)
	sm.add_state('idle',
		on_enter: fn () { sprite.play('idle') }
		on_update: fn (dt f32) { if input.x != 0 { sm.transition_to('run') } }
	)
	sm.add_state('run',
		on_enter: fn () { sprite.play('run') }
		on_update: fn (dt f32) { if input.x == 0 { sm.transition_to('idle') } }
		on_exit:  fn () { dust_particles.burst() }
	)
	sm.transition_to('idle')  // set initial state

All callbacks are optional. States with only on_update can be added with
add_state_simple(name, fn(dt f32) { ... }).
*/

pub const sig_sm_state_changed = 'state_changed'

pub struct State {
pub mut:
	on_enter  ?fn ()
	on_exit   ?fn ()
	on_update ?fn (f32)
}

@[heap]
pub struct StateMachine {
	Node
pub mut:
	current string
	signals SignalTable
mut:
	states        map[string]State
	transitioning bool
	process_flags ProcessFlags
}

pub fn StateMachine.instantiate(app &App, name string) &StateMachine {
	return &StateMachine{
		app:       app
		node_name: name
	}
}

fn (n &StateMachine) wren_class_name() string {
	return 'StateMachine'
}

pub fn (mut sm StateMachine) add_state(name string, state State) {
	sm.states[name] = state
}

pub fn (mut sm StateMachine) add_state_simple(name string, on_update fn (f32)) {
	sm.states[name] = State{
		on_update: on_update
	}
}

// transition_to switches to a named state immediately, calling on_exit on the
// previous state and on_enter on the new one. Re-entrant calls are dropped.
pub fn (mut sm StateMachine) transition_to(name string) {
	if name !in sm.states {
		return
	}
	if sm.transitioning {
		return
	}
	sm.transitioning = true

	old := sm.current
	if old != '' {
		if prev := sm.states[old] {
			if cb := prev.on_exit {
				cb()
			}
		}
	}

	sm.current = name

	if next := sm.states[name] {
		if cb := next.on_enter {
			cb()
		}
	}

	sm.transitioning = false
	sm.signals.emit(sig_sm_state_changed, sm, [SignalArg(old), SignalArg(name)], sm.app.wren_vm,
		sm.app.wren_signal_call_handles)
}

@[inline]
pub fn (sm &StateMachine) is(name string) bool {
	return sm.current == name
}

@[inline]
pub fn (sm &StateMachine) has_state(name string) bool {
	return name in sm.states
}

fn (mut sm StateMachine) update_internal(dt f32) {
	if sm.current == '' {
		return
	}
	if state := sm.states[sm.current] {
		if cb := state.on_update {
			cb(dt)
		}
	}
}
