module main

import mv.core
import mv.graphics as g
import mv.util
import mv.math
import rand
import sdl

[heap]
struct Game {
mut:
	ctx &core.Context = sdl.null
pub mut:
	sprites [200]&g.Sprite
	qoi     ?&g.Sprite
}

fn main() {
	mut game := Game{
		ctx: &core.Context{}
	}
	game.setup()
	game.run()
}

fn (mut game Game) setup() {
	game.ctx = &core.Context{
		window_width: 640
		window_height: 480
		title: 'Microvidya'
		init_func: game.init
		update_func: game.update
		draw_func: game.draw
		event_func: game.event
	}
	game.ctx.init()
}

fn (mut game Game) init() {
	default_tex := util.load_default_texture()
	silly_tex := util.load_texture_file('res/feelsillyman.png', 'spr_silly', false) or {
		util.load_default_texture()
	}
	third_tex := util.load_texture_file('res/spr_amogus.png', 'spr_amogus', false) or {
		util.load_default_texture()
	}
	qoi_tex := util.load_texture_qoi('res/dice.qoi', 'spr_qoi', false) or {
		util.load_default_texture()
	}
	game.ctx.data['spr_default'] = default_tex
	game.ctx.data['spr_silly'] = silly_tex
	game.ctx.data['spr_third'] = third_tex
	game.ctx.data['spr_qoi'] = qoi_tex

	refs := [&default_tex, &silly_tex, &third_tex]
	for mut s in game.sprites {
		num := rand.int_in_range(0, refs.len) or { 0 }
		s = g.Sprite.new(
			renderer: game.ctx.renderer
			texture: refs[num]
			position: math.Vec2{rand.f32_in_range(0, 800) or { 0 }, rand.f32_in_range(0,
				600) or { 0 }}
			angle: rand.f32_in_range(0, math.pi) or { 0 }
		)
	}
	game.qoi = g.Sprite.new(
		renderer: game.ctx.renderer
		texture: &qoi_tex
	)
}

fn (mut game Game) run() {
	game.ctx.run()
}

fn (mut game Game) event(mut ev sdl.Event) {
}

fn (mut game Game) update(delta f32) {
}

fn (mut game Game) draw() {
	for mut s in game.sprites {
		s.draw_self()
	}
	if mut qoi := game.qoi {
		qoi.angle -= 0.01
		qoi.draw_self()
	}
}
