module engine

import mv.typeinfo
import core { Vec2 }
import raylib as rl
import physics

fn write_vec2_scene(v Vec2, mut enc typeinfo.JsonEncoder) ! {
	enc.begin_object()!
	enc.key('x')
	enc.write_f64(f64(v.x))!
	enc.key('y')
	enc.write_f64(f64(v.y))!
	enc.end_object()!
}

fn read_vec2_scene(mut dec typeinfo.JsonDecoder) !Vec2 {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('x')!
	x := f32(dec.read_f64()!)
	dec.seek_key('y')!
	y := f32(dec.read_f64()!)
	return Vec2{x, y}
}

fn write_color_scene(c rl.Color, mut enc typeinfo.JsonEncoder) ! {
	enc.begin_object()!
	enc.key('r')
	enc.write_i64(i64(c.r))!
	enc.key('g')
	enc.write_i64(i64(c.g))!
	enc.key('b')
	enc.write_i64(i64(c.b))!
	enc.key('a')
	enc.write_i64(i64(c.a))!
	enc.end_object()!
}

fn read_color_scene(mut dec typeinfo.JsonDecoder) !rl.Color {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('r')!
	r := u8(dec.read_i64()!)
	dec.seek_key('g')!
	g := u8(dec.read_i64()!)
	dec.seek_key('b')!
	b := u8(dec.read_i64()!)
	dec.seek_key('a')!
	a := u8(dec.read_i64()!)
	return rl.Color{r, g, b, a}
}

fn write_phys_vec_scene(v physics.Vec, mut enc typeinfo.JsonEncoder) ! {
	enc.begin_object()!
	enc.key('x')
	enc.write_f64(f64(v.x))!
	enc.key('y')
	enc.write_f64(f64(v.y))!
	enc.end_object()!
}

fn read_phys_vec_scene(mut dec typeinfo.JsonDecoder) !physics.Vec {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('x')!
	x := f32(dec.read_f64()!)
	dec.seek_key('y')!
	y := f32(dec.read_f64()!)
	return physics.Vec{x, y}
}

fn write_shape_scene(s physics.Shape, mut enc typeinfo.JsonEncoder) ! {
	enc.begin_object()!
	match s {
		physics.AABB {
			enc.key('kind')
			enc.write_string('aabb')!
			enc.key('min')
			write_phys_vec_scene(s.min, mut enc)!
			enc.key('max')
			write_phys_vec_scene(s.max, mut enc)!
		}
		physics.Circle {
			enc.key('kind')
			enc.write_string('circle')!
			enc.key('px')
			enc.write_f64(f64(s.p.x))!
			enc.key('py')
			enc.write_f64(f64(s.p.y))!
			enc.key('r')
			enc.write_f64(f64(s.r))!
		}
		physics.Capsule {
			enc.key('kind')
			enc.write_string('capsule')!
			enc.key('ax')
			enc.write_f64(f64(s.a.x))!
			enc.key('ay')
			enc.write_f64(f64(s.a.y))!
			enc.key('bx')
			enc.write_f64(f64(s.b.x))!
			enc.key('by')
			enc.write_f64(f64(s.b.y))!
			enc.key('r')
			enc.write_f64(f64(s.r))!
		}
		else {
			// Polygon/Ray/Vec: fall back to a zero AABB
			enc.key('kind')
			enc.write_string('aabb')!
			enc.key('min')
			write_phys_vec_scene(physics.Vec{0, 0}, mut enc)!
			enc.key('max')
			write_phys_vec_scene(physics.Vec{0, 0}, mut enc)!
		}
	}
	enc.end_object()!
}

fn read_shape_scene(mut dec typeinfo.JsonDecoder) !physics.Shape {
	dec.enter_object()!
	defer { dec.exit_object() or {} }
	dec.seek_key('kind')!
	kind := dec.read_string()!
	if kind == 'circle' {
		dec.seek_key('px')!
		px := f32(dec.read_f64()!)
		dec.seek_key('py')!
		py := f32(dec.read_f64()!)
		dec.seek_key('r')!
		r := f32(dec.read_f64()!)
		return physics.Shape(physics.Circle{
			p: physics.Vec{px, py}
			r: r
		})
	} else if kind == 'capsule' {
		dec.seek_key('ax')!
		ax := f32(dec.read_f64()!)
		dec.seek_key('ay')!
		ay := f32(dec.read_f64()!)
		dec.seek_key('bx')!
		bx := f32(dec.read_f64()!)
		dec.seek_key('by')!
		by := f32(dec.read_f64()!)
		dec.seek_key('r')!
		r := f32(dec.read_f64()!)
		return physics.Shape(physics.Capsule{
			a: physics.Vec{ax, ay}
			b: physics.Vec{bx, by}
			r: r
		})
	} else {
		dec.seek_key('min')!
		min := read_phys_vec_scene(mut dec)!
		dec.seek_key('max')!
		max := read_phys_vec_scene(mut dec)!
		return physics.Shape(physics.AABB{
			min: min
			max: max
		})
	}
}
