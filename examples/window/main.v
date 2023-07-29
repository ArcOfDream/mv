module main

import mv.core
import sdl

[heap]
struct Game {
mut:
	ctx &core.Context = sdl.null
}

fn main() {
	mut game := Game{
		ctx: &core.Context{}
	}
	game.setup()
}

fn (mut game Game) setup() {
	game.ctx = &core.Context{
		window_width: 300
		window_height: 300
		title: 'Microvidya'
		init_func: game.init
		update_func: game.update
		draw_func: game.draw
		event_func: game.event
	}
	game.ctx.init()
}

fn (mut game Game) init() {
	game.ctx.run()
}

fn (mut game Game) event(mut ev sdl.Event) {
}

fn (mut game Game) update(delta f32) {
}

fn (mut game Game) draw() {
}
