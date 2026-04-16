module main

import mv
import mv.core { Vec2 }
import raylib as rl
import mv.physics

struct Ball {
	mv.PhysicsBody
mut:
	velocity    Vec2
	radius      f32 = 10.0
	restitution f32 = 0.8 // bounciness
	gravity     f32 = 1000.0
}

fn Ball.new(app &mv.App, name string, pos Vec2) &Ball {
	return &Ball{
		app: app
		node_name: name
		pos : pos
	}
}

fn (mut b Ball) update(dt f32) {
	b.velocity.y += b.gravity * dt

	// move_and_collide returns hits from the physics world
	delta := b.velocity * Vec2.f32(dt)
	hits := b.move_and_collide(delta)

	if hits.len > 0 {
		hit := hits[0]

		// advance to proposed position, then resolve overlap
		b.set_pos(b.get_pos() + delta + hit.normal * Vec2.f32(hit.depth))

		// bounce logic
		dot := b.velocity.dot(hit.normal)
		normal_component := hit.normal * Vec2.f32(dot)
		b.velocity = b.velocity - normal_component * Vec2.f32(1.0 + b.restitution)
	} else {
		b.set_pos(b.get_pos() + delta)
	}
}

fn (mut b Ball) draw() {
	rl.draw_circle(0, 0, b.radius, rl.maroon)
}

struct Floor {
	mv.PhysicsBody
mut:
	size Vec2
}

fn Floor.new(app &mv.App, name string, pos Vec2) &Floor {
	return &Floor{
		app: app
		node_name: name
		pos : pos
	}
}

fn (mut f Floor) draw() {
	rl.draw_rectangle(0, 0, int(f.size.x), int(f.size.y), rl.darkgray)
}

@[heap]
struct Game {
mut:
	app   &mv.App = unsafe { nil }
	balls []&Ball
	floor &Floor = unsafe { nil }
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
	for i in 0 .. 1 {
		mut ball := Ball.new(g.app, 'Ball_${i}', Vec2{200 + 10 * i, 100})
		ball.body_type = .kinematic
		ball.shape = physics.Circle{
			r: 10.0
		}
		ball.velocity = Vec2{10, 0}
		mv.emit_notification(mut ball, .ready)

		g.balls << ball
	}

	mut floor := Floor.new(g.app, 'Floor', Vec2{100, 500})
	g.floor = floor
	floor.body_type = .static_body
	floor.size = Vec2{600, 40}
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
