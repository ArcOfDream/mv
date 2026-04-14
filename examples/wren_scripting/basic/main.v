module main

import mv
import raylib as rl

@[heap]
struct Game {
mut:
	app ?&mv.App
}

fn (mut g Game) setup() {
	g.app = mv.App.new(g.init, none, none, none, none)

	if mut app := g.app {
		app.wren = mv.WrenSetup{
			entry: 'main.wren'
		}
		app.run()
	}
}

fn (mut g Game) init() {
	if mut app := g.app {
		app.set_window_title('mv: wren rotating rect')
		app.set_window_size(640, 480)
		app.set_viewport_size(320, 240)
		app.set_target_fps(60)
		app.set_clear_color(rl.darkblue)
	}
}

fn main() {
	mut game := Game{}
	game.setup()
}
