module engine

import core { Vec2 }
import physics

/*
Area2D: non-colliding detection zone.

Queries the spatial hash each frame to detect which PhysicsBodies overlap its
shape, then fires callbacks on enter and exit transitions.

Bodies are tested with narrow-phase manifold after the broad-phase hash pass,
so all shapes (AABB, Circle, Capsule, Polygon) are handled correctly.

Basic usage:

	mut zone := app.new_node[Area2D]('damage_zone', 0, 0)
	zone.shape = physics.AABB{ min: physics.Vec{-16, -16}, max: physics.Vec{16, 16} }
	zone.on_body_entered = fn (body &PhysicsBody) {
		println('entered: ${body.name()}')
	}

Layer / mask filtering mirrors PhysicsBody: the area only detects bodies whose
collision_layer overlaps the area's collision_mask.

Note: Area2D relies on PhysicsBodies registering their world shape via
update_internal. Place Area2D after PhysicsBodies in the scene tree
(or as a sibling added later) to ensure bodies are registered before the
area queries them within the same frame.
*/

pub const sig_area_body_entered = 'body_entered'
pub const sig_area_body_exited = 'body_exited'

@[heap]
pub struct Area2D {
	Node
pub mut:
	shape           physics.Shape = physics.AABB{}
	shape_offset    Vec2
	collision_layer u32  = 1
	collision_mask  u32  = 1
	monitoring      bool = true

	on_body_entered ?fn (body &PhysicsBody)
	on_body_exited  ?fn (body &PhysicsBody)

	signals SignalTable
mut:
	process_flags ProcessFlags
	overlapping   map[int]bool
}

pub fn Area2D.instantiate(app &App, name string) &Area2D {
	return &Area2D{
		app:       app
		node_name: name
	}
}

pub fn Area2D.new(app &App, name string, shape physics.Shape) &Area2D {
	return &Area2D{
		app:       app
		node_name: name
		shape:     shape
	}
}

fn (n &Area2D) wren_class_name() string {
	return 'Area2D'
}

// layer / mask helpers

@[inline]
pub fn (mut a Area2D) set_layer(layer int) {
	a.collision_layer |= 1 << (layer - 1)
}

@[inline]
pub fn (mut a Area2D) clear_layer(layer int) {
	a.collision_layer &= ~(1 << (layer - 1))
}

@[inline]
pub fn (mut a Area2D) set_mask(layer int) {
	a.collision_mask |= 1 << (layer - 1)
}

@[inline]
pub fn (mut a Area2D) clear_mask(layer int) {
	a.collision_mask &= ~(1 << (layer - 1))
}

// get_overlapping_bodies returns a snapshot of currently overlapping bodies.
pub fn (a &Area2D) get_overlapping_bodies(app &App) []&PhysicsBody {
	mut out := []&PhysicsBody{}
	for id, _ in a.overlapping {
		if body := app.bodies[id] {
			out << body
		}
	}
	return out
}

pub fn (a &Area2D) is_body_overlapping(body &PhysicsBody) bool {
	return body.body_id in a.overlapping
}

// world_shape returns the area shape translated into world space.
pub fn (mut a Area2D) world_shape() physics.Shape {
	wp := a.get_global_pos() + a.shape_offset
	return match mut a.shape {
		physics.Circle {
			physics.Circle{
				p: physics.Vec{a.shape.p.x + wp.x, a.shape.p.y + wp.y}
				r: a.shape.r
			}
		}
		physics.AABB {
			physics.AABB{
				min: physics.Vec{a.shape.min.x + wp.x, a.shape.min.y + wp.y}
				max: physics.Vec{a.shape.max.x + wp.x, a.shape.max.y + wp.y}
			}
		}
		physics.Capsule {
			physics.Capsule{
				a: physics.Vec{a.shape.a.x + wp.x, a.shape.a.y + wp.y}
				b: physics.Vec{a.shape.b.x + wp.x, a.shape.b.y + wp.y}
				r: a.shape.r
			}
		}
		else {
			a.shape
		}
	}
}

fn (mut a Area2D) update_internal(_dt f32) {
	if !a.monitoring {
		return
	}

	ws := a.world_shape()
	candidates := a.app.physics_world.hash.query_shape(ws)
	mut new_overlapping := map[int]bool{}

	for id in candidates {
		mut other := a.app.bodies[id] or { continue }
		if a.collision_mask & other.collision_layer == 0 {
			continue
		}
		m := physics.manifold_between(ws, other.world_shape())
		if m.count == 0 {
			continue
		}
		new_overlapping[id] = true
		if id !in a.overlapping {
			if cb := a.on_body_entered {
				cb(other)
			}
			a.signals.emit(sig_area_body_entered, a, [SignalArg(id)], a.app.wren_vm, a.app.wren_signal_call_handles)
		}
	}

	for id, _ in a.overlapping {
		if id !in new_overlapping {
			other := a.app.bodies[id] or { continue }
			if cb := a.on_body_exited {
				cb(other)
			}
			a.signals.emit(sig_area_body_exited, a, [SignalArg(id)], a.app.wren_vm, a.app.wren_signal_call_handles)
		}
	}

	a.overlapping = new_overlapping.clone()
}
