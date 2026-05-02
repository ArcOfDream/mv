module engine

import rand
import math
import raylib as rl
import core { BakedCurve, Vec2 }
import resourcemanager { Handle, ShaderResource, TextureResource }

// BurstEmitter is adapted from BurstParticles2D by Ian Sly (ivysly)
// https://github.com/ivysly/BurstParticles2D (or wherever the original is hosted)
// Copyright (c) 2023 Ian Sly ivysly@protonmail.com: MIT License
// See LICENSES/BurstParticles2D-MIT.txt for the full license text.

/*
BurstEmitter: usage example

BurstEmitter is a curve-driven one-shot particle system adapted from
BurstParticles2D by Ian Sly (MIT). Unlike ParticleEmitter, particles have
no velocity or forces: position is computed each frame as a pure function
of normalised lifetime t in [0,1] via authored BakedCurve instances.
Use it for stylised hit sparks, magic bursts, and effects that need a
hand-crafted feel rather than simulated motion.

	mut sparks := BurstEmitter.new(app, 'hit_sparks')
	sparks.num_particles = 12
	sparks.lifetime      = core.ParamRange{ value: 0.35 }
	sparks.set_texture_id('particle_spark') or {}
	sparks.base_color    = rl.Color{255, 220, 80, 255}
	sparks.direction     = Vec2{0, -1}
	sparks.spread        = f32(math.pi)        // full circle
	sparks.distance      = core.ParamRange{ value: 64.0, randomness: 0.4 }
	sparks.autoplay      = false

Shape the travel curve: particles accelerate out then slow:

	mut dist_curve := core.Curve.new()
	dist_curve.add_point(Vec2{0.0, 0.0}, 0, 2)
	dist_curve.add_point(Vec2{0.4, 0.9}, 0, 0)
	dist_curve.add_point(Vec2{1.0, 1.0}, 0, 0)
	sparks.distance_curve = dist_curve.bake(64)

Fade out the alpha:

	mut alpha := core.Curve.new()
	alpha.add_point(Vec2{0.0, 1.0}, 0, 0)
	alpha.add_point(Vec2{0.7, 1.0}, 0, 0)
	alpha.add_point(Vec2{1.0, 0.0}, 0, 0)
	sparks.alpha_curve = alpha.bake(64)

center_concentration clusters particles toward the launch direction.
falloff_curve attenuates max_distance by angular distance from centre:

	sparks.center_concentration = 2.0
	mut falloff := core.Curve.new()
	falloff.add_point(Vec2{0.0, 1.0}, 0, 0)
	falloff.add_point(Vec2{1.0, 0.3}, 0, 0)
	sparks.falloff_curve = falloff.bake(32)

Gradient map shader (maps particle texture luminance through a color gradient).
Load the shader and a 1D gradient texture, then assign both:

	sparks.set_shader_id('gradient_map') or {}
	sparks.set_gradient_texture_id('spark_gradient') or {}
	sparks.color_offset_high   =  0.0   // gradient sample at t=0
	sparks.color_offset_low    = -0.8   // gradient sample at t=1 (shift toward cooler)
	sparks.blend_mode          = .add   // additive blending for glowing effects

Fire the emitter on demand:

	parent.add_child(mut sparks)
	sparks.burst()

	// or listen for completion to queue_free or trigger a chain
	sparks.signals.connect(sig_burst_finished, VSignalHandler{
		func: fn (recv voidptr, _ voidptr, _ []engine.SignalArg) {
			mut e := unsafe { &BurstEmitter(recv) }
			e.queue_free()
		}
		receiver: sparks
	})
*/

pub const sig_burst_finished = 'burst_finished'

pub enum BlendMode {
	mix
	add
}

// BurstParticle stores only the values that are fixed at spawn time.
struct BurstParticle {
mut:
	t         f32 // normalised lifetime; advances +/-dt/lifetime per tick
	lifetime  f32
	start_dir f32  // launch direction in radians, fixed at spawn
	end_dir   f32  // direction at t=1 after direction_rotation, fixed at spawn
	max_dist  f32  // maximum travel distance, fixed at spawn (post-falloff)
	max_angle f32  // sprite rotation limit in radians, fixed at spawn
	scale_mod f32  // per-particle scale multiplier from image_scale_randomness
	co_hi     f32  // color_offset high value, fixed at spawn
	co_lo     f32  // color_offset low value, fixed at spawn
	offset    Vec2 // base offset vector, fixed at spawn
	color     rl.Color
}

// exponential_sample returns a sample from an exponential distribution.
// lambda controls concentration: higher values produce smaller outputs,
// making particles cluster near the center of the launch arc.
@[inline]
fn exponential_sample(lambda f32) f32 {
	return -f32(math.log(f64(1.0 - rand.f32()))) / lambda
}

@[heap]
pub struct BurstEmitter {
	Node
pub mut:
	num_particles int = 10

	// timing
	lifetime          ParamRange = ParamRange{
		value: 1.0
	}
	reverse           bool // animate t from 1->0 instead of 0->1
	preprocess_amount f32  // 0..1: particles start pre-aged by this fraction
	repeat            bool
	autoplay          bool = true

	// texture and rendering
	image_scale            f32 = 1.0
	image_scale_randomness f32
	base_color             rl.Color = rl.white
	blend_mode             BlendMode

	// gradient map shader (optional)
	// gradient_texture is a 1D gradient image; the shader maps particle
	// texture luminance through it.
	color_offset_high f32 = 0.0  // gradient sample position at t=0
	color_offset_low  f32 = -1.0 // gradient sample position at t=1

	// emission direction
	direction            Vec2 = Vec2{1, 0} // base launch direction (normalised at spawn)
	spread               f32  = f32(math.pi)    // half-angle of launch arc in radians
	center_concentration f32        // > 0: cluster particles toward direction; higher = tighter
	direction_rotation   ParamRange // additional angular drift applied over the particle's life

	// travel distance
	start_radius f32 // particles begin this many pixels from the emitter
	distance     ParamRange = ParamRange{
		value: 100.0
	}
	// falloff_curve attenuates max_distance by the particle's normalised angular distance
	// from the launch direction: 0.0 at centre, 1.0 at spread edge.
	// a curve from (0,1) to (1,0) makes edge particles travel less far.
	falloff_curve ?&BakedCurve

	// sprite
	angle                 ParamRange // sprite rotation at t=1 in radians
	align_sprite_rotation bool = true // rotate sprite to face travel direction
	randomly_flip_angle   bool

	// tween curves: all optional; linear interpolation used when absent
	distance_curve     ?&BakedCurve // shapes lerp(start_radius, max_dist, t)
	rotation_curve     ?&BakedCurve // shapes lerp(start_dir, end_dir, t)
	offset_curve       ?&BakedCurve // scales the offset vector (1.0 = full offset)
	angle_curve        ?&BakedCurve // shapes max_angle * curve(t); linear if absent
	scale_curve        ?&BakedCurve // uniform scale multiplier over t
	x_scale_curve      ?&BakedCurve // horizontal scale independently
	y_scale_curve      ?&BakedCurve // vertical scale independently
	alpha_curve        ?&BakedCurve // alpha [0,1] over t
	color_offset_curve ?&BakedCurve // shapes lerp(co_hi, co_lo, t) for gradient map

	// base offset added to particle position (in emitter-local space)
	offset       Vec2
	local_coords bool = true // true: particles move with emitter; false: world-space

	// signals
	signals SignalTable
mut:
	// texture / shader handles - plain handles; invalid handle = no asset (get() returns none)
	texture             Handle[TextureResource]
	gradient_texture    Handle[TextureResource]
	gradient_map_shader Handle[ShaderResource]

	// internal
	particles  []BurstParticle
	active     int
	just_burst bool // true from burst() until active hits 0
}

pub fn BurstEmitter.instantiate(app &App, name string) &BurstEmitter {
	return &BurstEmitter{
		app:       app
		node_name: name
	}
}

pub fn BurstEmitter.new(app &App, name string) &BurstEmitter {
	return &BurstEmitter{
		app:       app
		node_name: name
	}
}

fn (e &BurstEmitter) wren_class_name() string {
	return 'BurstEmitter'
}

// unload releases every handle this emitter holds.
pub fn (mut e BurstEmitter) unload() {
	e.texture.release()
	e.gradient_texture.release()
	e.gradient_map_shader.release()
}

// --- texture ---

pub fn (e &BurstEmitter) get_texture_handle() Handle[TextureResource] {
	return e.texture
}

@[inline]
pub fn (e &BurstEmitter) get_texture() ?&TextureResource {
	return e.texture.get()
}

// set_texture_id releases the current handle and acquires a new one by name.
pub fn (mut e BurstEmitter) set_texture_id(val string) !Handle[TextureResource] {
	e.texture.release()
	e.texture = e.app.textures.get_handle(val) or {
		e.texture = Handle[TextureResource]{}
		return error('texture not found: ${val}')
	}
	return e.texture
}

// set_texture_handle takes ownership of a handle the caller already acquired or cloned.
pub fn (mut e BurstEmitter) set_texture_handle(h Handle[TextureResource]) {
	e.texture.release()
	e.texture = h
}

pub fn (e &BurstEmitter) get_texture_id() ?string {
	if !e.texture.is_valid() {
		return none
	}
	return e.app.textures.name_of(e.texture.id)
}

// --- gradient texture ---

pub fn (e &BurstEmitter) get_gradient_texture_handle() Handle[TextureResource] {
	return e.gradient_texture
}

@[inline]
pub fn (e &BurstEmitter) get_gradient_texture() ?&TextureResource {
	return e.gradient_texture.get()
}

pub fn (mut e BurstEmitter) set_gradient_texture_id(val string) !Handle[TextureResource] {
	e.gradient_texture.release()
	e.gradient_texture = e.app.textures.get_handle(val) or {
		e.gradient_texture = Handle[TextureResource]{}
		return error('gradient texture not found: ${val}')
	}
	return e.gradient_texture
}

pub fn (mut e BurstEmitter) set_gradient_texture_handle(h Handle[TextureResource]) {
	e.gradient_texture.release()
	e.gradient_texture = h
}

pub fn (e &BurstEmitter) get_gradient_texture_id() ?string {
	if !e.gradient_texture.is_valid() {
		return none
	}
	return e.app.textures.name_of(e.gradient_texture.id)
}

// --- gradient map shader ---

pub fn (e &BurstEmitter) get_shader_handle() Handle[ShaderResource] {
	return e.gradient_map_shader
}

@[inline]
pub fn (e &BurstEmitter) get_shader() ?&ShaderResource {
	return e.gradient_map_shader.get()
}

pub fn (mut e BurstEmitter) set_shader_id(val string) !Handle[ShaderResource] {
	e.gradient_map_shader.release()
	e.gradient_map_shader = e.app.shaders.get_handle(val) or {
		e.gradient_map_shader = Handle[ShaderResource]{}
		return error('shader not found: ${val}')
	}
	return e.gradient_map_shader
}

pub fn (mut e BurstEmitter) set_shader_handle(h Handle[ShaderResource]) {
	e.gradient_map_shader.release()
	e.gradient_map_shader = h
}

pub fn (e &BurstEmitter) get_shader_id() ?string {
	if !e.gradient_map_shader.is_valid() {
		return none
	}
	return e.app.shaders.name_of(e.gradient_map_shader.id)
}

// burst fires all particles simultaneously. If a burst is already in progress
// it is cleared first. Calling burst() again before particles expire restarts.
pub fn (mut e BurstEmitter) burst() {
	e.active = 0
	e.just_burst = true

	for _ in 0 .. e.num_particles {
		e.spawn_particle()
	}
}

// tree callbacks

fn (mut e BurstEmitter) ready_internal() {
	e.particles = []BurstParticle{len: e.num_particles}
	if e.autoplay {
		e.burst()
	}
}

fn (mut e BurstEmitter) exit_tree_internal() {
	e.signals.clear()
}

fn (mut e BurstEmitter) update_internal(dt f32) {
	e.simulate(dt)
}

fn (mut e BurstEmitter) draw_internal() {
	use_blend_add := e.blend_mode == .add

	for i in 0 .. e.active {
		p := e.particles[i]
		t := p.t

		// direction: lerp start_dir -> end_dir shaped by rotation_curve
		t_rot := if rc := e.rotation_curve { rc.sample(t) } else { t }
		cur_dir := p.start_dir + (p.end_dir - p.start_dir) * t_rot

		// distance: lerp start_radius -> max_dist shaped by distance_curve
		t_dist := if dc := e.distance_curve { dc.sample(t) } else { t }
		cur_dist := e.start_radius + (p.max_dist - e.start_radius) * t_dist

		// offset: scale base offset by offset_curve (1.0 = full; 0.0 = at origin)
		t_off := if oc := e.offset_curve { oc.sample(t) } else { f32(1.0) }
		cur_off := Vec2{p.offset.x * t_off, p.offset.y * t_off}

		// local-space position
		local_pos := Vec2{
			x: f32(math.cos(f64(cur_dir))) * cur_dist + cur_off.x
			y: f32(math.sin(f64(cur_dir))) * cur_dist + cur_off.y
		}
		draw_pos := local_pos // matrix handles the world translation

		// sprite rotation: angle_curve shapes max_angle; optionally aligned to travel dir
		t_ang := if ac := e.angle_curve { ac.sample(t) } else { t }
		cur_angle := p.max_angle * t_ang
		rot_rads := if e.align_sprite_rotation { cur_dir + cur_angle } else { cur_angle }
		rot_deg := rot_rads * 57.29578

		// per-axis scale
		sx := (if xsc := e.x_scale_curve { xsc.sample(t) } else { f32(1.0) }) * p.scale_mod * e.image_scale
		sy := (if ysc := e.y_scale_curve { ysc.sample(t) } else { f32(1.0) }) * p.scale_mod * e.image_scale
		s_mult := if sc := e.scale_curve { sc.sample(t) } else { f32(1.0) }

		// color and alpha
		mut draw_color := p.color
		if ac := e.alpha_curve {
			draw_color.a = u8(ac.sample(t) * 255.0)
		}

		// gradient map color_offset: shaped by color_offset_curve; defaults to hi->lo over t
		t_co := if coc := e.color_offset_curve { coc.sample(t) } else { f32(1.0) - t }
		cur_co := p.co_lo + (p.co_hi - p.co_lo) * t_co

		if tr := e.texture.get() {
			tw := f32(tr.tex.width) * sx * s_mult
			th_ := f32(tr.tex.height) * sy * s_mult
			src := rl.Rectangle{0, 0, f32(tr.tex.width), f32(tr.tex.height)}
			dest := rl.Rectangle{draw_pos.x, draw_pos.y, tw, th_}
			orig := Vec2{tw * 0.5, th_ * 0.5}

			if use_blend_add {
				rl.begin_blend_mode(int(rl.BlendMode.blend_additive))
			}

			// gradient map shader path
			if shr := e.gradient_map_shader.get() {
				rl.begin_shader_mode(shr.shd)
				co_loc := rl.get_shader_location(shr.shd, 'colorOffset')
				rl.set_shader_value(shr.shd, co_loc, &cur_co, int(rl.ShaderUniformDataType.shader_uniform_float))
				if gtr := e.gradient_texture.get() {
					g_loc := rl.get_shader_location(shr.shd, 'gradient')
					rl.set_shader_value_texture(shr.shd, g_loc, gtr.tex)
				}
				rl.draw_texture_pro(tr.tex, src, dest, orig, rot_deg, draw_color)
				rl.end_shader_mode()
			} else {
				rl.draw_texture_pro(tr.tex, src, dest, orig, rot_deg, draw_color)
			}

			if use_blend_add {
				rl.end_blend_mode()
			}
		} else {
			// zero-asset fallback
			if use_blend_add {
				rl.begin_blend_mode(int(rl.BlendMode.blend_additive))
			}
			rl.draw_circle_v(draw_pos, 4.0 * sx * s_mult, draw_color)
			if use_blend_add {
				rl.end_blend_mode()
			}
		}
	}
}

fn (mut e BurstEmitter) simulate(dt f32) {
	// advance each particle's t; swap-pop expired ones
	sign := if e.reverse { f32(-1.0) } else { f32(1.0) }

	mut i := 0
	for i < e.active {
		new_t := e.particles[i].t + sign * dt / e.particles[i].lifetime
		done := if e.reverse { new_t <= 0.0 } else { new_t >= 1.0 }

		if done {
			e.particles[i] = e.particles[e.active - 1]
			e.active--
			continue
		}

		e.particles[i].t = new_t
		i++
	}

	// emit finished signal once all particles from the last burst have expired
	if e.just_burst && e.active == 0 {
		e.just_burst = false
		// TODO: replace none/[] with app.wren_vm / app.wren_call_handles for Wren support
		e.signals.emit(sig_burst_finished, e, [], none, [])
	}
}

fn (mut e BurstEmitter) spawn_particle() {
	if e.active >= e.num_particles {
		return
	}

	// launch direction with spread
	base_angle := f32(math.atan2(f64(e.direction.y), f64(e.direction.x)))
	mut p_spread := (rand.f32() * 2.0 - 1.0) * e.spread

	if e.center_concentration > 0.0 {
		// exponential distribution concentrates particles toward the launch direction.
		// multiply the uniform spread by a sample that is small when lambda is large.
		exp_s := exponential_sample(e.center_concentration)
		p_spread *= math.min(exp_s, f32(1.0)) // clamp to prevent escape past spread edge
	}

	start_dir := base_angle + p_spread
	end_dir := start_dir + e.direction_rotation.sample()

	// max_distance attenuated by falloff_curve based on angular distance from centre
	mut max_dist := e.distance.sample()
	if fc := e.falloff_curve {
		// 0.0 = centre of arc, 1.0 = spread edge
		norm_spread := if e.spread > 0.001 {
			math.min(math.abs(p_spread) / e.spread, f32(1.0))
		} else {
			f32(0.0)
		}
		max_dist *= fc.sample(norm_spread)
	}

	// preprocess_amount: start already into the animation
	t_start := if e.reverse { f32(1.0) } else { e.preprocess_amount }

	mut max_angle := e.angle.sample()
	if e.randomly_flip_angle && rand.u32() % 2 == 0 {
		max_angle *= -1.0
	}

	e.particles[e.active] = BurstParticle{
		t:         t_start
		lifetime:  e.lifetime.sample()
		start_dir: start_dir
		end_dir:   end_dir
		max_dist:  max_dist
		max_angle: max_angle
		scale_mod: 1.0 - rand.f32() * e.image_scale_randomness
		co_hi:     e.color_offset_high
		co_lo:     e.color_offset_low
		offset:    e.offset
		color:     e.base_color
	}
	e.active++
}
