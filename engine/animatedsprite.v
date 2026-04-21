module engine

import raylib as rl
import math
import core { Vec2 }
import resourcemanager { Handle, TextureResource }

@[heap]
pub struct AnimatedSprite {
	Node
pub mut:
	frames   ?&SpriteFrames
	autoplay string

	centered bool = true
	offset   Vec2
	flip_h   bool
	flip_v   bool
	tint     rl.Color = rl.white

	speed_scale f32 = 1.0
mut:
	current_animation string
	current_frame     int
	elapsed           f32
	playing           bool
	pp_reverse        bool

	// one cached handle per unique texture_id seen during playback.
	tex_cache map[string]Handle[TextureResource]
}

pub fn AnimatedSprite.instantiate(app &App, name string) &AnimatedSprite {
	return &AnimatedSprite{
		Node: Node{
			app:           app
			node_name:     name
			scale:         Vec2{1, 1}
			process_flags: .transform | .draw
		}
	}
}

pub fn AnimatedSprite.new(app &App, name string) &AnimatedSprite {
	return &AnimatedSprite{
		Node: Node{
			app:           app
			node_name:     name
			scale:         Vec2{1, 1}
			process_flags: .transform | .draw
		}
	}
}

fn (n &AnimatedSprite) wren_class_name() string {
	return 'AnimatedSprite'
}

// unload releases every cached texture handle. called by the tree on node
// removal; also safe to call manually before reassigning SpriteFrames.
pub fn (mut s AnimatedSprite) unload() {
	for key, _ in s.tex_cache {
		mut h := s.tex_cache[key] or { continue }
		h.release()
	}
	s.tex_cache.clear()
}

// --- playback API ---

pub fn (mut s AnimatedSprite) play(anim_name string) {
	if sf := s.frames {
		if !sf.has_animation(anim_name) {
			return
		}
	} else {
		return
	}

	// reset state only when switching to a different animation
	if s.current_animation != anim_name {
		s.current_animation = anim_name
		s.current_frame = 0
		s.elapsed = 0
		s.pp_reverse = false
	}
	s.playing = true
}

pub fn (mut s AnimatedSprite) stop() {
	s.playing = false
	s.current_frame = 0
	s.elapsed = 0
	s.pp_reverse = false
}

pub fn (mut s AnimatedSprite) pause() {
	s.playing = false
}

@[inline]
pub fn (s &AnimatedSprite) is_playing() bool {
	return s.playing
}

pub fn (mut s AnimatedSprite) set_frame(frame int) {
	if sf := s.frames {
		count := sf.get_frame_count(s.current_animation)
		s.current_frame = if count > 0 { frame % count } else { 0 }
		s.elapsed = 0
	}
}

@[inline]
pub fn (s &AnimatedSprite) get_frame() int {
	return s.current_frame
}

@[inline]
pub fn (s &AnimatedSprite) get_animation() string {
	return s.current_animation
}

// --- texture handle API ---

pub fn (mut s AnimatedSprite) get_texture_handle(texture_id string) ?Handle[TextureResource] {
	return s.resolve_handle(texture_id)
}

@[inline]
pub fn (mut s AnimatedSprite) get_texture(texture_id string) ?&TextureResource {
	h := s.resolve_handle(texture_id) or { return none }
	return h.get()
}

pub fn (mut s AnimatedSprite) set_texture_id(texture_id string) !Handle[TextureResource] {
	h := s.resolve_handle(texture_id) or { return error('texture not found: ${texture_id}') }
	return h
}

pub fn (mut s AnimatedSprite) set_texture_handle(texture_id string, h Handle[TextureResource]) {
	if old := s.tex_cache[texture_id] {
		mut release_me := old
		release_me.release()
	}
	s.tex_cache[texture_id] = h
}

pub fn (mut s AnimatedSprite) invalidate_texture(texture_id string) {
	if h := s.tex_cache[texture_id] {
		mut release_me := h
		release_me.release()
		s.tex_cache.delete(texture_id)
	}
}

// --- internal ---

// resolve_handle returns a valid Handle for texture_id, re-fetching from the
// resource manager if the cache is cold or the cached handle is stale.
fn (mut s AnimatedSprite) resolve_handle(texture_id string) ?Handle[TextureResource] {
	if h := s.tex_cache[texture_id] {
		if h.is_valid() {
			return h
		}
	}
	if h := s.app.textures.get_handle(texture_id) {
		s.tex_cache[texture_id] = h
		return h
	}
	return none
}

// --- frame advancement ---

fn (mut s AnimatedSprite) advance_frame(anim &SpriteAnimation) {
	n := anim.frames.len
	if n <= 1 {
		if anim.loop_mode == .none {
			s.playing = false
			s.emit_signal('animation_finished')
		}
		return
	}

	match anim.loop_mode {
		.none {
			if s.current_frame < n - 1 {
				s.current_frame++
			} else {
				s.playing = false
				s.emit_signal('animation_finished')
			}
		}
		.loop {
			s.current_frame = (s.current_frame + 1) % n
			if s.current_frame == 0 {
				s.emit_signal('animation_looped')
			}
		}
		.ping_pong {
			if s.pp_reverse {
				s.current_frame--
				if s.current_frame <= 0 {
					s.current_frame = 0
					s.pp_reverse = false
					s.emit_signal('animation_looped')
				}
			} else {
				s.current_frame++
				if s.current_frame >= n - 1 {
					s.current_frame = n - 1
					s.pp_reverse = true
				}
			}
		}
	}
}

// --- node overrides ---

fn (mut s AnimatedSprite) ready_internal() {
	if s.autoplay != '' {
		s.play(s.autoplay)
	}
}

fn (mut s AnimatedSprite) update_internal(dt f32) {
	if !s.playing {
		return
	}
	sf := s.frames or { return }
	anim := sf.get_animation(s.current_animation) or { return }
	if anim.frames.len == 0 || anim.fps <= 0 {
		return
	}

	s.elapsed += dt * s.speed_scale
	frame_duration := 1.0 / anim.fps
	for s.elapsed >= frame_duration {
		s.elapsed -= frame_duration
		s.advance_frame(&anim)
		if !s.playing {
			break
		}
	}
}

fn (mut s AnimatedSprite) draw_internal() {
	sf := s.frames or { return }
	anim := sf.get_animation(s.current_animation) or { return }
	if anim.frames.len == 0 {
		return
	}

	frame := anim.frames[s.current_frame]
	h := s.resolve_handle(frame.texture_id) or { return }
	t := h.get() or { return }

	mut src := frame.source
	if s.flip_h {
		src.width = -src.width
	}
	if s.flip_v {
		src.height = -src.height
	}

	w := math.abs(src.width)
	h_size := math.abs(src.height)

	mut origin := s.offset
	if s.centered {
		origin += Vec2{w * 0.5, h_size * 0.5}
	}

	dst := rl.Rectangle{0, 0, w, h_size}

	rl.begin_blend_mode(int(t.blend_mode))
	rl.draw_texture_pro(t.tex, src, dst, origin, 0, s.tint)
	rl.end_blend_mode()
}
