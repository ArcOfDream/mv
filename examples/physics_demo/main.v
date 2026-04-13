module main

import mv
import raylib as rl
import mv.physics

struct Ball {
	mv.PhysicsBody
mut:
	velocity    mv.Vec2
	radius      f32 = 10.0
	restitution f32 = 0.3 // bounciness
	gravity     f32 = 1000.0
}

fn (mut b Ball) update(dt f32) {
	// apply gravity to velocity
	b.velocity.y += b.gravity * dt

	// move_and_collide returns hits from the physics world
	hits := b.move_and_collide(b.velocity * mv.Vec2.f32(dt))

	if hits.len > 0 {
		hit := hits[0]

		// snap to surface
		b.set_global_pos(b.get_global_pos() + hit.normal * mv.Vec2.f32(hit.depth))

		// bounce logic
		dot := b.velocity.dot(hit.normal)
		normal_component := hit.normal * mv.Vec2.f32(dot)
		b.velocity = b.velocity - normal_component * mv.Vec2.f32(1.0 + b.restitution)
	} else {
		// no collision
		b.set_global_pos(b.get_global_pos() + b.velocity * mv.Vec2.f32(dt))
	}
}

fn (mut b Ball) draw() {
	rl.draw_circle(0, 0, b.radius, rl.maroon)
}

struct Floor {
	mv.PhysicsBody
mut:
	size mv.Vec2
}

fn (mut f Floor) draw() {
	rl.draw_rectangle(0, 0, int(f.size.x), int(f.size.y), rl.darkgray)
}

@[heap]
struct Game {
mut:
	app   &mv.App = unsafe { nil }
	balls  []&Ball
	floor &Floor  = unsafe { nil }
}

fn (mut g Game) setup() {
	g.app = mv.App.new(g.init, g.update, g.draw, none, none)

	g.app.set_window_title('mv: physics demo')
	g.app.set_window_size(800, 600)
	g.app.set_viewport_size(800, 600)
	g.app.set_clear_color(rl.blue)

	g.app.run()
}

fn (mut g Game) init() {
	for i in 0..50 {
		mut ball := g.app.new_node[Ball]('Ball_${i}', 50+10*i, 100)
		ball.body_type = .kinematic
		ball.shape = physics.Circle{
			r: 10.0
		}
		ball.velocity = mv.Vec2{10, 0}
		mv.emit_notification(mut ball, .ready)

		g.balls << ball
	}


	mut floor := g.app.new_node[Floor]('Floor', 100, 500)
	g.floor = floor
	floor.body_type = .static_body
	floor.size = mv.Vec2{600, 40}
	floor.shape = physics.AABB{
		min: physics.Vec{0, 0}
		max: physics.Vec{600, 40}
	}
	mv.emit_notification(mut floor, .ready)
}

fn (mut g Game) update(dt f32) {
	for mut b in g.balls {
		mv.emit_notification(mut b, .update)
	}
	mv.emit_notification(mut g.floor, .update)
}

fn (mut g Game) draw() {
	for mut b in g.balls {
		mv.emit_notification(mut b, .draw)
	}
	mv.emit_notification(mut g.floor, .draw)

	rl.draw_text('bouncing ball sample', 2, 2, 4, rl.raywhite)
}

fn main() {
	mut game := &Game{}
	game.setup()
}
