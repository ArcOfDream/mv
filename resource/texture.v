module resource

import mv.thirdparty.gles2 as gl
import mv.math

[heap]
pub struct Texture {
pub:
	resource_type ResourceType = .image
pub mut:
	name string

	id           u32        // ID relative to the OpenGL texture
	flip         math.Vec2i = math.Vec2i{1, 1} // X/Y flip.
	tex_size     math.Vec2i // Size of the texture
	quad         math.Quad
	data         ?&TextureData
	image_format gl.Flag = gl.Flag.rgba
	wrap_s       gl.Flag = gl.Flag.repeat
	wrap_t       gl.Flag = gl.Flag.repeat
	filter_min   gl.Flag = gl.Flag.nearest
	filter_max   gl.Flag = gl.Flag.nearest
}

pub struct TextureData {
pub mut:
	pixels []u8
}

pub fn (mut t Texture) gen_id() {
	gl.gen_textures(1, &t.id)
}

pub fn (mut t Texture) generate_with(pixels voidptr, width int, height int, format gl.Flag) {
	t.tex_size = math.Vec2i{width, height}
	t.quad = math.Quad.new(0, 0, t.tex_size.x, t.tex_size.y, t.tex_size.x, t.tex_size.y)

	// create the texture
	gl.bind_texture(.texture_2d, t.id)

	gl.tex_parameteri(.texture_2d, .texture_wrap_s, int(t.wrap_s))
	gl.tex_parameteri(.texture_2d, .texture_wrap_t, int(t.wrap_t))
	gl.tex_parameteri(.texture_2d, .texture_min_filter, int(t.filter_min))
	gl.tex_parameteri(.texture_2d, .texture_mag_filter, int(t.filter_max))

	gl.tex_image2d(.texture_2d, 0, int(format), width, height, 0, format, .gl_unsigned_byte,
		pixels)
	// gl.tex_subimage2d(.texture_2d, 0, 0, 0, t.data.w, t.data.h, .rgba, .gl_unsigned_byte,
	// 	t.data.pixels)

	// can't forget to unbind
	gl.bind_texture(.texture_2d, 0)
}

pub fn (mut t Texture) bind() {
	gl.bind_texture(.texture_2d, t.id)
}
