module main

import mv.core
import mv.graphics as g
import mv.math
import mv.binary
import sdl

[heap]
struct Game {
mut:
	ctx &core.Context = sdl.null
pub mut:
	camera  g.Camera2D = g.Camera2D{
		size: math.Vec2{640, 480}
		// center_camera: false
	}
	fons &FontRender

	x       f32
	y       f32
	time    f32
}

fn main() {
	mut game := Game{
		ctx: &core.Context{}
		fons: &FontRender{
			width: 512
			height: 512
		}
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
	game.ctx.renderer.active_camera = &game.camera

	game.fons.renderer = game.ctx.renderer
	game.fons.setup_context()

	if fons := game.fons.ctx {
		mut font := []u8{len: binary.proggytiny_ttf_len}
		for n in 0 .. binary.proggytiny_ttf_len {
			font[n] = binary.proggytiny_ttf[n]
		}

		mut result := fons.add_font_mem('proggy', font, true)
		if result != -1 {
			println('font loaded ok')
			game.fons.fonts['proggy'] = result
		}
	}
}

fn (mut game Game) run() {
	game.ctx.run()
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

	game.x = 40 * math.sin(game.time * 0.01)
	game.y = 40 * math.cos(game.time * 0.01)
}

fn (mut game Game) draw() {
	game.fons.set_font('proggy')
	game.fons.set_size(20)
	game.fons.set_color(math.Vec4{1,1,1,1})
	game.fons.set_alignment(.center|.baseline)
	game.fons.draw_string(game.x, -60 + game.y, 'the quick brown fox jumps over the lazy dog')
	game.fons.set_size(40)
	game.fons.set_color(math.Vec4{1,0,1,1})
	game.fons.draw_string(-game.x, 50 - game.y, '${game.ctx.fps}')
}
