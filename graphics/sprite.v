module graphics

import mv.math
import mv.resource
import mv.node

pub interface Updateable {
	update(f32)
}

pub struct Sprite {
	node.Node
	RenderObject
pub mut:
	position      math.Vec2
	offset        math.Vec2
	center_sprite bool      = true
	scale         math.Vec2 = math.Vec2{1, 1}
	tint          math.Vec4 = math.Vec4{1, 1, 1, 1}
	angle         f32
mut:
	texture ?&resource.Texture
}

[params]
pub struct SpriteConfig {
	renderer      &Renderer
	shader        ?&resource.Shader
	position      math.Vec2
	offset        math.Vec2
	center_sprite bool      = true
	scale         math.Vec2 = math.Vec2{1, 1}
	tint          math.Vec4 = math.Vec4{1, 1, 1, 1}
	angle         f32
	texture       ?&resource.Texture
}

pub fn Sprite.new(conf SpriteConfig) &Sprite {
	mut s := &Sprite{
		renderer: conf.renderer
		shader: conf.shader
		position: conf.position
		offset: conf.offset
		center_sprite: conf.center_sprite
		scale: conf.scale
		tint: conf.tint
		angle: conf.angle
	}
	if t := conf.texture {
		s.texture = t
	}
	if shd := conf.shader {
		s.shader = shd
	}
	s.update_vertex()

	return s
}

pub fn (mut s Sprite) update_vertex() {
	s.update_vertex_color(s.tint)
	if tex := s.texture {
		s.update_vertex_pos(s.position, tex.tex_size)
		s.update_vertex_uv(tex)
	}
}

pub fn (mut spr Sprite) set_texture(tex &resource.Texture) {
	spr.texture = tex
	spr.update_vertex_uv(tex)
}

pub fn (mut spr Sprite) draw_self() {
	spr.update_vertex_color(spr.tint)

	mut final_pos := spr.position - spr.offset

	if tex := spr.texture {
		if spr.center_sprite {
			final_pos -= tex.tex_size.as_vec2().mul(0.5)
		}
		spr.update_vertex_pos(final_pos, tex.tex_size)
		spr.apply_transform(tex.tex_size.as_vec2(), spr.position, spr.angle, spr.scale)
		if mut renderer := spr.renderer {
			renderer.push_quad_vertexes(spr.vertex[0], spr.vertex[1], spr.vertex[2], spr.vertex[3],
				tex.id)
		}
	}
}
