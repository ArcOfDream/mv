module graphics

import mv.thirdparty.gles2 as gl
import mv.util
import sdl
import mv.resource
import mv.math

const (
	max_triangles = 2048
)

[heap]
pub struct Renderer {
pub mut:
	projection    math.Mat32
	active_camera ?&Camera2D

	batches      []Batch
	active_batch int
	batch_amt    int
	total_verts  u32

	width       int
	height      int
	clear_color math.Vec4 = math.Vec4{0.1, 0.2, 0.5, 1.0}
	gl_context     sdl.GLContext
	default_shader resource.Shader
}

pub fn (ren Renderer) set_sdl_attributes() {
	sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.es))
	sdl.gl_set_attribute(.context_major_version, 2)
	sdl.gl_set_attribute(.context_minor_version, 0)
	sdl.gl_set_attribute(.doublebuffer, 1)
	sdl.gl_set_attribute(.depth_size, 16)
	sdl.gl_set_attribute(.stencil_size, 8)
}

pub fn (mut ren Renderer) create_sdl_window(width int, height int) !&sdl.Window {
	ren.width = width
	ren.height = height

	window_flags := u32(sdl.WindowFlags.opengl) | u32(sdl.WindowFlags.hidden)
	sdl_window := sdl.create_window(''.str, sdl.windowpos_undefined, sdl.windowpos_undefined,
		width, height, window_flags)
	if sdl_window == sdl.null {
		error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		error('Could not create SDL window, SDL says:\n${error_msg}')
	}

	ren.gl_context = sdl.gl_create_context(sdl_window)
	if ren.gl_context == sdl.null {
		error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		error('Could not create OpenGL context, SDL says:\n${error_msg}')
	}

	sdl.gl_make_current(sdl_window, ren.gl_context)

	// Enable VSYNC (Sync buffer swaps with monitors vertical refresh rate)
	if sdl.gl_set_swap_interval(1) < 0 {
		error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		error('Could not set OpenGL swap interval to vsync:\n${error_msg}')
	}

	return sdl_window
}

pub fn (mut ren Renderer) init() {
	ren.default_shader = util.load_default_shader()

	ren.batches = []Batch{len: 8, cap: 8, init: Batch{
		vbo: VertexBuffer.new(sdl.null, graphics.max_triangles * 3 * sizeof(RenderVertex))
		shader_id: ren.default_shader.id
		shader_ref: &ren.default_shader
		max_vertices: graphics.max_triangles * 3
		vertices: []RenderVertex{len: graphics.max_triangles * 3, cap: graphics.max_triangles * 3}
	}}
	ren.batch_amt = 8

	ren.projection = math.Mat32.ortho(ren.width, ren.height)
	ren.set_shader(ren.default_shader)
	
	gl.enable(.blend)
	gl.blend_func(.src_alpha, .one_minus_src_alpha)
}

pub fn (mut ren Renderer) free() {
	for batch in ren.batches {
		gl.delete_buffers(1, batch.vbo.id)
		gl.delete_program(batch.shader_id)
	}
}

pub fn (mut ren Renderer) clear_frame() {
	gl.viewport(0, 0, ren.width, ren.height)
	gl.clear_color(ren.clear_color.x, ren.clear_color.y, ren.clear_color.z, ren.clear_color.w)
	gl.clear(u32(gl.Flag.color_buffer_bit))
}

pub fn (mut ren Renderer) begin_frame() {
	ren.projection = math.Mat32.ortho(ren.width, ren.height)
	if mut cam := ren.active_camera {
		cam.update()
		ren.projection *= cam.view
	}
}

pub fn (mut ren Renderer) end_frame() {
	ren.flush_batch()
	ren.reset_shader()
	gl.bind_texture(.texture_2d, 0)
}

pub fn (mut ren Renderer) next_batch() {
	ren.active_batch++
	if ren.active_batch >= ren.batch_amt {
		ren.flush_batch()
		ren.active_batch = 0
	}
}

[direct_array_access]
pub fn (mut ren Renderer) flush_batch() {
	for mut batch in ren.batches {
		if batch.vertex_count == 0 {
			batch.active_texture = 0
			continue
		}
		gl.bind_texture(.texture_2d, batch.active_texture)

		batch.vbo.bind()

		gl.vertex_attrib_pointer(0, 2, .gl_float, 0, sizeof(RenderVertex), voidptr(__offsetof(RenderVertex, pos)))
		gl.enable_vertex_attrib_array(0)
		gl.vertex_attrib_pointer(1, 4, .gl_float, 0, sizeof(RenderVertex), voidptr(__offsetof(RenderVertex, color)))
		gl.enable_vertex_attrib_array(1)
		gl.vertex_attrib_pointer(2, 2, .gl_float, 0, sizeof(RenderVertex), voidptr(__offsetof(RenderVertex, uv)))
		gl.enable_vertex_attrib_array(2)
		
		gl.buffer_subdata(.array_buffer, 0, batch.vertex_count * sizeof(RenderVertex), &batch.vertices[0])
		
		if s := batch.shader_ref {
			s.use()
			ren.set_default_uniforms(s)
		
		}
		ren.total_verts += batch.vertex_count

		gl.draw_arrays(.triangles, 0, batch.vertex_count)

		batch.vertex_count = 0
		batch.active_texture = 0
		batch.shader_id = ren.default_shader.id
		batch.shader_ref = &ren.default_shader
	}
		ren.total_verts = 0
		

}

[direct_array_access]
pub fn (mut ren Renderer) push_triangle(apos math.Vec2, bpos math.Vec2, cpos math.Vec2, col math.Vec4, auv math.Vec2, buv math.Vec2, cuv math.Vec2, tex u32) {
	if tex != ren.batches[ren.active_batch].active_texture {
		if ren.batches[ren.active_batch].active_texture != 0 { ren.next_batch() }
		ren.batches[ren.active_batch].active_texture = tex
	}

	if ren.batches[ren.active_batch].vertex_count >= ren.batches[ren.active_batch].max_vertices {
		ren.next_batch()
	}

	pos := ren.batches[ren.active_batch].vertex_count
	ren.batches[ren.active_batch].vertices[pos + 0].pos = apos // Tri 1
	ren.batches[ren.active_batch].vertices[pos + 0].color = col
	ren.batches[ren.active_batch].vertices[pos + 0].uv = auv
	ren.batches[ren.active_batch].vertices[pos + 1].pos = bpos // Tri 2
	ren.batches[ren.active_batch].vertices[pos + 1].color = col
	ren.batches[ren.active_batch].vertices[pos + 1].uv = buv
	ren.batches[ren.active_batch].vertices[pos + 2].pos = cpos // Tri 3
	ren.batches[ren.active_batch].vertices[pos + 2].color = col
	ren.batches[ren.active_batch].vertices[pos + 2].uv = cuv

	ren.batches[ren.active_batch].vertex_count += 3
}

pub fn (mut ren Renderer) push_quad_uvs(pos math.Vec2, size math.Vec2, uv &math.Quad, tint math.Vec4, tex u32) {
	// vfmt off
	ren.push_triangle(
		math.Vec2{pos.x, pos.y},
		math.Vec2{pos.x + size.x, pos.y},
		math.Vec2{pos.x + size.x, pos.y +size.y},
		tint, uv.texcoords[0], uv.texcoords[1], uv.texcoords[2], tex
	)
	ren.push_triangle(
		math.Vec2{pos.x, pos.y},
		math.Vec2{pos.x, pos.y + size.y},
		math.Vec2{pos.x + size.x, pos.y + size.y},
		tint, uv.texcoords[0], uv.texcoords[3], uv.texcoords[2], tex
	)
	// vfmt on
}

pub fn (mut ren Renderer) push_quad(pos math.Vec2, size math.Vec2, tint math.Vec4, tex u32) {
	// vfmt off
	ren.push_triangle(
		math.Vec2{pos.x, pos.y},
		math.Vec2{pos.x + size.x, pos.y},
		math.Vec2{pos.x + size.x, pos.y +size.y},
		tint, math.Vec2{0, 0}, math.Vec2{1, 0}, math.Vec2{1, 1}, tex
	)
	ren.push_triangle(
		math.Vec2{pos.x, pos.y},
		math.Vec2{pos.x, pos.y + size.y},
		math.Vec2{pos.x + size.x, pos.y + size.y},
		tint, math.Vec2{0, 0}, math.Vec2{0, 1}, math.Vec2{1, 1}, tex
	)
	// vfmt on
}

pub fn (mut ren Renderer) push_quad_vertexes(v1 &RenderVertex, v2 &RenderVertex, v3 &RenderVertex, v4 &RenderVertex, tex u32) {
	// vfmt off
	ren.push_triangle(
		v1.pos, v2.pos, v3.pos,
		v1.color, v1.uv, v2.uv, v3.uv, tex
	)

	ren.push_triangle(
		v1.pos, v4.pos, v3.pos,
		v1.color, v1.uv, v4.uv, v3.uv, tex
	)
	// vfmt on
}

// since one cannot simply batch with shaders, we flush the batch and start over
// this is likely not the most efficient way to do this but it's not quite the end of the world either
pub fn (mut ren Renderer) set_shader(shd &resource.Shader) {
	if shd.id != ren.batches[ren.active_batch].shader_id {
		ren.next_batch()
		ren.batches[ren.active_batch].shader_id = shd.id
		unsafe {
			ren.batches[ren.active_batch].shader_ref = shd
		}
		if mut s := ren.batches[ren.active_batch].shader_ref {
			s.use()
			s.update_uniforms()
			return
		}
	}

	shd.use()
}

pub fn (mut ren Renderer) reset_shader() {
	if ren.default_shader.id != ren.batches[ren.active_batch].shader_id {
		ren.next_batch()
		ren.batches[ren.active_batch].shader_id = ren.default_shader.id
		unsafe {
			ren.batches[ren.active_batch].shader_ref = &ren.default_shader
		}
		if mut s := ren.batches[ren.active_batch].shader_ref {
			s.use()
			s.update_uniforms()
			return
		}
	}
}

[direct_array_access; inline]
pub fn (mut ren Renderer) set_default_uniforms(shd &resource.Shader) {
	shd.set_mat4(shd.uniforms['projection'], ren.projection.to_mat44())
	shd.set_int(shd.uniforms['tex'], int(ren.batches[ren.active_batch].active_texture))
}

fn check_for_error() {
	err := gl.get_error()

	if err != .no_error {
		print('Uh oh \n')
		match err {
			.invalid_enum { print('GL Invalid Enum\n') }
			.invalid_value { print('GL Invalid Value\n') }
			.invalid_operation { print(' GL Invalid Operation\n') }
			.out_of_memory { print('GL Out of Memory\n') }
			else { print('GL Unknown error\n') }
		}
	}
}
