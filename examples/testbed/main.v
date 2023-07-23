module main

import mv.core
import mv.graphics as g
import mv.util
import mv.math
import mv.binary
// import mv.thirdparty.microui
// import mv.thirdparty.vpxtone
import rand
import sdl
import os

[heap]
struct Game {
mut:
	app &core.App = sdl.null
pub mut:
	sprites [200]&g.Sprite
	qoi     ?&g.Sprite
	camera  g.Camera2D = g.Camera2D{
		size: math.Vec2{640, 480}
		center_camera: false
	}
	fons &FontRender

	x       f32
	y       f32
	bluramt f32
	time    f32
}

fn main() {
	mut game := Game{
		app: &core.App{}
		fons: &FontRender{
			width: 512
			height: 512
		}
	}
	game.setup()
	game.run()
}

fn (mut game Game) setup() {
	game.app = &core.App{
		window_width: 640
		window_height: 480
		title: 'Microvidya'
		init_func: game.init
		update_func: game.update
		draw_func: game.draw
		event_func: game.event
	}
	game.app.init()
}

fn (mut game Game) init() {
	game.app.renderer.active_camera = &game.camera

	game.fons.renderer = game.app.renderer
	game.fons.setup_context()

	if fons := game.fons.ctx {
		mut font := []u8{len: binary.proggytiny_ttf_len}
		for n in 0 .. binary.proggytiny_ttf_len {
			font[n] = binary.proggytiny_ttf[n]
		}

		file := os.read_file_array[u8]('res/plex.ttf')

		mut result := fons.add_font_mem('proggy', font, true)
		if result != -1 {
			println('font loaded ok')
			game.fons.fonts['proggy'] = result
		}

		result = fons.add_font_mem('plex', file, true)
		if result != -1 {
			println('font loaded ok')
			game.fons.fonts['plex'] = result
		}
	}

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
	game.app.data['spr_default'] = default_tex
	game.app.data['spr_silly'] = silly_tex
	game.app.data['spr_third'] = third_tex
	game.app.data['spr_qoi'] = qoi_tex

	refs := [&default_tex, &silly_tex, &third_tex]
	for mut s in game.sprites {
		num := rand.int_in_range(0, refs.len) or { 0 }
		s = &g.Sprite{
			renderer: game.app.renderer
			shader: game.app.get_shader('default_shader')
			texture: refs[num]
			position: math.Vec2{rand.f32_in_range(0, 800) or { 0 }, rand.f32_in_range(0,
				600) or { 0 }}
			angle: rand.f32_in_range(0, math.pi) or { 0 }
		}
		s.update_vertex()
	}
	// game.qoi = &g.Sprite{
	// 	renderer: game.app.renderer
	// 	shader: game.app.get_shader('default_shader')
	// 	texture: &qoi_tex
	// 	// pos: math.Vec2{300, 300}
	// 	// scale: math.Vec2{0.25, 0.5}
	// }
	// if mut qoi := game.qoi {
	// 	qoi.update_vertex()
	// }
}

fn (mut game Game) run() {
	game.app.run()
}

fn (mut game Game) event(mut ev sdl.Event) {
	if ev.@type == .keydown {
		match ev.key.keysym.scancode {
			.scancode_a { game.camera.position.x -= 10 }
			.scancode_d { game.camera.position.x += 10 }
			.scancode_w { game.camera.position.y -= 10 }
			.scancode_s { game.camera.position.y += 10 }
			.scancode_q { game.camera.rotation -= 0.2 }
			.scancode_e { game.camera.rotation += 0.2 }
			.scancode_z { game.camera.scale -= math.Vec2{0.1, 0.1} }
			.scancode_x { game.camera.scale += math.Vec2{0.1, 0.1} }
			else {}
		}
	}
}

fn (mut game Game) update(delta f32) {
	// println("delta time: ${delta}")
	// println('${game.camera}')
	game.time++

	game.x = 40 * (math.pi + math.sin(game.time * 0.01))
	game.y = 40 * (math.pi + math.cos(game.time * 0.01))
	game.bluramt = 10 + (10 * (math.pi + math.cos(game.time * 0.1)))
}

fn (mut game Game) draw() {
	// for mut s in game.sprites {
	// 	s.draw_self()
	// }
	// if mut qoi := game.qoi {
	// 	qoi.angle -= 0.07
	// 	qoi.draw_self()
	// }
	game.draw_some_text()
}

fn (mut game Game) draw_some_text() {
	if fons := game.fons.ctx {
		fons.set_font(game.fons.fonts['proggy'])
		fons.set_size(20)
		fons.set_spacing(3)
		fons.set_color(math.Color.blanched_almond().value)
		fons.draw_text(game.x, game.y, 'asdfghjklQWERTYUIOP')

		fons.draw_debug(256, 256)
	}
}
