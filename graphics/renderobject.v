module graphics

import mv.math
import mv.resource

// pub interface Renderable {
// 	draw_texture(resource.Texture, math.Vec2, math.Vec2, math.Vec4)
// }

pub struct RenderObject {
pub mut:
	renderer ?&Renderer
	shader   ?&resource.Shader
	visible  bool
mut:
	vertex    [4]RenderVertex
	transform math.Mat32 = math.Mat32.identity()
}

pub fn (mut r RenderObject) draw_texture(tex_id u32, pos math.Vec2, size math.Vec2, color math.Vec4) {
	if mut ren := r.renderer {
		if s := r.shader {
			ren.set_shader(s)
		}
		ren.push_quad(pos, size, color, tex_id)
	}
}

pub fn (mut r RenderObject) draw_texture_uvs(tex_id u32, tex_uvs math.Quad, pos math.Vec2, size math.Vec2, color math.Vec4) {
	if mut ren := r.renderer {
		if s := r.shader {
			ren.set_shader(s)
		}
		ren.push_quad_uvs(pos, size, tex_uvs, color, tex_id)
	}
}

[inline]
pub fn (mut r RenderObject) update_vertex_color(color math.Vec4) {
	for mut v in r.vertex {
		v.color = color
	}
}

[inline]
pub fn (mut r RenderObject) update_vertex_pos(pos math.Vec2, size math.Vec2i) {
	r.vertex[0].pos = math.Vec2{pos.x, pos.y}
	r.vertex[1].pos = math.Vec2{pos.x + size.x, pos.y}
	r.vertex[2].pos = math.Vec2{pos.x + size.x, pos.y + size.y}
	r.vertex[3].pos = math.Vec2{pos.x, pos.y + size.y}
}

[inline]
pub fn (mut r RenderObject) update_vertex_uv(tex &resource.Texture) {
	r.vertex[0].uv = tex.quad.texcoords[0]
	r.vertex[1].uv = tex.quad.texcoords[1]
	r.vertex[2].uv = tex.quad.texcoords[2]
	r.vertex[3].uv = tex.quad.texcoords[3]
}

[inline]
pub fn (mut r RenderObject) apply_transform(size math.Vec2, pos math.Vec2, rotation f32, scale math.Vec2) {
	r.transform = math.Mat32.identity()
	r.transform.set_transform(pos.x, pos.y, rotation, scale.x, scale.y, pos.x, pos.y)
	for mut v in r.vertex {
		x := v.pos.x * r.transform.data[0] + v.pos.y * r.transform.data[2] + r.transform.data[4]
		y := v.pos.x * r.transform.data[1] + v.pos.y * r.transform.data[3] + r.transform.data[5]

		v.pos.x = x
		v.pos.y = y
	}
}

// TODO: make some basic drawn primitive routines
