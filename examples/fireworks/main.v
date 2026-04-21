module main

import raylib as rl
import math
import rand
import mv.engine {
	App,
	BurstEmitter,
	BurstGroup,
	Node,
	ParamRange,
	ParticleEmitter,
	SignalArg,
	Sprite,
	VSignalHandler,
}
import mv.core { BakedCurve, Curve, Gradient, Vec2, gen_image_sdf_circle }

// --- constants ---

const viewport_w = f32(320)
const viewport_h = f32(240)
const pool_size = int(6)
const fw_gravity = Vec2{0, 85}

// each palette is [burst_color, shimmer_color].
// burst particles are bright and saturated; shimmer particles are lighter.
const palettes = [
	[rl.Color{255, 70, 70, 255}, rl.Color{255, 200, 180, 255}], // red
	[rl.Color{70, 150, 255, 255}, rl.Color{180, 215, 255, 255}], // blue
	[rl.Color{80, 220, 80, 255}, rl.Color{190, 255, 190, 255}], // green
	[rl.Color{255, 215, 40, 255}, rl.Color{255, 250, 180, 255}], // gold
	[rl.Color{210, 70, 255, 255}, rl.Color{235, 185, 255, 255}], // violet
	[rl.Color{60, 230, 210, 255}, rl.Color{175, 255, 245, 255}], // cyan
]

// --- rocket pool entry ---

struct RocketState {
mut:
	sprite    ?&Sprite
	trail     ?&ParticleEmitter
	pos       Vec2
	vel       Vec2
	fuse      f32
	color_idx int
	active    bool
}

// --- game ---

@[heap]
struct Game {
mut:
	app          ?&App
	root         ?&Node
	rockets      []RocketState
	launch_timer f32 = 0.2 // first rocket fires quickly
	curves       map[string]BakedCurve
}

fn (mut g Game) setup() {
	g.app = App.new(g.init, g.update, g.draw, none, none)
	if mut app := g.app {
		app.run()
	}
}

// --- texture helpers ---

// make_glow generates a soft radial SDF glow: bright white centre fading to
// transparent at the edge. blend mode is set to additive so it just adds light.
// the same texture is tinted at draw time to produce any desired color.
fn make_glow(mut app App, name string, size int) {
	mut grad := Gradient.from_colors([
		rl.Color{255, 255, 255, 255},
		rl.Color{255, 255, 255, 0},
	])
	img := gen_image_sdf_circle(size, size, Vec2{0.5, 0.5}, 0.5, 0.5, &grad)
	tex := rl.load_texture_from_image(img)
	app.textures.add_texture(name, tex)
	if h := app.textures.get_handle(name) {
		if mut res := h.get() {
			res.set_filter_mode(.texture_filter_bilinear)
			res.blend_mode = .blend_additive
		}
	}
}

// --- init ---

fn (mut g Game) init() {
	mut app := g.app or { return }

	app.set_window_title('mv: fireworks')
	app.set_window_size(640, 480)
	app.set_viewport_size(int(viewport_w), int(viewport_h))
	app.set_target_fps(60)
	app.set_clear_color(rl.Color{4, 4, 14, 255})

	// procedurally generated textures - no image files needed
	make_glow(mut app, 'glow_lg', 32) // rocket sprite + burst particles
	make_glow(mut app, 'glow_sm', 12) // trail sparks

	mut root := Node.new(app, 'root')

	// bake all shared curves once here; spawn_explosion reads from g.curves
	mut trail_alpha := Curve.new()
	trail_alpha.add_point(Vec2{0.0, 1.0}, 0, 0)
	trail_alpha.add_point(Vec2{0.6, 0.7}, 0, 0)
	trail_alpha.add_point(Vec2{1.0, 0.0}, 0, 0)
	g.curves['trail_alpha'] = trail_alpha.bake(64)

	mut trail_scale := Curve.new()
	trail_scale.add_point(Vec2{0.0, 1.0}, 0, 0)
	trail_scale.add_point(Vec2{1.0, 0.2}, 0, 0)
	g.curves['trail_scale'] = trail_scale.bake(32)

	g.curves['burst_dist'] = Curve.ease_in_out().bake(64)

	mut burst_alpha := Curve.flat(1.0)
	burst_alpha.add_point(Vec2{0.5, 1.0}, 0, 0)
	burst_alpha.add_point(Vec2{1.0, 0.0}, 0, 0)
	g.curves['burst_alpha'] = burst_alpha.bake(64)

	mut burst_scale := Curve.new()
	burst_scale.add_point(Vec2{0.0, 1.3}, 0, 0)
	burst_scale.add_point(Vec2{0.18, 1.0}, 0, 0)
	burst_scale.add_point(Vec2{1.0, 0.25}, 0, 0)
	g.curves['burst_scale'] = burst_scale.bake(64)

	mut shim_alpha := Curve.new()
	shim_alpha.add_point(Vec2{0.0, 0.75}, 0, 0)
	shim_alpha.add_point(Vec2{0.65, 0.55}, 0, 0)
	shim_alpha.add_point(Vec2{1.0, 0.0}, 0, 0)
	g.curves['shim_alpha'] = shim_alpha.bake(64)

	mut shim_scale := Curve.new()
	shim_scale.add_point(Vec2{0.0, 1.0}, 0, 0)
	shim_scale.add_point(Vec2{0.5, 0.65}, 0, 0)
	shim_scale.add_point(Vec2{1.0, 0.1}, 0, 0)
	g.curves['shim_scale'] = shim_scale.bake(32)

	// build rocket pool
	g.rockets = []RocketState{len: pool_size}
	for i in 0 .. pool_size {
		// glow sprite - hidden until this rocket slot is launched
		mut spr := Sprite.new(app, 'rocket_${i}', 'glow_lg')
		spr.tint = rl.Color{0, 0, 0, 0}
		root.add_child(mut spr)

		// continuous spark trail, world-space so sparks stay behind the rocket
		mut trail := ParticleEmitter.new(app, 'trail_${i}')
		trail.max_particles = 80
		trail.emission_rate = 45.0
		trail.autoplay = false
		trail.local_coords = false
		trail.lifetime = ParamRange.ranged(0.22, 0.45)
		trail.initial_speed = ParamRange.ranged(16.0, 0.65)
		trail.direction = Vec2{0, 1} // emit downward behind rocket
		trail.spread = f32(math.pi) / 4.5
		trail.gravity = Vec2{0, 30}
		trail.base_color = rl.white
		trail.scale_start = ParamRange.ranged(0.28, 0.35)
		trail.alpha_over_lifetime = unsafe { &g.curves['trail_alpha'] }
		trail.scale_over_lifetime = unsafe { &g.curves['trail_scale'] }
		trail.set_texture_id('glow_sm') or {}
		root.add_child(mut trail)

		g.rockets[i] = RocketState{
			sprite: spr
			trail:  trail
		}
	}

	app.scene_root = root
	g.root = root
}

// --- rocket launch ---

fn (mut g Game) launch_rocket(idx int) {
	mut r := &g.rockets[idx]

	cidx := int(rand.f32() * palettes.len)
	col := palettes[cidx][0]

	r.pos = Vec2{30 + rand.f32() * (viewport_w - 60), viewport_h - 8}
	r.vel = Vec2{(rand.f32() * 2 - 1) * 22, -(155 + rand.f32() * 10)}
	r.fuse = 1.45 + rand.f32() * 0.55
	r.color_idx = cidx
	r.active = true

	if mut spr := r.sprite {
		spr.tint = rl.Color{col.r, col.g, col.b, 210}
		spr.set_pos(r.pos)
		spr.set_scale(Vec2{0.45, 0.45})
	}

	if mut trail := r.trail {
		trail.base_color = rl.Color{col.r, col.g, col.b, 230}
		trail.set_pos(r.pos)
		trail.play()
	}
}

// --- explosion ---

fn (mut g Game) spawn_explosion(pos Vec2, color_idx int) {
	mut app := g.app or { return }
	mut root := g.root or { return }

	burst_col := palettes[color_idx][0]
	shimmer_col := palettes[color_idx][1]

	glow_h := app.textures.get_handle('glow_lg') or { return }

	baked_dist := unsafe { &g.curves['burst_dist'] }
	baked_alpha := unsafe { &g.curves['burst_alpha'] }
	baked_scale := unsafe { &g.curves['burst_scale'] }
	baked_shim_alpha := unsafe { &g.curves['shim_alpha'] }
	baked_shim_scale := unsafe { &g.curves['shim_scale'] }

	// --- main burst: 24 saturated particles spread over full circle ---
	mut main_e := BurstEmitter.new(app, 'burst_main')
	main_e.autoplay = false
	main_e.num_particles = 24
	main_e.lifetime = ParamRange.ranged(0.85, 0.25)
	main_e.spread = f32(math.pi)
	main_e.distance = ParamRange.ranged(58.0, 0.35)
	main_e.start_radius = 2.0
	main_e.base_color = burst_col
	main_e.image_scale = 0.52
	main_e.image_scale_randomness = 0.28
	main_e.blend_mode = .add
	main_e.align_sprite_rotation = true
	main_e.set_texture_handle(glow_h)
	main_e.distance_curve = baked_dist
	main_e.alpha_curve = baked_alpha
	main_e.scale_curve = baked_scale
	main_e.set_pos(pos)

	// --- shimmer: 14 lighter particles with a longer, drifting tail ---

	mut shim_e := BurstEmitter.new(app, 'burst_shim')
	shim_e.autoplay = false
	shim_e.num_particles = 14
	shim_e.lifetime = ParamRange.ranged(1.4, 0.45)
	shim_e.spread = f32(math.pi)
	shim_e.distance = ParamRange.ranged(42.0, 0.55)
	shim_e.start_radius = 3.0
	shim_e.base_color = shimmer_col
	shim_e.image_scale = 0.32
	shim_e.image_scale_randomness = 0.40
	shim_e.blend_mode = .add
	shim_e.align_sprite_rotation = false
	shim_e.set_texture_handle(glow_h)
	shim_e.distance_curve = baked_dist
	shim_e.alpha_curve = baked_shim_alpha
	shim_e.scale_curve = baked_shim_scale
	shim_e.set_pos(pos)

	// BurstGroup coordinates both emitters and self-destructs once all particles expire.
	// emitters must be BOTH add_emitter'd (for finish tracking) AND add_child'd (for
	// scene tree update/draw) - BurstGroup only handles coordination, not rendering.
	mut group := BurstGroup.new(app, 'explosion')
	group.autoplay = false

	group.add_emitter(mut main_e)
	group.add_child(mut main_e)
	group.add_emitter(mut shim_e)
	group.add_child(mut shim_e)

	group.signals.connect(engine.sig_group_finished, VSignalHandler{
		func:     fn (recv voidptr, _ voidptr, _ []SignalArg) {
			mut grp := unsafe { &BurstGroup(recv) }
			grp.queue_free()
		}
		receiver: voidptr(group)
	})

	root.add_child(mut group)
	group.burst()
}

// --- update / draw ---

fn (mut g Game) update(dt f32) {
	// advance active rockets
	for i in 0 .. pool_size {
		mut r := &g.rockets[i]
		if !r.active {
			continue
		}

		r.vel.x += fw_gravity.x * dt
		r.vel.y += fw_gravity.y * dt
		r.pos.x += r.vel.x * dt
		r.pos.y += r.vel.y * dt

		if mut spr := r.sprite {
			spr.set_pos(r.pos)
		}
		if mut trail := r.trail {
			trail.set_pos(r.pos)
		}

		r.fuse -= dt
		if r.fuse <= 0 {
			g.spawn_explosion(r.pos, r.color_idx)
			if mut spr := r.sprite {
				spr.tint = rl.Color{0, 0, 0, 0}
			}
			if mut trail := r.trail {
				trail.stop()
			}
			r.active = false
		}
	}

	// launch timer: find an idle rocket slot and fire it
	g.launch_timer -= dt
	if g.launch_timer <= 0 {
		for i in 0 .. pool_size {
			if !g.rockets[i].active {
				g.launch_rocket(i)
				break
			}
		}
		g.launch_timer = 0.55 + rand.f32() * 0.65
	}
}

fn (g &Game) draw() {}

fn main() {
	mut game := Game{}
	game.setup()
}
