module typeinfo

import mv.core {
	BakedCurve,
	Curve,
	CurvePoint,
	Gradient,
	Gradient2D,
	GradientFill,
	GradientInterpolation,
	GradientStop,
	Vec2,
}
import raylib { Color }

// register_core_types installs serde handlers for the serializable core data
// types: Curve, BakedCurve, Gradient, Gradient2D, CurvePoint, and GradientStop.
//
// NOTE: Gradient.interpolation_curve (?&BakedCurve) is not serialized - it is
// a runtime optimization that can be reattached after loading if needed.
pub fn register_core_types(mut r TypeRegistry) {
	r.register_value[CurvePoint](ValueOpts{
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			write_curve_point(unsafe { &CurvePoint(src) }, mut enc)!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&CurvePoint(dst) = read_curve_point(mut dec)!
			}
		}
	})

	r.register_value[GradientStop](ValueOpts{
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			write_gradient_stop(unsafe { &GradientStop(src) }, mut enc)!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&GradientStop(dst) = read_gradient_stop(mut dec)!
			}
		}
	})

	r.register_value[Curve](ValueOpts{
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			c := unsafe { &Curve(src) }
			enc.begin_object()!
			enc.key('min_value')
			enc.write_f64(f64(c.min_value))!
			enc.key('max_value')
			enc.write_f64(f64(c.max_value))!
			enc.key('points')
			enc.begin_array()!
			for p in c.points {
				write_curve_point(&p, mut enc)!
			}
			enc.end_array()!
			enc.end_object()!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			mut c := unsafe { &Curve(dst) }
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('min_value')!
			c.min_value = f32(dec.read_f64()!)
			dec.seek_key('max_value')!
			c.max_value = f32(dec.read_f64()!)
			dec.seek_key('points')!
			dec.enter_array()!
			c.points = []CurvePoint{}
			for dec.has_next_element() {
				c.points << read_curve_point(mut dec)!
			}
			dec.exit_array()!
		}
	})

	// BakedCurve has immutable fields (pub:), so deserialization builds a
	// complete value and writes it to dst in one assignment.
	r.register_value[BakedCurve](ValueOpts{
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			bc := unsafe { &BakedCurve(src) }
			enc.begin_object()!
			enc.key('min_value')
			enc.write_f64(f64(bc.min_value))!
			enc.key('max_value')
			enc.write_f64(f64(bc.max_value))!
			enc.key('samples')
			enc.begin_array()!
			for s in bc.samples {
				enc.write_f64(f64(s))!
			}
			enc.end_array()!
			enc.end_object()!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('min_value')!
			min_val := f32(dec.read_f64()!)
			dec.seek_key('max_value')!
			max_val := f32(dec.read_f64()!)
			dec.seek_key('samples')!
			dec.enter_array()!
			mut samples := []f32{}
			for dec.has_next_element() {
				samples << f32(dec.read_f64()!)
			}
			dec.exit_array()!
			unsafe {
				*&BakedCurve(dst) = BakedCurve{
					samples:   samples
					min_value: min_val
					max_value: max_val
				}
			}
		}
	})

	r.register_value[Gradient](ValueOpts{
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			write_gradient_data(unsafe { &Gradient(src) }, mut enc)!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&Gradient(dst) = read_gradient_data(mut dec)!
			}
		}
	})

	r.register_value[Gradient2D](ValueOpts{
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			gt := unsafe { &Gradient2D(src) }
			enc.begin_object()!
			enc.key('fill')
			enc.write_string(gradient_fill_str(gt.fill))!
			enc.key('fill_from')
			write_vec2(gt.fill_from, mut enc)!
			enc.key('fill_to')
			write_vec2(gt.fill_to, mut enc)!
			enc.key('center')
			write_vec2(gt.center, mut enc)!
			enc.key('radius')
			enc.write_f64(f64(gt.radius))!
			enc.key('focal')
			write_vec2(gt.focal, mut enc)!
			enc.key('start_angle')
			enc.write_f64(f64(gt.start_angle))!
			enc.key('width')
			enc.write_i64(i64(gt.width))!
			enc.key('height')
			enc.write_i64(i64(gt.height))!
			enc.key('gradient')
			write_gradient_data(&gt.gradient, mut enc)!
			enc.end_object()!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			mut gt := unsafe { &Gradient2D(dst) }
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('fill')!
			gt.fill = gradient_fill_from_str(dec.read_string()!)
			dec.seek_key('fill_from')!
			gt.fill_from = read_vec2(mut dec)!
			dec.seek_key('fill_to')!
			gt.fill_to = read_vec2(mut dec)!
			dec.seek_key('center')!
			gt.center = read_vec2(mut dec)!
			dec.seek_key('radius')!
			gt.radius = f32(dec.read_f64()!)
			dec.seek_key('focal')!
			gt.focal = read_vec2(mut dec)!
			dec.seek_key('start_angle')!
			gt.start_angle = f32(dec.read_f64()!)
			dec.seek_key('width')!
			gt.width = int(dec.read_i64()!)
			dec.seek_key('height')!
			gt.height = int(dec.read_i64()!)
			dec.seek_key('gradient')!
			gt.gradient = read_gradient_data(mut dec)!
		}
	})
}

// --- private helpers shared between closures ---

fn write_vec2(v Vec2, mut enc JsonEncoder) ! {
	enc.begin_object()!
	enc.key('x')
	enc.write_f64(f64(v.x))!
	enc.key('y')
	enc.write_f64(f64(v.y))!
	enc.end_object()!
}

fn read_vec2(mut dec JsonDecoder) !Vec2 {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('x')!
	x := f32(dec.read_f64()!)
	dec.seek_key('y')!
	y := f32(dec.read_f64()!)
	return Vec2{x, y}
}

fn write_curve_point(p &CurvePoint, mut enc JsonEncoder) ! {
	enc.begin_object()!
	enc.key('x')
	enc.write_f64(f64(p.pos.x))!
	enc.key('y')
	enc.write_f64(f64(p.pos.y))!
	enc.key('tl')
	enc.write_f64(f64(p.tangent_l))!
	enc.key('tr')
	enc.write_f64(f64(p.tangent_r))!
	enc.end_object()!
}

fn read_curve_point(mut dec JsonDecoder) !CurvePoint {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('x')!
	x := f32(dec.read_f64()!)
	dec.seek_key('y')!
	y := f32(dec.read_f64()!)
	dec.seek_key('tl')!
	tl := f32(dec.read_f64()!)
	dec.seek_key('tr')!
	tr := f32(dec.read_f64()!)
	return CurvePoint{
		pos:       Vec2{x, y}
		tangent_l: tl
		tangent_r: tr
	}
}

fn write_gradient_stop(s &GradientStop, mut enc JsonEncoder) ! {
	enc.begin_object()!
	enc.key('offset')
	enc.write_f64(f64(s.offset))!
	enc.key('r')
	enc.write_i64(i64(s.color.r))!
	enc.key('g')
	enc.write_i64(i64(s.color.g))!
	enc.key('b')
	enc.write_i64(i64(s.color.b))!
	enc.key('a')
	enc.write_i64(i64(s.color.a))!
	enc.end_object()!
}

fn read_gradient_stop(mut dec JsonDecoder) !GradientStop {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('offset')!
	offset := f32(dec.read_f64()!)
	dec.seek_key('r')!
	r := u8(dec.read_i64()!)
	dec.seek_key('g')!
	g := u8(dec.read_i64()!)
	dec.seek_key('b')!
	b := u8(dec.read_i64()!)
	dec.seek_key('a')!
	a := u8(dec.read_i64()!)
	return GradientStop{
		offset: offset
		color:  Color{r, g, b, a}
	}
}

fn write_gradient_data(g &Gradient, mut enc JsonEncoder) ! {
	enc.begin_object()!
	enc.key('interpolation')
	enc.write_string(gradient_interp_str(g.interpolation))!
	enc.key('stops')
	enc.begin_array()!
	for s in g.stops {
		write_gradient_stop(&s, mut enc)!
	}
	enc.end_array()!
	enc.end_object()!
}

fn read_gradient_data(mut dec JsonDecoder) !Gradient {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('interpolation')!
	interp := gradient_interp_from_str(dec.read_string()!)
	dec.seek_key('stops')!
	dec.enter_array()!
	mut stops := []GradientStop{}
	for dec.has_next_element() {
		stops << read_gradient_stop(mut dec)!
	}
	dec.exit_array()!
	return Gradient{
		interpolation: interp
		stops:         stops
	}
}

fn gradient_interp_str(i GradientInterpolation) string {
	return match i {
		.constant { 'constant' }
		.linear { 'linear' }
		.cubic { 'cubic' }
		.monotone_cubic { 'monotone_cubic' }
	}
}

fn gradient_interp_from_str(s string) GradientInterpolation {
	return match s {
		'constant' { GradientInterpolation.constant }
		'cubic' { GradientInterpolation.cubic }
		'monotone_cubic' { GradientInterpolation.monotone_cubic }
		else { GradientInterpolation.linear }
	}
}

fn gradient_fill_str(f GradientFill) string {
	return match f {
		.linear { 'linear' }
		.radial { 'radial' }
		.radial_focal { 'radial_focal' }
		.conic { 'conic' }
	}
}

fn gradient_fill_from_str(s string) GradientFill {
	return match s {
		'radial' { GradientFill.radial }
		'radial_focal' { GradientFill.radial_focal }
		'conic' { GradientFill.conic }
		else { GradientFill.linear }
	}
}
