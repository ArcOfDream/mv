module mv

import raylib as rl
import resourcemanager { Handle, ShaderResource, TextureResource }

@[heap]
pub struct Sprite {
	Node
mut:
	centered   bool = true
	offset     Vec2
	texture_id string
	shader_id  string
	tint       rl.Color = rl.white
	texture    Handle[TextureResource]
	shader     Handle[ShaderResource]
pub mut:
	h_frames      int = 1
	v_frames      int = 1
	current_frame int
}

pub fn Sprite.new(app &App, name string, texture_id ?string) &Sprite {
	mut spr := &Sprite{
		app:       app
		node_name: name
	}
	if tex := texture_id {
		spr.set_texture_id(tex)
	}

	return spr
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

pub fn (s &Sprite) get_texture_handle() Handle[TextureResource] {
	return s.texture
}

@[inline]
pub fn (s &Sprite) get_texture() ?TextureResource {
	return s.app.textures.get(s.texture)
}

pub fn (mut s Sprite) set_texture_id(val string) {
	s.texture_id = val
	if handle := s.app.textures.get_handle(val) {
		s.texture = handle
		println('texture set to ${val}')
	}
}

pub fn (s &Sprite) get_shader_handle() Handle[ShaderResource] {
	return s.shader
}

@[inline]
pub fn (s &Sprite) get_shader() ?ShaderResource {
	return s.app.shaders.get(s.shader)
}

pub fn (mut s Sprite) set_shader_id(val string) {
	s.shader_id = val
	if handle := s.app.shaders.get_handle(val) {
		s.shader = handle
		println('shader set to ${val}')
	}
}

pub fn (s &Sprite) get_shader_id() string {
	return s.shader_id
}

@[inline]
fn (s &Sprite) get_source_rect(res &TextureResource) rl.Rectangle {
	frame_w := res.tex.width / s.h_frames
	frame_h := res.tex.height / s.v_frames

	// vfmt off
	return rl.Rectangle{
		(s.current_frame % s.h_frames) * frame_w,
		(s.current_frame / s.v_frames) * frame_h,
		frame_w, frame_h
	}
	// vfmt on
}

@[inline]
fn (s &Sprite) draw_sprite_internal(t &TextureResource) {
	mut origin := s.offset
	src := s.get_source_rect(t)

	if s.centered {
		origin += Vec2{src.width * 0.5, src.height * 0.5}
	}

	dst := rl.Rectangle{0, 0, src.width, src.height}
	rl.draw_texture_pro(t.tex, src, dst, origin, 0, s.tint)
}

fn (mut s Sprite) draw_internal() {
	if t := s.get_texture() {
		s.draw_sprite_internal(t)
	} else if th := s.app.textures.get_handle(s.texture_id) {
		s.texture = th
		if t := s.get_texture() {
			s.draw_sprite_internal(t)
		}
	}
}
