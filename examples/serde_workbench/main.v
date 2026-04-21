module main

import mv.core { Vec2 }
import raylib { Color }
import mv.serde
import mv.typeinfo

struct TestThing {
pub mut:
	position Vec2  @[export]
	tint     Color @[export]
	speed    f32   @[export]
	internal int // not exported; should not appear in JSON
}

fn register_vec2(mut reg typeinfo.TypeRegistry) {
	reg.register_value[Vec2](typeinfo.ValueOpts{
		write_json: fn (src voidptr, mut enc typeinfo.JsonEncoder) ! {
			v := unsafe { &Vec2(src) }
			enc.begin_object()!
			enc.key('x')
			enc.write_f64(f64(v.x))!
			enc.key('y')
			enc.write_f64(f64(v.y))!
			enc.end_object()!
		}
		read_json:  fn (mut dec typeinfo.JsonDecoder, dst voidptr) ! {
			mut v := unsafe { &Vec2(dst) }
			dec.enter_object()!
			defer { dec.exit_object() or {} }
			dec.seek_key('x')!
			v.x = f32(dec.read_f64()!)
			dec.seek_key('y')!
			v.y = f32(dec.read_f64()!)
		}
	})
}

fn register_color(mut reg typeinfo.TypeRegistry) {
	reg.register_value[Color](typeinfo.ValueOpts{
		write_json: fn (src voidptr, mut enc typeinfo.JsonEncoder) ! {
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
		read_json:  fn (mut dec typeinfo.JsonDecoder, dst voidptr) ! {
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
}

fn main() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	register_vec2(mut reg) // the value-type registration for Vec2
	register_color(mut reg)

	original := TestThing{
		position: Vec2{
			x: 10.0
			y: 20.0
		}
		tint:     Color{
			r: 255
			g: 128
			b: 64
			a: 255
		}
		speed:    3.5
		internal: 999
	}

	mut enc := typeinfo.JsonEncoder.new()
	serde.write_struct(&original, reg, mut enc)!
	json := enc.to_string()
	println('wrote: ${json}')

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := TestThing{}
	serde.read_struct(mut restored, reg, mut dec)!

	assert restored.position.x == original.position.x
	assert restored.position.y == original.position.y
	assert restored.tint.r == original.tint.r
	assert restored.speed == original.speed
	assert restored.internal == 0 // not exported, stays at default
	println('round-trip ok')
}
