module main

import raylib as rl
import math
import mv.engine { App, Line, Node, Sprite }
import mv.core { Gradient, Vec2 }

const viewport_w = f32(320)
const viewport_h = f32(240)
const trail_max = int(150)
const trail_speed = f32(2.0)
const trail_width = f32(24.0)

@[heap]
struct Game {
mut:
	app    ?&App
	sprite ?&Sprite
	trail  ?&Line
	t      f32
}

fn (mut g Game) setup() {
	g.app = App.new(g.init, g.update, g.draw, none, none)
	if mut app := g.app {
		app.run()
	}
}

fn (mut g Game) init() {
	mut app := g.app or { return }

	app.set_window_title('mv: line trail demo')
	app.set_window_size(640, 480)
	app.set_viewport_size(int(viewport_w), int(viewport_h))
	app.set_target_fps(60)
	app.set_clear_color(rl.Color{15, 15, 25, 255})

	// load the bunny texture
	app.textures.load('bnuy', 'bnuy.png')

	// build a rainbow gradient and bake it to a 256px wide 1D texture
	mut rainbow := Gradient.from_colors([
		rl.Color{255, 0, 0, 255}, // red
		rl.Color{255, 140, 0, 255}, // orange
		rl.Color{255, 220, 0, 255}, // yellow
		rl.Color{0, 210, 0, 255}, // green
		rl.Color{0, 200, 255, 255}, // cyan
		rl.Color{0, 60, 255, 255}, // blue
		rl.Color{160, 0, 255, 255}, // violet
	])
	rainbow.interpolation = .linear
	tex := rainbow.bake(256)
	app.textures.add_texture('rainbow', tex)

	// clamp wrap so stretched UVs don't bleed at the trail endpoints
	if rh := app.textures.get_handle('rainbow') {
		if mut res := rh.get() {
			res.set_wrap_mode(.texture_wrap_clamp)
		}
	}

	// --- scene ---

	mut root := Node.new(app, 'root')

	// line trail following the sprite
	mut trail := Line.new(app, 'trail')
	trail.width = trail_width
	trail.joint_mode = .miter
	trail.cap_mode = .round
	trail.texture_mode = .stretch
	trail.set_texture_id('rainbow') or { eprintln(err) }
	root.add_child(mut trail)
	g.trail = trail

	// sprite that traces a figure-8 across the viewport
	mut spr := Sprite.new(app, 'bnuy', 'bnuy')
	spr.set_scale(Vec2{0.4, 0.4})
	root.add_child(mut spr)
	g.sprite = spr

	// stationary arc to verify Line rendering independently of trail logic.
	// if this also appears as dots, the issue is in core Line draw path.
	mut arc := Line.new(app, 'arc')
	arc.width = trail_width
	arc.joint_mode = .miter
	arc.cap_mode = .flat
	arc.default_color = rl.Color{255, 80, 80, 255}
	segs := 32
	for i in 0 .. segs + 1 {
		a := math.pi * f32(i) / f32(segs)
		arc.add_point(Vec2{viewport_w * 0.1 + math.cosf(a) * viewport_w * 0.4, viewport_h * 0.5 - math.sinf(a) * viewport_h * 0.35},
			-1)
	}
	// root.add_child(mut arc)

	app.scene_root = root
}

fn (mut g Game) update(dt f32) {
	g.t += dt * trail_speed

	// Lissajous figure-8
	cx := viewport_w * 0.5
	cy := viewport_h * 0.5
	pos := Vec2{cx + viewport_w * 0.35 * math.sinf(g.t), cy +
		viewport_h * 0.30 * math.sinf(g.t * 2.0)}

	if mut spr := g.sprite {
		spr.set_pos(pos)
	}
	if mut trail := g.trail {
		trail.push_trail_point(pos, trail_max)
	}
}

fn (g &Game) draw() {}

fn main() {
	mut game := Game{}
	game.setup()
}
