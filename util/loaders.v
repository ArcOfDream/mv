module util

import os
import sdl.image
import sdl
import vqoi
import mv.thirdparty.gles2 as gl
import mv.resource as r
import mv.binary as b
import arrays

pub fn load_texture_raw_from_memory(pixels []u8, name string, width int, height int, format gl.Flag, keep_data bool) ?r.Texture {
	if pixels.len == 0 {
		return none
	}

	mut t := r.Texture{
		name: name
	}
	t.gen_id()
	t.generate_with(pixels.data, width, height, format)

	if keep_data {
		t.data = &r.TextureData{pixels.clone()}
	}

	return t
}

pub fn load_texture_file(path string, name string, keep_data bool) ?r.Texture {
	if !os.exists(path) {
		return none
	}
	file := sdl.rw_from_file(path.str, 'r'.str)
	if isnil(file) {
		return none
	}
	img := image.load_rw(file, 1)
	if isnil(img) {
		return none
	}
	mut format := gl.Flag.rgba
	mut channels := 0

	match img.format.Amask {
		0 {
			format = .rgb
			channels = 3
		}
		else {
			format = .rgba
			channels = 4
		}
	}

	mut t := r.Texture{
		name: name
	}
	t.gen_id()
	t.generate_with(img.pixels, img.w, img.h, format)

	if keep_data {
		mut pixels := unsafe { arrays.carray_to_varray[u8](img.pixels, img.w * img.h * channels) }
		t.data = &r.TextureData{pixels}
	}

	sdl.free_surface(img)

	return t
}

pub fn load_texture_qoi(path string, name string, keep_data bool) ?r.Texture {
	if !os.exists(path) {
		return none
	}
	file := (os.read_file(path)!).bytes()
	mut img := vqoi.decode(file) or { return none }
	mut format := gl.Flag.rgba4

	match img.metadata.channels {
		.rgb { format = .rgb }
		.rgba { format = .rgba }
	}
	println('qoi image width ${img.metadata.width}, height ${img.metadata.height}, format ${img.metadata.channels}')

	mut t := r.Texture{
		// data: sdl.null
		name: name
	}

	if keep_data {
		mut pixel_data := []u8{}
		for pixel in img.rgba {
			for i in pixel {
				pixel_data << i
			}
		}
		t.data = &r.TextureData{pixel_data}
	}

	t.gen_id()
	t.generate_with(img.rgba.data, int(img.metadata.width), int(img.metadata.height),
		format)
	return t
}

pub fn load_default_texture() r.Texture {
	file := sdl.rw_from_const_mem(&b.default_png, b.default_png_len)
	img := image.load_rw(file, 1)
	mut t := r.Texture{
		// data: sdl.null
		name: 'default'
	}
	t.gen_id()
	t.generate_with(img.pixels, img.w, img.h, .rgba)
	sdl.free_surface(img)

	return t
}

pub fn load_shader_from_file(vpath string, fpath string, name string) ?r.Shader {
	if !os.exists(vpath) || !os.exists(fpath) {
		return none
	}

	vsrc := os.read_file(vpath) or {
		println('Vertex shader file not found for ${name}!')
		return none
	}
	fsrc := os.read_file(fpath) or {
		println('Fragment shader file not found for ${name}!')
		return none
	}

	return load_shader_from_source(vsrc, fsrc, name)
}

pub fn load_shader_from_source(v string, f string, name string) r.Shader {
	mut vid := u32(0)
	mut fid := u32(0)
	mut pid := u32(0)

	vid = load_shader(v, .vertex_shader)
	fid = load_shader(f, .fragment_shader)
	pid = link_shader_program(vid, fid)

	mut shd := r.Shader{
		name: name
		id: pid
	}

	return shd
}

pub fn load_default_shader() r.Shader {
	mut vid := u32(0)
	mut fid := u32(0)
	mut pid := u32(0)

	vid = load_shader(b.vertex_shader, .vertex_shader)
	fid = load_shader(b.fragment_shader, .fragment_shader)
	pid = link_shader_program(vid, fid)

	mut shd := r.Shader{
		name: 'shd_default'
		id: pid
	}
	shd.add_uniform('projection', .mat4)
	shd.add_uniform('view', .mat4)
	shd.add_uniform('tex', .int)

	return shd
}
