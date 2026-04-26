module engine

import raylib as rl
import core { RectF }

// Control is a Node that owns a screen-space rectangle.
// does not perform layout - callers set rect directly.
// children inherit no automatic positioning; they use their own rect.
// when clip is true, drawing of self and all descendants is scissored to the
// global rect (computed by walking the parent Control chain).
@[heap]
pub struct Control {
	Node
pub mut:
	rect RectF
	clip bool
}

pub fn Control.new(app &App, name string) &Control {
	return &Control{
		app:       app
		node_name: name
	}
}

fn (c &Control) wren_class_name() string {
	return 'Control'
}

// get_global_rect returns the rect in screen space, offset by all ancestor Controls.
pub fn (c &Control) get_global_rect() RectF {
	mut ox := f32(0)
	mut oy := f32(0)
	mut p := c.parent
	for {
		anc := p or { break }
		if anc is Control {
			ox += anc.rect.x
			oy += anc.rect.y
			p = anc.parent
		} else {
			break
		}
	}
	return RectF{c.rect.x + ox, c.rect.y + oy, c.rect.w, c.rect.h}
}

fn (mut c Control) push_mat_internal() {
	c.Node.push_mat_internal()
	if c.clip {
		r := c.get_global_rect()
		rl.begin_scissor_mode(int(r.x), int(r.y), int(r.w), int(r.h))
	}
}

fn (mut c Control) pop_mat_internal() {
	if c.clip {
		rl.end_scissor_mode()
	}
	c.Node.pop_mat_internal()
}

pub fn (c &Control) init() {}

pub fn (c &Control) ready() {}

pub fn (c &Control) exit_tree() {}

pub fn (mut c Control) update(_dt f32) {}

pub fn (c &Control) draw() {}
