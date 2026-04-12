module mv

import physics

pub enum BodyType {
	static_body // immovable: registers for others to collide against
	kinematic   // moved manually; collisions reported but not auto-resolved
}

pub struct CollisionResult {
pub:
	manifold physics.Manifold
	normal   Vec2
	depth    f32
	other    &PhysicsBody
}

pub struct PhysicsBody {
	Node
pub mut:
	body_type       BodyType      = .kinematic
	shape           physics.Shape = physics.AABB{}
	shape_offset    Vec2
	collision_layer u32 = 1 // which layers this body occupies
	collision_mask  u32 = 1 // which layers this body scans against
}

// layer funcs

// sets a single layer bit (1-indexed, 1–32)
@[inline]
pub fn (mut b PhysicsBody) set_layer(layer int) {
	b.collision_layer |= 1 << (layer - 1)
}

@[inline]
pub fn (mut b PhysicsBody) clear_layer(layer int) {
	b.collision_layer &= ~(1 << (layer - 1))
}

@[inline]
pub fn (mut b PhysicsBody) set_mask(layer int) {
	b.collision_mask |= 1 << (layer - 1)
}

@[inline]
pub fn (mut b PhysicsBody) clear_mask(layer int) {
	b.collision_mask &= ~(1 << (layer - 1))
}

// can_collide_with returns true if this body's mask overlaps the other's layer
@[inline]
pub fn (b &PhysicsBody) can_collide_with(other &PhysicsBody) bool {
	return b.collision_mask & other.collision_layer != 0
}

fn (mut b PhysicsBody) ready_internal() {
	id := int(voidptr(b))
	b.app.bodies[id] = b
	if b.body_type == .static_body {
		b.app.physics_world.hash.register_static_shape(id, b.world_shape())
	}
}

fn (mut b PhysicsBody) exit_tree_internal() {
	id := int(voidptr(b))
	b.app.bodies.delete(id)
	if b.body_type == .static_body {
		b.app.physics_world.hash.unregister_static(id)
	}
}

// world_shape returns the shape translated into world space using the node's
// current global position.
// polygon shapes use the node's XTransform instead.
pub fn (b &PhysicsBody) world_shape() physics.Shape {
	wp := b.transform.translation + b.shape_offset
	return match b.shape {
		physics.Circle {
			physics.Circle{
				p: physics.Vec{b.shape.p.x + wp.x, b.shape.p.y + wp.y}
				r: b.shape.r
			}
		}
		physics.AABB {
			physics.AABB{
				min: physics.Vec{b.shape.min.x + wp.x, b.shape.min.y + wp.y}
				max: physics.Vec{b.shape.max.x + wp.x, b.shape.max.y + wp.y}
			}
		}
		physics.Capsule {
			physics.Capsule{
				a: physics.Vec{b.shape.a.x + wp.x, b.shape.a.y + wp.y}
				b: physics.Vec{b.shape.b.x + wp.x, b.shape.b.y + wp.y}
				r: b.shape.r
			}
		}
		// polygon rotation is handled via XTransform through cute_c2
		else {
			b.shape
		}
	}
}

fn (mut b PhysicsBody) update_internal(_dt f32) {
	// static bodies register once in ready_internal -- skip re-registration
	if b.body_type == .static_body {
		return
	}
	id := int(voidptr(b))
	ws := b.world_shape()
	b.app.physics_world.hash.register_shape(id, ws)
}

// move_and_collide checks for collisions along a proposed velocity and returns
// all hits.
// it does NOT move the node -- the caller is responsible for applying position
// changes based on the results.
pub fn (b &PhysicsBody) move_and_collide(velocity Vec2) []CollisionResult {
	self_id := int(voidptr(b))
	proposed := b.translated_shape(velocity)
	candidates := b.app.physics_world.hash.query_shape(proposed)

	mut results := []CollisionResult{}

	for id in candidates {
		if id == self_id {
			continue
		}
		other := b.app.bodies[id] or { continue }
		if !b.can_collide_with(other) {
			continue
		}
		m := physics.manifold_between(proposed, other.world_shape())
		if m.count == 0 {
			continue
		}
		results << CollisionResult{
			manifold: m
			normal:   Vec2{m.n.x, m.n.y}
			depth:    m.depths[0]
			other:    other
		}
	}

	return results
}

// translated_shape returns the world shape offset by an additional delta,
// used internally by move_and_collide to test a proposed movement.
@[inline]
fn (b &PhysicsBody) translated_shape(delta Vec2) physics.Shape {
	ws := b.world_shape()
	return match ws {
		physics.Circle {
			physics.Circle{
				p: physics.Vec{ws.p.x + delta.x, ws.p.y + delta.y}
				r: ws.r
			}
		}
		physics.AABB {
			physics.AABB{
				min: physics.Vec{ws.min.x + delta.x, ws.min.y + delta.y}
				max: physics.Vec{ws.max.x + delta.x, ws.max.y + delta.y}
			}
		}
		physics.Capsule {
			physics.Capsule{
				a: physics.Vec{ws.a.x + delta.x, ws.a.y + delta.y}
				b: physics.Vec{ws.b.x + delta.x, ws.b.y + delta.y}
				r: ws.r
			}
		}
		else {
			ws
		}
	}
}
