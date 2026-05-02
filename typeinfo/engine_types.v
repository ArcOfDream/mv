module typeinfo

import mv.core { Vec2 }
import raylib { Color, Rectangle }

// register_engine_types installs serde handlers for the common engine value
// types: Vec2, Color, and Rectangle. Call alongside register_builtins when
// setting up a TypeRegistry.
pub fn register_engine_types(mut r TypeRegistry) {
	// Vec2 = C.Vector2 - two f32 fields, plain old data.
	r.register_value[Vec2](ValueOpts{
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			v := unsafe { &Vec2(src) }
			enc.begin_object()!
			enc.key('x')
			enc.write_f64(f64(v.x))!
			enc.key('y')
			enc.write_f64(f64(v.y))!
			enc.end_object()!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			mut v := unsafe { &Vec2(dst) }
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('x')!
			v.x = f32(dec.read_f64()!)
			dec.seek_key('y')!
			v.y = f32(dec.read_f64()!)
		}
	})

	// Color - four u8 channels (r, g, b, a).
	r.register_value[Color](ValueOpts{
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			c := unsafe { &Color(src) }
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
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			mut c := unsafe { &Color(dst) }
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('r')!
			c.r = u8(dec.read_i64()!)
			dec.seek_key('g')!
			c.g = u8(dec.read_i64()!)
			dec.seek_key('b')!
			c.b = u8(dec.read_i64()!)
			dec.seek_key('a')!
			c.a = u8(dec.read_i64()!)
		}
	})

	// Rectangle - four f32 fields (x, y, width, height).
	r.register_value[Rectangle](ValueOpts{
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			rect := unsafe { &Rectangle(src) }
			enc.begin_object()!
			enc.key('x')
			enc.write_f64(f64(rect.x))!
			enc.key('y')
			enc.write_f64(f64(rect.y))!
			enc.key('width')
			enc.write_f64(f64(rect.width))!
			enc.key('height')
			enc.write_f64(f64(rect.height))!
			enc.end_object()!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			mut rect := unsafe { &Rectangle(dst) }
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('x')!
			rect.x = f32(dec.read_f64()!)
			dec.seek_key('y')!
			rect.y = f32(dec.read_f64()!)
			dec.seek_key('width')!
			rect.width = f32(dec.read_f64()!)
			dec.seek_key('height')!
			rect.height = f32(dec.read_f64()!)
		}
	})
}
