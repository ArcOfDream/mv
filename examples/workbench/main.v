module main

import raylib as rl
import mv
import mv.rres

const test_pxtone = $embed_file('assets/test.ptcop')

@[heap]
struct Game {
mut:
	app ?&mv.App

	root ?&mv.Node
	cam  ?&mv.CameraNode
}

fn (mut g Game) setup() {
	g.app = mv.App.new(g.init, g.update, g.draw, none, none)

	if mut app := g.app {
		app.run()
	}
}

fn (mut g Game) init() {
	loader := rres.new_rres_loader('assets/assets.rres')

	if mut app := g.app {
		app.set_window_title('Hello, raymv!')
		app.set_window_size(640, 480)
		app.set_viewport_size(320, 240)
		app.set_target_fps(60)
		app.set_clear_color(rl.darkblue)

		if l := loader {
			app.textures.load_from_rres(l, 'bnuy', 'bnuy.png')
			l.unload()
		}

		g.root = app.new_node[mv.Node]('root', 0, 0)

		if mut r := g.root {
			mut test := r.create_and_add_child[mv.TestNode]('child')
			test.set_scale(mv.Vec2{0.4, 0.4})

			mut c := r.create_and_add_child[mv.CameraNode]('camera')
			g.cam = c

			c.register()
			//c.set_pos(mv.Vec2{0, 0})
			
			mut player := r.create_and_add_child[mv.MusicPlayer]('player')
			player.play_pxtone(test_pxtone.to_bytes()) or { eprintln(err) }
			//player.seek(30)

			mv.emit_notification(mut r, .ready, app.get_state())
		}
	}
}

fn (mut g Game) update(_dt f32) {
	if mut app := g.app {
		if mut root := g.root {
			mv.emit_notification(mut root, .update, app.get_state())
		}
	}
}

fn (mut g Game) draw() {
	if mut app := g.app {
		if mut root := g.root {
			mv.emit_notification(mut root, .draw, app.get_state())
		}

		rl.draw_fps(2, 2)
	}
}

fn main() {
	mut game := Game{}
	game.setup()
}
