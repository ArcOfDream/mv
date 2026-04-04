module mv

import raylib as rl
import animation as anim { Keyframe }
import tween { lerp_f32, lerp_vec2 }

struct Bnuy {
pub mut:
	pos   Vec2
	angle f32
}

pub struct TestNode {
	Sprite
mut:
	timer       f32
	anim_player anim.AnimationPlayer
pub mut:
	color rl.Color = rl.red
}

pub fn (mut n TestNode) ready() {
	mut a := anim.Animation{
		duration:  2.0
		loop_mode: .loop
	}

	// vfmt off
	a.add_track_cb(
		fn [mut n] (v Vec2) { n.set_pos(v) }, [
		Keyframe{ time: 0.0, value: Vec2{100, 100}, ease: .in_out_quad },
		Keyframe{ time: 0.5, value: Vec2{200, 100}, ease: .linear },
		Keyframe{ time: 1.0, value: Vec2{200, 200}, ease: .out_bounce },
		Keyframe{ time: 1.5, value: Vec2{100, 200}, ease: .out_expo },
		Keyframe{ time: 2.0, value: Vec2{100, 100}, ease: .in_out_quad }
		], lerp_vec2
	)

	a.add_track_cb(
		fn [mut n] (f f32) { n.set_angle_deg(f) }, [
		Keyframe{ time: 0.0, value: f32(0  ), ease: .linear },
		Keyframe{ time: 2.0, value: f32(360), ease: .in_out_back }
		], lerp_f32
	)
	// vfmt on

	n.anim_player.add('loop', a)
	n.anim_player.play('loop')
}

pub fn (mut n TestNode) update(dt f32) {
	n.anim_player.update(dt)
}

pub fn (n &TestNode) draw() {}
