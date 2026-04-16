module mv

import core { Vec2 }
import physics
import math

pub enum BodyType {
	static_body // immovable: registers for others to collide against
	kinematic   // moved manually; collisions reported but not auto-resolved
}

pub struct CollisionResult {
pub:
	manifold physics.Manifold
	normal   Vec2
	depth    f32
	ti       f32 = f32(1.0)    // time of impact 0..1; 0 = overlap, 1 = manifold default
	other    &PhysicsBody
}

@[heap]
pub struct PhysicsBody {
	Node
pub mut:
	body_type        BodyType      = .kinematic
	shape            physics.Shape = physics.AABB{}
	shape_offset     Vec2
	collision_layer  u32 = 1 // which layers this body occupies
	collision_mask   u32 = 1 // which layers this body scans against
	slide_collisions []CollisionResult

	// used by is_on_floor / is_on_wall / is_on_ceiling
	up_direction    Vec2 = Vec2{0, -1}
	floor_max_angle f32  = math.pi / 4.0 // 45 degrees
}

pub fn PhysicsBody.new(app &App, name string, body_type BodyType, shape physics.Shape) &PhysicsBody {
	return &PhysicsBody{
		app: app
		node_name: name
		body_type: body_type
		shape: shape
	}
}

fn (n &PhysicsBody) wren_class_name() string {
	return 'PhysicsBody'
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

// tree callbacks

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

fn (mut b PhysicsBody) update_internal(_dt f32) {
	if b.body_type == .static_body {
		return
	}
	id := int(voidptr(b))
	b.app.physics_world.hash.register_shape(id, b.world_shape())
}

// shape helpers

// world_shape returns the shape translated into world space using the node's
// current global position.
// polygon shapes use the node's XTransform instead.
pub fn (mut b PhysicsBody) world_shape() physics.Shape {
	mut wp := b.get_global_pos() + b.shape_offset
	return match mut b.shape {
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
		else {
			b.shape
		}
	}
}

// translated_shape returns the world shape offset by delta.
// for non-polygon shapes this moves the vertices directly.
// for polygons the vertices stay in local space -- use translated_xtransform
// to get the corresponding shifted transform.
@[inline]
fn (mut b PhysicsBody) translated_shape(delta Vec2) physics.Shape {
	mut ws := b.world_shape()
	return match mut ws {
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

pub fn (b &PhysicsBody) xtransform() physics.XTransform {
	wp := b.transform.translation + b.shape_offset
	return physics.XTransform.from(physics.Vec{wp.x, wp.y}, b.transform.rotation)
}

@[inline]
pub fn (b &PhysicsBody) shape_xtransform() physics.XTransform {
	return match b.shape {
		physics.Polygon { b.xtransform() }
		else { physics.xtransform_identity }
	}
}

// translated_xtransform returns the XTransform at the proposed position
// (current position + delta). For non-polygon shapes this returns identity
// since translated_shape already moved their vertices.
// for polygons this carries the delta that translated_shape cannot apply to
// local-space vertices
@[inline]
fn (b &PhysicsBody) translated_xtransform(delta Vec2) physics.XTransform {
	return match b.shape {
		physics.Polygon {
			wp := b.transform.translation + b.shape_offset + delta
			physics.XTransform.from(physics.Vec{wp.x, wp.y}, b.transform.rotation)
		}
		else {
			physics.xtransform_identity
		}
	}
}

// movement

// move_and_collide checks for collisions along a proposed velocity and returns
// all hits.
// it does NOT move the node -- the caller is responsible for applying position
// changes based on the results.
pub fn (mut b PhysicsBody) move_and_collide(velocity Vec2) []CollisionResult {
    self_id    := int(voidptr(b))
    cur_shape  := b.world_shape()
    proposed   := b.translated_shape(velocity)
    proposed_xf := b.translated_xtransform(velocity)

    // broad phase: query at endpoint (conservative; catches all candidates)
    candidates := b.app.physics_world.hash.query_shape(proposed)
    mut results := []CollisionResult{}

    for id in candidates {
        if id == self_id { continue }
        mut other := b.app.bodies[id] or { continue }
        if !b.can_collide_with(other) { continue }

        other_shape := other.world_shape()

        // AABB vs AABB: Liang-Barsky sweep for accurate time-of-impact
        if cur_shape is physics.AABB && other_shape is physics.AABB {
            sr := physics.sweep_aabb(cur_shape, other_shape, velocity.x, velocity.y)
            if !sr.hit { continue }
            results << CollisionResult{
                normal: Vec2{sr.normal_x, sr.normal_y}
                ti:     sr.ti
                other:  other
            }
            continue
        }

        // All other pairs: cute_c2 manifold (overlap test at endpoint)
        mf := physics.manifold_between_xf(proposed, proposed_xf, other_shape, other.shape_xtransform())
        if mf.count == 0 { continue }
        results << CollisionResult{
            manifold: mf
            normal:   Vec2{-mf.n.x, -mf.n.y}
            depth:    mf.depths[0]
            ti:       f32(1.0)  // manifold = already at overlap depth
            other:    other
        }
    }

    return results
}

// move_and_slide iteratively moves the body, sliding along surfaces on collision.
// returns the remaining velocity after all slides are resolved.
// collisions encountered are stored in slide_collisions.
pub fn (mut b PhysicsBody) move_and_slide(velocity Vec2, max_slides int) Vec2 {
    b.slide_collisions.clear()
    mut remaining := velocity
    mut pos := b.transform.translation

    for _ in 0 .. max_slides {
        if remaining.length() < 0.001 {
            break
        }

        hits := b.move_and_collide(remaining)
        if hits.len == 0 {
            pos += remaining
            remaining = Vec2{}
            break
        }

        // pick the earliest contact this iteration
        mut earliest := hits[0]
        for hit in hits[1..] {
            if hit.ti < earliest.ti {
                earliest = hit
            }
        }

        b.slide_collisions << earliest

        if earliest.ti == 0 {
            // static overlap: push out by penetration (manifold path or resting contact)
            // use depth for manifold hits; for sweep overlaps the normal is already computed
            push := if earliest.depth > 0 { earliest.depth } else { f32(0.5) }
            pos += earliest.normal * Vec2.f32(push)
        } else {
            // sweep contact: move forward to the touch point
            pos += remaining * Vec2.f32(earliest.ti)
        }

        b.set_global_pos(pos)

        // project the unspent velocity along the surface
        leftover := remaining * Vec2.f32(1.0 - earliest.ti)
        dot := leftover.dot(earliest.normal)
        remaining = leftover - earliest.normal * Vec2.f32(dot)
    }

    b.set_global_pos(pos)
    return remaining
}

// surface queries

// floor_dot_threshold is the minimum dot product between a collision normal
// and up_direction for the surface to be considered a floor.
// derived from floor_max_angle: cos(45deg) = about 0.707.
@[inline]
fn (b &PhysicsBody) floor_dot_threshold() f32 {
	return math.cosf(b.floor_max_angle)
}

// is_on_floor returns true if any slide collision this frame had a normal
// within floor_max_angle of up_direction
pub fn (b &PhysicsBody) is_on_floor() bool {
	t := b.floor_dot_threshold()
	for hit in b.slide_collisions {
		if hit.normal.dot(b.up_direction) > t {
			return true
		}
	}
	return false
}

// is_on_ceiling returns true if any collision normal pointed away from
// up_direction beyond floor_max_angle -- i.e. the body hit a ceiling
pub fn (b &PhysicsBody) is_on_ceiling() bool {
	t := b.floor_dot_threshold()
	for hit in b.slide_collisions {
		if hit.normal.dot(b.up_direction) < -t {
			return true
		}
	}
	return false
}

// is_on_wall returns true if any collision was neither floor nor ceiling
pub fn (b &PhysicsBody) is_on_wall() bool {
	t := b.floor_dot_threshold()
	for hit in b.slide_collisions {
		d := hit.normal.dot(b.up_direction)
		if math.abs(d) <= t {
			return true
		}
	}
	return false
}

// get_floor_normal returns the normal of the first floor collision, if any
pub fn (b &PhysicsBody) get_floor_normal() ?Vec2 {
	t := b.floor_dot_threshold()
	for hit in b.slide_collisions {
		if hit.normal.dot(b.up_direction) > t {
			return hit.normal
		}
	}
	return none
}

// get_wall_normal returns the normal of the first wall collision, if any
pub fn (b &PhysicsBody) get_wall_normal() ?Vec2 {
	t := b.floor_dot_threshold()
	for hit in b.slide_collisions {
		d := hit.normal.dot(b.up_direction)
		if math.abs(d) <= t {
			return hit.normal
		}
	}
	return none
}

// get_ceiling_normal returns the normal of the first ceiling collision, if any
pub fn (b &PhysicsBody) get_ceiling_normal() ?Vec2 {
	t := b.floor_dot_threshold()
	for hit in b.slide_collisions {
		if hit.normal.dot(b.up_direction) < -t {
			return hit.normal
		}
	}
	return none
}
