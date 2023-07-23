module main

import fontstash
import mv.thirdparty.gles2 as gl
import mv.graphics
import mv.math
import arrays

// #flag -lfreetype

// FontRender
[heap]
struct FontRender {
pub mut:
	width  int
	height int

	fonts map[string]int
	ctx   ?&fontstash.Context
mut:
	active_color     math.Vec4  = math.Vec4{0, 1, 1, 1}
	active_color_u32 math.Color = math.Color.white()
	renderer         ?&graphics.Renderer
	tid              u32
}

fn (mut fon FontRender) setup_context() {
	mut conf := C.FONSparams{
		width: fon.width
		height: fon.height
		flags: u8(fontstash.Flags.top_left)
		userPtr: &fon
		renderCreate: atlas_create
		renderResize: atlas_create // the GL3 header for fontstash just defines a function that calls the create func again
		renderUpdate: atlas_update
		renderDraw: render_draw
		renderDelete: atlas_delete
	}
	c := fontstash.create_internal(conf)
	// assert !isnil(c)
	fon.ctx = c
}

[inline]
fn (mut fon FontRender) delete_tex() {
	if fon.tid != 0 {
		gl.delete_textures(1, fon.tid)
		fon.tid = 0
	}
}

fn atlas_create(mut fr FontRender, width int, height int) int {
	fr.delete_tex()
	fr.width = width
	fr.height = height
	gl.gen_textures(1, &fr.tid)

	gl.bind_texture(.texture_2d, fr.tid)
	gl.tex_image2d(.texture_2d, 0, int(gl.Flag.luminance_alpha), fr.width, fr.height,
		0, .luminance_alpha, .gl_unsigned_byte, unsafe { nil })
	gl.tex_parameteri(.texture_2d, .texture_min_filter, int(gl.Flag.linear))
	gl.tex_parameteri(.texture_2d, .texture_mag_filter, int(gl.Flag.nearest))

	return 1
}

// fn atlas_resize(mut fr &FontRender, width int, height int) int {
// 	atlas_create(fr, width, height)
// 	return 0
// }

[live]
fn atlas_update(fr &FontRender, rect &int, data &u8) {
	r := unsafe { arrays.carray_to_varray[int](rect, 4) }
	w := r[2] - r[0]
	h := r[3] - r[1]
	println('x: ${r[0]}, y: ${r[1]}, w: ${w}, h: ${h}|${math.ceilpow2_int(h)}')

	// gl.pixel_storei(.unpack_alignment, 1)
	gl.bind_texture(.texture_2d, fr.tid)
	gl.tex_subimage2d(.texture_2d, 0, 0, 0, fr.width, math.ceilpow2_int(h), .luminance_alpha,
		.gl_unsigned_byte, data)
}

fn atlas_delete(mut fr FontRender) {
	fr.delete_tex()
}

[live]
fn render_draw(mut fr FontRender, verts &f32, tcoords &f32, colors &u32, nverts int) {
	if mut renderer := fr.renderer {
		v := unsafe { arrays.carray_to_varray[f32](verts, nverts * 2) } // vertex coordinates
		tc := unsafe { arrays.carray_to_varray[f32](tcoords, nverts * 2) } // texture coordinates
		c := unsafe { arrays.carray_to_varray[u32](colors, nverts) }
		// TODO: text colors

		mut n := 0
		for n < nverts {
			if fr.active_color_u32.value != c[n] {
				fr.active_color_u32.value = c[n]
				fr.active_color.x = fr.active_color_u32.r()
				fr.active_color.y = fr.active_color_u32.g()
				fr.active_color.z = fr.active_color_u32.b()
				fr.active_color.w = fr.active_color_u32.a()
			}
			// vfmt off
			renderer.push_triangle(
				math.Vec2{v[n+0], v[n+1]},
				math.Vec2{v[n+2], v[n+3]},
				math.Vec2{v[n+4], v[n+5]},
				fr.active_color,
				math.Vec2{tc[n+0]*0.5, tc[n+1]*0.5},
				math.Vec2{tc[n+2]*0.5, tc[n+3]*0.5},
				math.Vec2{tc[n+4]*0.5, tc[n+5]*0.5},
				fr.tid
			)
			renderer.push_triangle(
				math.Vec2{v[n+6], v[n+7]},
				math.Vec2{v[n+10], v[n+11]},
				math.Vec2{v[n+8], v[n+9]},
				fr.active_color,
				math.Vec2{tc[n+6]*0.5, tc[n+7]*0.5},
				math.Vec2{tc[n+10]*0.5, tc[n+11]*0.5},
				math.Vec2{tc[n+8]*0.5, tc[n+9]*0.5},
				fr.tid
			)
			// vfmt on
			n += 6
		}
	}
}
