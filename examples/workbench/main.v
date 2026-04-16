module main

import raylib as rl { Color }
import mv
import mv.core { Vec2 }
import mv.rres
import mv.ldtk as _

// this is less of an example and more of a testbed for me to test some features
// as i work on them.
// this may vanish when the project reaches a certain degree of maturity!

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
	loader := rres.RresLoader.new('assets/assets.rres')

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
			mut child := TestNode.new(app, 'child')
			child.set_scale(Vec2{0.4, 0.4})
			r.add_child(mut child)

			mut c := mv.CameraNode.new(app, 'camera')
			r.add_child(mut c)
			g.cam = c
			c.register()

			mut player := mv.MusicPlayer.new(app, 'player')
			r.add_child(mut player)
			player.play_pxtone(test_pxtone.to_bytes()) or { eprintln(err) }
			player.loop(true)

			mut sphere_grad := core.Gradient.from_colors([
				Color{255, 255, 240, 255}, // near-white highlight
				Color{60, 80, 160, 255}, // mid blue
				Color{10, 15, 40, 255}, // dark edge
			])
			sphere_grad.interpolation = .monotone_cubic
			mut rainbow_grad := core.Gradient.from_colors([
				rl.red,
				rl.orange,
				rl.yellow,
				rl.green,
				rl.skyblue,
				rl.darkblue,
				rl.purple,
				rl.violet,
			])
			rainbow_grad.interpolation = .constant

			sphere_tex := core.Gradient2D{
				gradient: sphere_grad
				fill:     .radial_focal
				center:   Vec2{0.5, 0.5} // outer circle sits in the middle
				radius:   0.5
				focal:    Vec2{0.35, 0.3} // highlight pushed upper-left
				width:    64
				height:   64
			}.bake()
			app.textures.add_texture('sphere', sphere_tex)

			mut sprite := mv.Sprite.new(app, 'gradient', 'sphere')
			r.add_child(mut sprite)
			sprite.set_centered(false)
			sprite.set_pos(Vec2{0, 0})

			mut img_xor := core.gen_image_xor(64, 64, rainbow_grad)
			app.textures.load_from_image('xor', img_xor)
			mut sprite2 := mv.Sprite.new(app, 'xor', 'xor')
			r.add_child(mut sprite2)
			sprite2.set_centered(false)
			sprite2.set_pos(Vec2{64, 0})

			mv.emit_notification(mut r, .ready)
		}
	}
}

fn (mut g Game) update(_dt f32) {
	if mut root := g.root {
		mv.emit_notification(mut root, .update)
	}
}

fn (mut g Game) draw() {
	if mut root := g.root {
		mv.emit_notification(mut root, .draw)
	}

	rl.draw_fps(2, 2)
}

fn main() {
	mut game := Game{}
	game.setup()
}
