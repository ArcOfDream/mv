module main

import raylib as rl
import mv

// a minimal example for setting up a window

@[heap]
struct Game {
mut:
	app ?&mv.App
}

fn (mut g Game) setup() {
	g.app = mv.App.new(g.init, g.update, g.draw, none, none)

	if mut app := g.app {
		app.run()
	}
}

fn (mut g Game) init() {
	if mut app := g.app {
		app.set_window_title('Hello, mv!')
		app.set_window_size(640, 480)
		app.set_viewport_size(320, 240)
		app.set_target_fps(60)
		app.set_clear_color(rl.darkblue)
	}
}

fn (g &Game) update(dt f32) {}

fn (mut g Game) draw() {
	rl.draw_text('basic window', 2, 2, 4, rl.raywhite)
}

fn main() {
	mut game := Game{}
	game.setup()
}
