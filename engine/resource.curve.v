module engine

import os
import mv.typeinfo
import rres
import core

// load_curve_from_file reads a .curve.json file and deserialises it.
// Use this path in debug builds or during development.
pub fn load_curve_from_file(path string) !core.Curve {
	src := os.read_file(path)!
	return decode_curve_json(src)
}

// load_curve_from_rres extracts a curve JSON chunk from an open rres archive
// and deserialises it. The chunk must have been packed by mvpacker from a
// .curve.json file; it is stored as a RAWD chunk keyed by the original path.
pub fn load_curve_from_rres(loader &rres.RresLoader, key string) !core.Curve {
	chunk := loader.load_single(key) or { return error('curve chunk not found: ${key}') }
	defer { chunk.unload() }
	data_ptr, size := rres.load_data_from_resource(chunk)
	if data_ptr == unsafe { nil } || size == 0 {
		return error('curve chunk empty: ${key}')
	}
	mut buf := []u8{len: int(size)}
	unsafe { C.memcpy(buf.data, data_ptr, usize(size)) }
	C.MemFree(data_ptr)
	return decode_curve_json(buf.bytestr())
}

fn decode_curve_json(src string) !core.Curve {
	mut dec := typeinfo.JsonDecoder.parse(src)!
	dec.enter_object()!
	defer { dec.exit_object() or {} }

	dec.seek_key('min_value') or {}
	min_value := f32(dec.read_f64() or { 0.0 })
	dec.seek_key('max_value') or {}
	max_value := f32(dec.read_f64() or { 1.0 })

	mut points := []core.CurvePoint{}
	dec.seek_key('points') or {
		return core.Curve{
			min_value: min_value
			max_value: max_value
		}
	}
	dec.enter_array()!
	for dec.has_next_element() {
		dec.enter_object()!
		dec.seek_key('x') or {}
		x := f32(dec.read_f64() or { 0.0 })
		dec.seek_key('y') or {}
		y := f32(dec.read_f64() or { 0.0 })
		dec.seek_key('tl') or {}
		tl := f32(dec.read_f64() or { 0.0 })
		dec.seek_key('tr') or {}
		tr := f32(dec.read_f64() or { 0.0 })
		dec.exit_object()!
		points << core.CurvePoint{
			pos:       core.Vec2{
				x: x
				y: y
			}
			tangent_l: tl
			tangent_r: tr
		}
	}
	dec.exit_array()!

	return core.Curve{
		min_value: min_value
		max_value: max_value
		points:    points
	}
}
