module graphics

import mv.thirdparty.fons as fontstash
import mv.thirdparty.gles2 as gl
import mv.math
import arrays

// TTF text renderer based on Fontstash. Currently able to provide basic functionality.
[heap]
pub struct FontRender {
pub mut:
	width  int
	height int

	fonts    map[string]int
	ctx      ?&fontstash.Context
	renderer ?&Renderer
mut:
	active_color math.Vec4 = math.Vec4{1, 1, 1, 1}
	// active_color_u32 math.Color = math.Color.white()
	tid u32
}

pub fn (mut fon FontRender) setup_context() {
	mut conf := C.FONSparams{
		width: fon.width
		height: fon.height
		flags: u8(fontstash.Flags.top_left)
		userPtr: &fon
		renderCreate: atlas_create
		renderResize: atlas_create // the GL3 header for fontstash just defines a function that calls the create func again
		renderUpdate: atlas_update
		// renderDraw: render_draw // for some reason that i couldn't figure out, this will always draw only half of the text
		renderDelete: atlas_delete
		pushQuad: push_quad
	}
	c := fontstash.create_internal(conf)
	// assert !isnil(c)
	fon.ctx = c
}

[inline]
pub fn (mut fon FontRender) set_font(name string) {
	if fons := fon.ctx {
		fons.set_font(fon.fonts[name])
	}
}

[inline]
pub fn (mut fon FontRender) set_color(col math.Vec4) {
	fon.active_color = col
}

[inline]
pub fn (mut fon FontRender) set_size(size f32) {
	if fons := fon.ctx {
		fons.set_size(size)
	}
}

[inline]
pub fn (mut fon FontRender) set_alignment(a fontstash.Align) {
	if fons := fon.ctx {
		fons.set_alignment(a)
	}
}

[inline]
pub fn (mut fon FontRender) draw_string(x f32, y f32, str string) {
	if fons := fon.ctx {
		fons.draw_text(x, y, str)
	}
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

fn atlas_update(fr &FontRender, rect &int, data &u8) {
	r := unsafe { arrays.carray_to_varray[int](rect, 4) }
	// w := r[2] - r[0]
	h := r[3] - r[1]
	// println('x: ${r[0]}, y: ${r[1]}, w: ${w}, h: ${h}|${math.ceilpow2_int(h)}')

	// gl.pixel_storei(.unpack_alignment, 1)
	gl.bind_texture(.texture_2d, fr.tid)
	gl.tex_subimage2d(.texture_2d, 0, 0, 0, fr.width, math.ceilpow2_int(h - 16), .luminance_alpha,
		.gl_unsigned_byte, data)
}

fn atlas_delete(mut fr FontRender) {
	fr.delete_tex()
}

fn render_draw(mut fr FontRender, verts &f32, tcoords &f32, colors &u32, nverts int) {
	if mut renderer := fr.renderer {
		// v := unsafe { arrays.carray_to_varray[f32](verts, nverts * 2) } // vertex coordinates
		// tc := unsafe { arrays.carray_to_varray[f32](tcoords, nverts * 2) } // texture coordinates
		// c := unsafe { arrays.carray_to_varray[u32](colors, nverts) }
		// TODO: text colors

		mut n := 0
		for n < nverts {
			unsafe {
				// vfmt off
				renderer.push_triangle(
					math.Vec2{verts[n+0], verts[n+1]},
					math.Vec2{verts[n+4], verts[n+5]},
					math.Vec2{verts[n+2], verts[n+3]},
					fr.active_color,
					math.Vec2{tcoords[n+0]*0.5, tcoords[n+1]*0.5},
					math.Vec2{tcoords[n+4]*0.5, tcoords[n+5]*0.5},
					math.Vec2{tcoords[n+2]*0.5, tcoords[n+3]*0.5},
					fr.tid
				)
				renderer.push_triangle(
					math.Vec2{verts[n+6], verts[n+7]},
					math.Vec2{verts[n+10], verts[n+11]},
					math.Vec2{verts[n+8], verts[n+9]},
					fr.active_color,
					math.Vec2{tcoords[n+6]*0.5, tcoords[n+7]*0.5},
					math.Vec2{tcoords[n+10]*0.5, tcoords[n+11]*0.5},
					math.Vec2{tcoords[n+8]*0.5, tcoords[n+9]*0.5},
					fr.tid
				)
				// vfmt on
			}
			n += 6
		}
	}
}

fn push_quad(mut fr FontRender, q &fontstash.Quad) {
	if mut renderer := fr.renderer {
		// vfmt off
		renderer.push_triangle(
			math.Vec2{q.x0*0.5, q.y0*0.5},
			math.Vec2{q.x1*0.5 q.y0*0.5},
			math.Vec2{q.x1*0.5, q.y1*0.5},
			fr.active_color,
			math.Vec2{q.s0*0.5, q.t0*0.5},
			math.Vec2{q.s1*0.5, q.t0*0.5},
			math.Vec2{q.s1*0.5, q.t1*0.5},
			fr.tid
		)
		renderer.push_triangle(
			math.Vec2{q.x0*0.5, q.y0*0.5},
			math.Vec2{q.x0*0.5, q.y1*0.5},
			math.Vec2{q.x1*0.5, q.y1*0.5},
			fr.active_color,
			math.Vec2{q.s0*0.5, q.t0*0.5},
			math.Vec2{q.s0*0.5, q.t1*0.5},
			math.Vec2{q.s1*0.5, q.t1*0.5},
			fr.tid
		)
		// vfmt on
	}
}
