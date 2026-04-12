module main

import raylib as rl
import mv { Vec2 }

// Image generation workbench: 4×3 grid of 64×64 generated textures
//
//  [0] fill          [1] checker       [2] grid          [3] linear H
//  [4] linear V      [5] linear diag   [6] radial         [7] radial focal
//  [8] conic         [9] xor rainbow  [10] xor two-tone  [11] sdf glow

const img_size = 64
const cols = 4

@[heap]
struct Game {
mut:
	app  ?&mv.App
	root ?&mv.Node
}

fn (mut g Game) setup() {
	g.app = mv.App.new(g.init, g.update, g.draw, none, none)
	if mut app := g.app {
		app.run()
	}
}

fn (mut g Game) init() {
	if mut app := g.app {
		app.set_window_title('mv: image generation workbench')
		app.set_window_size(512, 384)
		app.set_viewport_size(256, 192)
		app.set_target_fps(60)
		app.set_clear_color(rl.Color{20, 20, 20, 255})

		mut r := mv.Node.new(app, 'root')
		g.root = r

		// gradients

		mut sunset := mv.Gradient.from_colors([
			rl.Color{10, 10, 40, 255},
			rl.Color{120, 60, 180, 255},
			rl.Color{240, 100, 40, 255},
			rl.Color{250, 220, 80, 255},
		])
		sunset.interpolation = .monotone_cubic

		mut sky := mv.Gradient.from_colors([
			rl.Color{10, 30, 80, 255},
			rl.Color{80, 160, 220, 255},
			rl.Color{200, 230, 255, 255},
		])
		sky.interpolation = .monotone_cubic

		mut rainbow := mv.Gradient.from_colors([
			rl.red,
			rl.orange,
			rl.yellow,
			rl.green,
			rl.skyblue,
			rl.darkblue,
			rl.violet,
		])

		mut sphere_grad := mv.Gradient.from_colors([
			rl.Color{255, 255, 240, 255},
			rl.Color{60, 80, 160, 255},
			rl.Color{10, 15, 40, 255},
		])
		sphere_grad.interpolation = .cubic

		mut vignette := mv.Gradient.from_colors([
			rl.Color{255, 255, 255, 255},
			rl.Color{0, 0, 0, 255},
		])

		mut glow := mv.Gradient.from_colors([
			rl.Color{255, 220, 80, 255},
			rl.Color{255, 120, 20, 180},
			rl.Color{200, 40, 10, 0},
		])
		glow.interpolation = .monotone_cubic

		mut two_tone := mv.Gradient.from_colors([
			rl.Color{20, 20, 60, 255},
			rl.Color{0, 200, 180, 255},
		])

		// generate & register images

		// [0] solid fill
		app.textures.load_from_image('fill', mv.gen_image_fill(img_size, img_size, rl.Color{30, 160, 180, 255}))

		// [1] checkerboard
		app.textures.load_from_image('checker', mv.gen_image_checker(img_size, img_size,
			8, 8, rl.Color{240, 40, 240, 255}, rl.Color{40, 40, 40, 255}))

		// [2] grid
		app.textures.load_from_image('grid', mv.gen_image_grid(img_size, img_size, 4,
			4, 2, rl.Color{30, 30, 30, 255}, rl.Color{100, 200, 120, 255}))

		// [3] linear horizontal: sunset
		app.textures.load_from_image('linear_h', mv.gen_image_gradient_linear(img_size,
			img_size, &sunset, Vec2{0.0, 0.5}, Vec2{1.0, 0.5}))

		// [4] linear vertical: sky
		app.textures.load_from_image('linear_v', mv.gen_image_gradient_linear(img_size,
			img_size, &sky, Vec2{0.5, 0.0}, Vec2{0.5, 1.0}))

		// [5] linear diagonal
		app.textures.load_from_image('linear_diag', mv.gen_image_gradient_linear(img_size,
			img_size, &rainbow, Vec2{0.0, 0.0}, Vec2{1.0, 1.0}))

		// [6] radial vignette
		app.textures.load_from_image('radial', mv.gen_image_gradient_radial(img_size,
			img_size, &vignette, Vec2{0.5, 0.5}, 0.5))

		// [7] radial focal: sphere shading
		app.textures.load_from_image('radial_focal', mv.gen_image_gradient_radial_focal(img_size,
			img_size, &sphere_grad, Vec2{0.5, 0.5}, 0.5, Vec2{0.35, 0.3}))

		// [8] conic: rainbow sweep
		app.textures.load_from_image('conic', mv.gen_image_gradient_conic(img_size, img_size,
			&rainbow, Vec2{0.5, 0.5}, 0.0))

		// [9] xor: rainbow
		app.textures.load_from_image('xor_rainbow', mv.gen_image_xor(img_size, img_size,
			&rainbow))

		// [10] xor: two-tone
		app.textures.load_from_image('xor_two', mv.gen_image_xor(img_size, img_size, &two_tone))

		// [11] sdf circle: soft glow
		app.textures.load_from_image('sdf_glow', mv.gen_image_sdf_circle(img_size, img_size,
			Vec2{0.5, 0.5}, 0.35, 0.15, &glow))

		// lay out sprites in a 4×3 grid

		names := [
			'fill',
			'checker',
			'grid',
			'linear_h',
			'linear_v',
			'linear_diag',
			'radial',
			'radial_focal',
			'conic',
			'xor_rainbow',
			'xor_two',
			'sdf_glow',
		]

		for i, name in names {
			mut sprite := mv.Sprite.new(app, name, name)
			r.add_child(mut sprite)
			sprite.set_centered(false)
			sprite.set_pos(Vec2{f32((i % cols) * img_size), f32((i / cols) * img_size)})
		}
	}
}

fn (g &Game) update(_ f32) {
	if mut r := g.root {
		mv.emit_notification(mut r, .update)
	}
}

fn (mut g Game) draw() {
	if mut r := g.root {
		mv.emit_notification(mut r, .draw)
	}

	rl.draw_text('image gen sample', 2, 2, 4, rl.raywhite)
}

fn main() {
	mut game := Game{}
	game.setup()
}
