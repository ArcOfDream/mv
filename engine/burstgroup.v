module engine

// BurstGroup is adapted from BurstParticles2D by Ian Sly (ivysly)
// https://github.com/ivysly/BurstParticles2D (or wherever the original is hosted)
// Copyright (c) 2023 Ian Sly ivysly@protonmail.com: MIT License
// See LICENSES/BurstParticles2D-MIT.txt for the full license text.

/*
BurstGroup: usage example

BurstGroup fires multiple BurstEmitters simultaneously and emits
sig_group_finished only after every child's particles have expired.
Use it for composite effects: a hit effect that combines a flash,
a spark spray, and a debris scatter, all timed together.

	mut hit_effect := BurstGroup.new(app, 'hit_effect')
	hit_effect.autoplay  = false
	parent.add_child(mut hit_effect)

	// create and register each emitter
	mut flash  := BurstEmitter.new(app, 'flash')   // ... configure flash ...
	mut sparks := BurstEmitter.new(app, 'sparks')   // ... configure sparks ...
	mut debris := BurstEmitter.new(app, 'debris')   // ... configure debris ...

	// add_emitter connects the child's finished signal automatically
	hit_effect.add_emitter(mut flash)
	hit_effect.add_emitter(mut sparks)
	hit_effect.add_emitter(mut debris)

	// fire all emitters at once
	hit_effect.burst()

	// clean up after the whole effect has finished
	hit_effect.signals.connect(engine.sig_group_finished, VSignalHandler{
		func: fn (recv voidptr, _ voidptr, _ []engine.SignalArg) {
			mut g := unsafe { &BurstGroup(recv) }
			g.queue_free()
		}
		receiver: hit_effect
	})

repeat = true causes burst() to be called again automatically each time
the group finishes, useful for looping ambient composite effects.
*/

pub const sig_group_finished = 'group_finished'

// BurstGroup coordinates multiple BurstEmitters, firing them simultaneously
// and emitting sig_group_finished only after every emitter's particles have expired.
// Add emitters via add_emitter() before or after entering the tree.
@[heap]
pub struct BurstGroup {
	Node
pub mut:
	repeat   bool
	autoplay bool = true
	signals  SignalTable

	// internal
	emitters []&BurstEmitter
	pending  int // emitters that have not yet finished
}

pub fn BurstGroup.instantiate(app &App, name string) &BurstGroup {
	return &BurstGroup{
		app:       app
		node_name: name
	}
}

pub fn BurstGroup.new(app &App, name string) &BurstGroup {
	return &BurstGroup{
		app:       app
		node_name: name
	}
}

fn (g &BurstGroup) wren_class_name() string {
	return 'BurstGroup'
}

// add_emitter registers an emitter with this group and connects its finished signal.
// Call before burst(): emitters added after a burst is in progress are not
// counted toward that burst's completion.
pub fn (mut g BurstGroup) add_emitter(mut emitter BurstEmitter) {
	g.emitters << &emitter
	emitter.signals.connect(sig_burst_finished, VSignalHandler{
		func:     burst_group_child_done
		receiver: voidptr(g)
	})
}

// burst fires all registered emitters simultaneously.
pub fn (mut g BurstGroup) burst() {
	if g.emitters.len == 0 {
		return
	}
	g.pending = g.emitters.len
	for mut e in g.emitters {
		e.burst()
	}
}

// tree callbacks

fn (mut g BurstGroup) ready_internal() {
	if g.autoplay {
		g.burst()
	}
}

fn (mut g BurstGroup) exit_tree_internal() {
	g.signals.clear()
}

// burst_group_child_done is called each time a child emitter emits sig_burst_finished.
fn burst_group_child_done(receiver voidptr, _sender voidptr, _args []SignalArg) {
	mut g := unsafe { &BurstGroup(receiver) }
	g.pending--
	if g.pending > 0 {
		return
	}
	g.pending = 0
	// TODO: replace none/[] with app.wren_vm / app.wren_call_handles for Wren support
	g.signals.emit(sig_group_finished, g, [], none, [])
	if g.repeat {
		g.burst()
	}
}
