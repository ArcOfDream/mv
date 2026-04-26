module engine

import os
import mv.typeinfo
import rres
import core
import raylib as rl

// --- Gradient ---

pub fn load_gradient_from_file(path string) !core.Gradient {
	src := os.read_file(path)!
	return decode_gradient_json(src)
}

pub fn load_gradient_from_rres(loader &rres.RresLoader, key string) !core.Gradient {
	chunk := loader.load_single(key) or { return error('gradient chunk not found: ${key}') }
	defer { chunk.unload() }
	data_ptr, size := rres.load_data_from_resource(chunk)
	if data_ptr == unsafe { nil } || size == 0 {
		return error('gradient chunk empty: ${key}')
	}
	mut buf := []u8{len: int(size)}
	unsafe { C.memcpy(buf.data, data_ptr, usize(size)) }
	C.MemFree(data_ptr)
	return decode_gradient_json(buf.bytestr())
}

// --- Gradient2D ---

pub fn load_gradient2d_from_file(path string) !core.Gradient2D {
	src := os.read_file(path)!
	return decode_gradient2d_json(src)
}

pub fn load_gradient2d_from_rres(loader &rres.RresLoader, key string) !core.Gradient2D {
	chunk := loader.load_single(key) or { return error('gradient2d chunk not found: ${key}') }
	defer { chunk.unload() }
	data_ptr, size := rres.load_data_from_resource(chunk)
	if data_ptr == unsafe { nil } || size == 0 {
		return error('gradient2d chunk empty: ${key}')
	}
	mut buf := []u8{len: int(size)}
	unsafe { C.memcpy(buf.data, data_ptr, usize(size)) }
	C.MemFree(data_ptr)
	return decode_gradient2d_json(buf.bytestr())
}

// --- decoders ---

fn decode_gradient_json(src string) !core.Gradient {
	mut dec := typeinfo.JsonDecoder.parse(src)!
	return decode_gradient_from_dec(mut dec)
}

fn decode_gradient2d_json(src string) !core.Gradient2D {
	mut dec := typeinfo.JsonDecoder.parse(src)!
	dec.enter_object()!
	defer { dec.exit_object() or {} }

	dec.seek_key('fill') or {}
	fill := gradient_fill_from_string(dec.read_string() or { 'linear' })

	dec.seek_key('fill_from') or {}
	fill_from := read_vec2_dec(mut dec) or {
		core.Vec2{
			x: 0.0
			y: 0.5
		}
	}

	dec.seek_key('fill_to') or {}
	fill_to := read_vec2_dec(mut dec) or {
		core.Vec2{
			x: 1.0
			y: 0.5
		}
	}

	dec.seek_key('center') or {}
	center := read_vec2_dec(mut dec) or {
		core.Vec2{
			x: 0.5
			y: 0.5
		}
	}

	dec.seek_key('radius') or {}
	radius := f32(dec.read_f64() or { 0.5 })

	dec.seek_key('focal') or {}
	focal := read_vec2_dec(mut dec) or {
		core.Vec2{
			x: 0.5
			y: 0.5
		}
	}

	dec.seek_key('start_angle') or {}
	start_angle := f32(dec.read_f64() or { 0.0 })

	dec.seek_key('width') or {}
	width := int(dec.read_f64() or { 256.0 })

	dec.seek_key('height') or {}
	height := int(dec.read_f64() or { 256.0 })

	dec.seek_key('gradient') or {
		return core.Gradient2D{
			fill:        fill
			fill_from:   fill_from
			fill_to:     fill_to
			center:      center
			radius:      radius
			focal:       focal
			start_angle: start_angle
			width:       width
			height:      height
		}
	}
	gradient := decode_gradient_from_dec(mut dec)!

	return core.Gradient2D{
		gradient:    gradient
		fill:        fill
		fill_from:   fill_from
		fill_to:     fill_to
		center:      center
		radius:      radius
		focal:       focal
		start_angle: start_angle
		width:       width
		height:      height
	}
}

fn decode_gradient_from_dec(mut dec typeinfo.JsonDecoder) !core.Gradient {
	dec.enter_object()!
	defer { dec.exit_object() or {} }

	dec.seek_key('interpolation') or {}
	interp := gradient_interp_from_string(dec.read_string() or { 'linear' })

	mut stops := []core.GradientStop{}
	dec.seek_key('stops') or { return core.Gradient{
		interpolation: interp
	} }
	dec.enter_array()!
	for dec.has_next_element() {
		dec.enter_object()!
		dec.seek_key('offset') or {}
		offset := f32(dec.read_f64() or { 0.0 })
		dec.seek_key('r') or {}
		r := u8(dec.read_f64() or { 0.0 })
		dec.seek_key('g') or {}
		g := u8(dec.read_f64() or { 0.0 })
		dec.seek_key('b') or {}
		b := u8(dec.read_f64() or { 0.0 })
		dec.seek_key('a') or {}
		a := u8(dec.read_f64() or { 255.0 })
		dec.exit_object()!
		stops << core.GradientStop{
			offset: offset
			color:  rl.Color{
				r: r
				g: g
				b: b
				a: a
			}
		}
	}
	dec.exit_array()!

	return core.Gradient{
		stops:         stops
		interpolation: interp
	}
}

fn read_vec2_dec(mut dec typeinfo.JsonDecoder) !core.Vec2 {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('x')!
	x := f32(dec.read_f64()!)
	dec.seek_key('y')!
	y := f32(dec.read_f64()!)
	return core.Vec2{
		x: x
		y: y
	}
}

fn gradient_interp_from_string(s string) core.GradientInterpolation {
	return match s {
		'constant' { .constant }
		'cubic' { .cubic }
		'monotone_cubic' { .monotone_cubic }
		else { .linear }
	}
}

fn gradient_fill_from_string(s string) core.GradientFill {
	return match s {
		'radial' { .radial }
		'radial_focal' { .radial_focal }
		'conic' { .conic }
		else { .linear }
	}
}
