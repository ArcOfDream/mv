module graphics

import mv.thirdparty.gles2 as gl

pub struct VertexBuffer {
mut:
	id u32
}

pub fn VertexBuffer.new(data voidptr, size u32) VertexBuffer {
	mut v := VertexBuffer{}

	gl.gen_buffers(1, &v.id)
	gl.bind_buffer(.array_buffer, v.id)
	gl.buffer_data(.array_buffer, size, data, .dynamic_draw)

	return v
}

pub fn (v VertexBuffer) bind() {
	gl.bind_buffer(.array_buffer, v.id)
}

pub fn (v VertexBuffer) unbind() {
	gl.bind_buffer(.array_buffer, 0)
}
