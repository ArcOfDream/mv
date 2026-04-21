module engine

import rand
import math
import raylib as rl
import core { BakedCurve, Gradient, Vec2 }
import resourcemanager { Handle, TextureResource }

/*
ParticleEmitter: usage example

ParticleEmitter is a physics-driven continuous or burst particle system.
Particles accumulate velocity, gravity, and radial/tangential forces each tick.

Basic continuous emitter (fire, smoke, rain):

	mut smoke := ParticleEmitter.new(app)
	smoke.node_name     = 'smoke'
	smoke.max_particles = 64
	smoke.emission_rate = 12.0
	smoke.lifetime      = core.ParamRange{ value: 2.0, randomness: 0.4 }
	smoke.initial_speed = core.ParamRange{ value: 30.0, randomness: 0.5 }
	smoke.direction     = Vec2{0, -1}
	smoke.spread        = f32(math.pi) / 6.0  // 30-degree cone
	smoke.gravity       = Vec2{0, -8.0}
	smoke.base_color    = rl.Color{180, 180, 180, 200}
	smoke.texture       = app.textures.get_handle('particle_smoke') or { Handle[TextureResource]{} }
	scene_root.add_child(mut smoke)

Apply lifecycle curves for visual richness. Curves should be baked before
assigning: curve.bake(128) gives 128 samples:

	mut scale_curve := core.Curve.new()
	scale_curve.add_point(Vec2{0.0, 0.2}, 0, 0)
	scale_curve.add_point(Vec2{0.5, 1.0}, 0, 0)
	scale_curve.add_point(Vec2{1.0, 0.0}, 0, 0)
	smoke.scale_over_lifetime = scale_curve.bake(128)

	mut alpha_curve := core.Curve.flat(1.0)
	alpha_curve.add_point(Vec2{0.8, 1.0}, 0, 0)
	alpha_curve.add_point(Vec2{1.0, 0.0}, 0, 0)
	smoke.alpha_over_lifetime = alpha_curve.bake(64)

	mut grad := core.Gradient.new()
	grad.add_stop(0.0, rl.Color{255, 200, 100, 255})
	grad.add_stop(1.0, rl.Color{80, 80, 80, 0})
	smoke.color_over_lifetime = grad

One-shot burst (explosion, hit effect):

	mut explosion := ParticleEmitter.new(app)
	explosion.one_shot       = true
	explosion.burst          = 32
	explosion.autoplay       = false   // fire manually
	explosion.max_particles  = 32
	explosion.lifetime       = core.ParamRange{ value: 0.6, randomness: 0.3 }
	explosion.initial_speed  = core.ParamRange{ value: 200.0, randomness: 0.6 }
	explosion.spread         = f32(math.pi)  // full circle
	explosion.radial_accel   = core.ParamRange{ value: -60.0 }  // pull inward
	// connect finished signal to queue_free the node
	explosion.signals.connect(sig_emitter_finished, VSignalHandler{
		func: fn (recv voidptr, _ voidptr, _ []core.SignalArg) {
			mut e := unsafe { &ParticleEmitter(recv) }
			e.queue_free()
		}
		receiver: explosion
	})
	parent.add_child(mut explosion)
	explosion.play()

local_coords = false keeps particles in world space after spawn (trail effect).
preprocess warm-starts the simulation so the emitter appears fully populated
on the first visible frame rather than building up from nothing.

	smoke.local_coords = false   // particles stay where spawned
	smoke.preprocess   = 2.0     // 2 seconds of simulated history
	smoke.fixed_fps    = 30.0    // simulate at 30Hz regardless of render rate
*/

pub const sig_emitter_finished = 'finished'

// ParamRange stores a base value and a randomness factor.
// sample() returns a value symmetrically randomised around value by up to value*randomness.
// randomness = 0.0: always returns value. randomness = 1.0: uniform in [0, 2*value].
pub struct ParamRange {
pub mut:
	value      f32
	randomness f32
}

@[inline]
pub fn (p ParamRange) sample() f32 {
	if p.randomness == 0.0 {
		return p.value
	}
	return p.value + p.value * p.randomness * (rand.f32() * 2.0 - 1.0)
}

@[inline]
pub fn ParamRange.fixed(v f32) ParamRange {
	return ParamRange{
		value: v
	}
}

@[inline]
pub fn ParamRange.ranged(v f32, randomness f32) ParamRange {
	return ParamRange{
		value:      v
		randomness: randomness
	}
}

// EmissionMode controls how particles are placed within the emission shape.
pub enum EmissionMode {
	volume           // anywhere inside the shape
	surface          // perimeter or edge only
	directed_surface // surface spawn + initial velocity aligned to surface normal
}

pub type EmissionShape = PointEmission | CircleEmission | RectEmission | LineEmission

pub struct PointEmission {}

pub struct CircleEmission {
pub mut:
	radius f32 = 32.0
}

pub struct RectEmission {
pub mut:
	size Vec2 = Vec2{32, 32}
}

// LineEmission spawns particles along a horizontal line centred at the emitter origin.
// normal is the outward direction used in directed_surface mode.
pub struct LineEmission {
pub mut:
	length f32  = 64.0
	normal Vec2 = Vec2{0, -1}
}

// spawn returns a local-space offset and surface normal for the given mode.
// The normal is only used when emission_mode is .directed_surface.
fn (s EmissionShape) spawn(mode EmissionMode) (Vec2, Vec2) {
	match s {
		PointEmission {
			return Vec2{}, Vec2{0, -1}
		}
		CircleEmission {
			angle := rand.f32() * f32(math.tau)
			outward := Vec2{f32(math.cos(f64(angle))), f32(math.sin(f64(angle)))}
			pos := match mode {
				// uniform disk sampling: scale by sqrt to avoid centre clustering
				.volume {
					outward.scale(f32(math.sqrt(f64(rand.f32()))) * s.radius)
				}
				.surface, .directed_surface {
					outward.scale(s.radius)
				}
			}
			return pos, outward
		}
		RectEmission {
			hw := s.size.x * 0.5
			hh := s.size.y * 0.5
			if mode == .volume {
				return Vec2{(rand.f32() - 0.5) * s.size.x, (rand.f32() - 0.5) * s.size.y}, Vec2{0, -1}
			}
			// pick an edge weighted by its length so density is uniform along the perimeter
			perim := 2.0 * (s.size.x + s.size.y)
			t := rand.f32() * perim
			if t < s.size.x {
				return Vec2{t - hw, -hh}, Vec2{0, -1}
			} else if t < s.size.x + s.size.y {
				return Vec2{hw, (t - s.size.x) - hh}, Vec2{1, 0}
			} else if t < 2.0 * s.size.x + s.size.y {
				return Vec2{(t - s.size.x - s.size.y) - hw, hh}, Vec2{0, 1}
			} else {
				return Vec2{-hw, (t - 2.0 * s.size.x - s.size.y) - hh}, Vec2{-1, 0}
			}
		}
		LineEmission {
			return Vec2{(rand.f32() - 0.5) * s.length, 0}, s.normal
		}
	}
}

// spread_dir rotates base by a random angle within [-half_angle, half_angle].
@[inline]
fn spread_dir(base Vec2, half_angle f32) Vec2 {
	if half_angle == 0.0 {
		return base
	}
	a := f32(math.atan2(f64(base.y), f64(base.x))) + (rand.f32() * 2.0 - 1.0) * half_angle
	return Vec2{f32(math.cos(f64(a))), f32(math.sin(f64(a)))}
}

// Particle is plain data: no heap allocation, lives in a flat pool on the emitter.
struct Particle {
mut:
	pos         Vec2
	velocity    Vec2
	age         f32
	lifetime    f32
	color       rl.Color
	rotation    f32 // radians
	angular_vel f32 // radians per second
	scale       f32
	// sampled once at spawn so each particle has a consistent force profile
	radial_accel     f32
	tangential_accel f32
}

@[heap]
pub struct ParticleEmitter {
	Node
pub mut:
	// pool: configure before the node enters the tree; changing after ready has no effect
	max_particles int = 256

	// emission
	shape         EmissionShape = PointEmission{}
	emission_mode EmissionMode  = .volume
	emission_rate f32           = 20.0 // particles per second; 0 = burst only
	burst         int // particles fired immediately on play()

	// playback
	one_shot bool // stop emitting after initial burst; sig_emitter_finished fires when all particles expire
	autoplay bool = true

	// per-particle initial parameters: randomness applied once at spawn
	lifetime       ParamRange = ParamRange{
		value: 1.0
	}
	initial_speed  ParamRange = ParamRange{
		value: 100.0
	}
	scale_start    ParamRange = ParamRange{
		value: 1.0
	}
	rotation_start ParamRange
	angular_vel    ParamRange

	// directional emission
	direction Vec2 = Vec2{0, -1} // base emission direction; normalised at spawn time
	spread    f32 // cone half-angle in radians

	// forces: sampled once per particle at spawn for consistent per-particle behaviour
	radial_accel     ParamRange // positive = outward from emitter origin
	tangential_accel ParamRange // positive = counter-clockwise

	// flat acceleration applied every simulation tick
	gravity Vec2

	// lifecycle curves: sampled at t = age / lifetime ∈ [0, 1]
	scale_over_lifetime ?&BakedCurve
	alpha_over_lifetime ?&BakedCurve
	color_over_lifetime ?&Gradient

	// rendering
	texture    Handle[TextureResource]
	base_color rl.Color = rl.white

	// simulation control
	local_coords bool = true // true: particles stay relative to emitter; false: world-space
	fixed_fps    f32 // decouple simulation from render rate; 0 = simulate every frame
	preprocess   f32 // warm-start seconds applied during ready() before first frame

	// signals
	signals SignalTable

	// internal state
	particles      []Particle
	active         int
	playing        bool
	emission_accum f32
	sim_accum      f32
	burst_pending  int
}

pub fn ParticleEmitter.instantiate(app &App, name string) &ParticleEmitter {
	return &ParticleEmitter{
		app:       app
		node_name: name
	}
}

pub fn ParticleEmitter.new(app &App, name string) &ParticleEmitter {
	return ParticleEmitter.instantiate(app, name)
}

fn (e &ParticleEmitter) wren_class_name() string {
	return 'ParticleEmitter'
}

// play (re)starts emission. Clears the active pool and queues any burst.
pub fn (mut e ParticleEmitter) play() {
	e.active = 0
	e.emission_accum = 0.0
	e.sim_accum = 0.0
	e.playing = true
	e.burst_pending = e.burst
}

// stop halts emission and immediately clears all active particles.
pub fn (mut e ParticleEmitter) stop() {
	e.playing = false
	e.active = 0
}

// pause toggles emission without disturbing existing particles.
pub fn (mut e ParticleEmitter) pause() {
	e.playing = !e.playing
}

// is_emitting returns true while the emitter is actively spawning particles.
@[inline]
pub fn (e &ParticleEmitter) is_emitting() bool {
	return e.playing
}

// particle_count returns the number of currently live particles.
@[inline]
pub fn (e &ParticleEmitter) particle_count() int {
	return e.active
}

pub fn (mut e ParticleEmitter) unload() {
	e.texture.release()
}

pub fn (mut e ParticleEmitter) set_texture_id(val string) !Handle[TextureResource] {
	e.texture.release()
	e.texture = e.app.textures.get_handle(val) or {
		e.texture = Handle[TextureResource]{}
		return error('texture not found: ${val}')
	}
	return e.texture
}

pub fn (mut e ParticleEmitter) set_texture_handle(h Handle[TextureResource]) {
	e.texture.release()
	e.texture = h
}

// tree callbacks

fn (mut e ParticleEmitter) ready_internal() {
	e.particles = []Particle{len: e.max_particles}

	if e.autoplay {
		e.play()
	}

	// warm-start: run the simulation headlessly so the effect appears fully populated
	// on the first visible frame rather than building up from nothing
	if e.preprocess > 0.0 {
		step := if e.fixed_fps > 0.0 { 1.0 / e.fixed_fps } else { 1.0 / 60.0 }
		mut acc := f32(0.0)
		for acc < e.preprocess {
			e.simulate(step)
			acc += step
		}
	}
}

fn (mut e ParticleEmitter) exit_tree_internal() {
	e.signals.clear()
}

fn (mut e ParticleEmitter) update_internal(dt f32) {
	if e.fixed_fps > 0.0 {
		// fixed-timestep accumulator: decouple simulation rate from render rate
		step := 1.0 / e.fixed_fps
		e.sim_accum += dt
		for e.sim_accum >= step {
			e.simulate(step)
			e.sim_accum -= step
		}
	} else {
		e.simulate(dt)
	}
}

fn (mut e ParticleEmitter) draw_internal() {
	world_pos := e.get_global_pos()

	for i in 0 .. e.active {
		p := e.particles[i]
		t := p.age / p.lifetime

		draw_pos := if e.local_coords {
			p.pos // local-space; matrix translates to world
		} else {
			p.pos - world_pos // de-relativize so matrix re-applies correctly
		}

		// apply lifecycle color and alpha: alpha curve wins over color curve's alpha
		mut draw_color := p.color
		if gc := e.color_over_lifetime {
			draw_color = gc.sample(t)
		}
		if ac := e.alpha_over_lifetime {
			draw_color.a = u8(ac.sample(t) * 255.0)
		}

		draw_scale := if sc := e.scale_over_lifetime {
			p.scale * sc.sample(t)
		} else {
			p.scale
		}

		// 57.29578 = 180 / pi
		rot_deg := p.rotation * 57.29578

		if tr := e.texture.get() {
			tw := f32(tr.tex.width) * draw_scale
			th_ := f32(tr.tex.height) * draw_scale
			src := rl.Rectangle{0, 0, f32(tr.tex.width), f32(tr.tex.height)}
			dest := rl.Rectangle{draw_pos.x, draw_pos.y, tw, th_}
			origin := Vec2{tw * 0.5, th_ * 0.5}
			rl.draw_texture_pro(tr.tex, src, dest, origin, rot_deg, draw_color)
		} else {
			// zero-asset fallback
			rl.draw_circle_v(draw_pos, 4.0 * draw_scale, draw_color)
		}
	}
}

// simulate advances the particle system by dt seconds.
fn (mut e ParticleEmitter) simulate(dt f32) {
	// fire burst queued by play()
	if e.burst_pending > 0 {
		for _ in 0 .. e.burst_pending {
			e.spawn_particle()
		}
		e.burst_pending = 0
		// one_shot: stop continuous emission after the burst fires
		if e.one_shot {
			e.playing = false
		}
	}

	// continuous emission
	if e.playing && e.emission_rate > 0.0 {
		e.emission_accum += e.emission_rate * dt
		for e.emission_accum >= 1.0 {
			e.spawn_particle()
			e.emission_accum -= 1.0
		}
	}

	// emitter origin for radial/tangential accel: local origin when local_coords,
	// otherwise the emitter's current world position
	emitter_origin := if e.local_coords { Vec2{} } else { e.get_global_pos() }

	// advance particles; swap-pop expired ones so active particles stay contiguous
	mut i := 0
	for i < e.active {
		new_age := e.particles[i].age + dt

		if new_age >= e.particles[i].lifetime {
			e.particles[i] = e.particles[e.active - 1]
			e.active--
			continue // re-examine this slot: it now holds the swapped particle
		}

		mut p := &e.particles[i]
		p.age = new_age

		// radial and tangential acceleration relative to emitter origin
		from_origin := Vec2{p.pos.x - emitter_origin.x, p.pos.y - emitter_origin.y}
		dist := f32(math.sqrt(f64(from_origin.x * from_origin.x + from_origin.y * from_origin.y)))
		if dist > 0.001 {
			outward := from_origin.scale(1.0 / dist) // unit vector away from emitter
			tangent := Vec2{-outward.y, outward.x} // 90° CCW
			p.velocity = p.velocity + outward.scale(p.radial_accel * dt)
			p.velocity = p.velocity + tangent.scale(p.tangential_accel * dt)
		}

		p.velocity = p.velocity + e.gravity.scale(dt)
		p.pos = p.pos + p.velocity.scale(dt)
		p.rotation = p.rotation + p.angular_vel * dt

		i++
	}

	// one_shot finish: emission has stopped and the last particle has expired
	if e.one_shot && !e.playing && e.active == 0 {
		// Note: pass app.wren_vm and app.wren_call_handles in place of none / []
		// if Wren signal handlers are needed on this emitter
		e.signals.emit(sig_emitter_finished, e, [], none, [])
	}
}

fn (mut e ParticleEmitter) spawn_particle() {
	if e.active >= e.max_particles {
		return
	}

	spawn_offset, surface_normal := e.shape.spawn(e.emission_mode)

	// directed_surface uses the shape's outward normal directly;
	// all other modes apply spread around the emitter's direction
	dir_len := f32(math.sqrt(f64(e.direction.x * e.direction.x + e.direction.y * e.direction.y)))
	base_dir := if e.emission_mode == .directed_surface {
		surface_normal
	} else if dir_len > 0.001 {
		e.direction.scale(1.0 / dir_len)
	} else {
		Vec2{0, -1}
	}
	vel_dir := spread_dir(base_dir, e.spread)

	pos := if e.local_coords {
		spawn_offset
	} else {
		wp := e.get_global_pos()
		Vec2{wp.x + spawn_offset.x, wp.y + spawn_offset.y}
	}

	e.particles[e.active] = Particle{
		pos:              pos
		velocity:         vel_dir.scale(e.initial_speed.sample())
		age:              0.0
		lifetime:         e.lifetime.sample()
		color:            e.base_color
		rotation:         e.rotation_start.sample()
		angular_vel:      e.angular_vel.sample()
		scale:            e.scale_start.sample()
		radial_accel:     e.radial_accel.sample()
		tangential_accel: e.tangential_accel.sample()
	}
	e.active++
}
