module engine

import raylib as rl
import core { Vec2 }
import resourcemanager { Handle, ShaderResource, TextureResource }
import math
import os

@[heap]
pub struct Sprite {
	Node
mut:
	centered bool = true
	offset   Vec2
	texture  Handle[TextureResource]
	shader   Handle[ShaderResource]
pub mut:
	tint          rl.Color = rl.white
	h_frames      int      = 1
	v_frames      int      = 1
	flip_h        bool
	flip_v        bool
	current_frame int
}

pub fn Sprite.instantiate(app &App, name string) &Sprite {
	return &Sprite{
		app:       app
		node_name: name
	}
}

pub fn Sprite.new(app &App, name string, texture_id ?string) &Sprite {
	mut spr := Sprite.instantiate(app, name)
	if tex := texture_id {
		spr.set_texture_id(tex) or {}
	}
	return spr
}

fn (n &Sprite) wren_class_name() string {
	return 'Sprite'
}

// unload is the teardown hook - every handle field gets released here.
// If Sprite embeds other resource handles in the future, release them here too.
pub fn (mut s Sprite) unload() {
	s.texture.release()
	s.shader.release()
}

pub fn (s &Sprite) get_centered() bool {
	return s.centered
}

pub fn (mut s Sprite) set_centered(value bool) {
	s.centered = value
}

pub fn (s &Sprite) get_offset() Vec2 {
	return s.offset
}

pub fn (mut s Sprite) set_offset(val Vec2) {
	s.offset = val
}

// --- texture ---

pub fn (s &Sprite) get_texture_handle() Handle[TextureResource] {
	return s.texture
}

@[inline]
pub fn (s &Sprite) get_texture() ?&TextureResource {
	return s.texture.get()
}

// set_texture_id releases the current handle and acquires a new one by name.
// Returns an error if the name doesn't resolve - the sprite is left with an
// invalid handle in that case (caller can inspect and recover, or leave it).
pub fn (mut s Sprite) set_texture_id(val string) !Handle[TextureResource] {
	s.texture.release()
	s.texture = s.app.textures.get_handle(val) or {
		s.app.textures.load(val, val) or {
			s.texture = Handle[TextureResource]{}
			return error('texture not found: ${val}')
		}
	}
	return s.texture
}

// set_texture_handle takes ownership of a handle the caller already has.
// The caller is expected to have either just acquired it (load/get_handle)
// or cloned it. Sprite becomes the owner and will release on teardown.
pub fn (mut s Sprite) set_texture_handle(h Handle[TextureResource]) {
	s.texture.release()
	s.texture = h
}

pub fn (s &Sprite) get_texture_id() ?string {
	if !s.texture.is_valid() {
		return none
	}
	return s.app.textures.name_of(s.texture.id)
}

// --- shader ---

pub fn (s &Sprite) get_shader_handle() Handle[ShaderResource] {
	return s.shader
}

@[inline]
pub fn (s &Sprite) get_shader() ?&ShaderResource {
	return s.shader.get()
}

pub fn (mut s Sprite) set_shader_id(val string) !Handle[ShaderResource] {
	s.shader.release()
	s.shader = s.app.shaders.get_handle(val) or {
		ext := os.file_ext(val).to_lower()
		vs := if ext in ['.vert', '.vs'] { val } else { '' }
		fs := if ext in ['.frag', '.fs', '.glsl'] { val } else { '' }
		s.app.shaders.load(val, vs, fs) or {
			s.shader = Handle[ShaderResource]{}
			return error('shader not found: ${val}')
		}
	}
	return s.shader
}

pub fn (mut s Sprite) set_shader_handle(h Handle[ShaderResource]) {
	s.shader.release()
	s.shader = h
}

pub fn (s &Sprite) get_shader_id() ?string {
	if !s.shader.is_valid() {
		return none
	}
	return s.app.shaders.name_of(s.shader.id)
}

// --- draw ---

@[inline]
fn (s &Sprite) get_source_rect(res &TextureResource) rl.Rectangle {
	hf := if s.h_frames > 0 { s.h_frames } else { 1 }
	vf := if s.v_frames > 0 { s.v_frames } else { 1 }
	frame_w := res.tex.width / hf
	frame_h := res.tex.height / vf

	fx := (s.current_frame % hf) * frame_w
	fy := (s.current_frame / vf) * frame_h

	// vfmt off
	    return rl.Rectangle{
	        fx,
	        fy,
	        if s.flip_h { -frame_w } else { frame_w },
	        if s.flip_v { -frame_h } else { frame_h },
	    }
	// vfmt on
}

@[inline]
fn (s &Sprite) draw_sprite_internal(t &TextureResource) {
	mut origin := s.offset
	src := s.get_source_rect(t)

	if s.centered {
		origin += Vec2{math.abs(src.width) * 0.5, math.abs(src.height) * 0.5}
	}

	dst := rl.Rectangle{0, 0, math.abs(src.width), math.abs(src.height)}
	rl.draw_texture_pro(t.tex, src, dst, origin, 0, s.tint)
}

fn (mut s Sprite) draw_internal() {
	t := s.texture.get() or { return }
	rl.begin_blend_mode(int(t.blend_mode))
	s.draw_sprite_internal(t)
	rl.end_blend_mode()
}
