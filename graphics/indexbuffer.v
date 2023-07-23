module graphics

import mv.thirdparty.gles2 as gl

pub struct IndexBuffer {
mut:
	id    u32
	count u32
}

pub fn IndexBuffer.new(data voidptr, count u32) IndexBuffer {
	mut i := IndexBuffer{}

	gl.gen_buffers(1, &i.id)
	gl.bind_buffer(.element_array_buffer, i.id)
	gl.buffer_data(.element_array_buffer, count * sizeof(u32), data, .dynamic_draw)

	return i
}

pub fn (i IndexBuffer) bind() {
	gl.bind_buffer(.array_buffer, i.id)
}

pub fn (i IndexBuffer) unbind() {
	gl.bind_buffer(.array_buffer, 0)
}
