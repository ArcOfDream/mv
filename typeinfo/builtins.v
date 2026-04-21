module typeinfo

pub fn register_builtins(mut r TypeRegistry) {
	// integer types - pod: true installs memcpy for binary; JSON uses numbers.
	r.register_primitive[int](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_i64(i64(*unsafe { &int(src) }))!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&int(dst) = int(dec.read_i64()!)
			}
		}
	)
	r.register_primitive[i64](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_i64(*unsafe { &i64(src) })!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&i64(dst) = dec.read_i64()!
			}
		}
	)
	r.register_primitive[u32](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_i64(i64(*unsafe { &u32(src) }))!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&u32(dst) = u32(dec.read_i64()!)
			}
		}
	)
	r.register_primitive[u8](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_i64(i64(*unsafe { &u8(src) }))!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&u8(dst) = u8(dec.read_i64()!)
			}
		}
	)

	// Float types
	r.register_primitive[f32](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_f64(f64(*unsafe { &f32(src) }))!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&f32(dst) = f32(dec.read_f64()!)
			}
		}
	)
	r.register_primitive[f64](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_f64(*unsafe { &f64(src) })!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&f64(dst) = dec.read_f64()!
			}
		}
	)

	// Bool - memcpy'able but worth an explicit branch in case the V bool
	// representation ever changes (it's a u8 today).
	r.register_primitive[bool](
		pod:        true
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_bool(*unsafe { &bool(src) })!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&bool(dst) = dec.read_bool()!
			}
		}
	)

	// String - NOT pod. Binary form is length-prefixed bytes; JSON is native.
	r.register_primitive[string](
		pod:        false
		write_json: fn (src voidptr, mut enc JsonEncoder) ! {
			enc.write_string(*unsafe { &string(src) })!
		}
		read_json:  fn (mut dec JsonDecoder, dst voidptr) ! {
			unsafe {
				*&string(dst) = dec.read_string()!
			}
		}
		write_bin:  fn (src voidptr, mut enc BinEncoder) ! {
			s := unsafe { &string(src) }
			enc.write_u32(u32(s.len))!
			enc.write_raw(s.str, s.len)!
		}
		read_bin:   fn (mut dec BinDecoder, dst voidptr) ! {
			n := int(dec.read_u32()!)
			bytes := dec.read_raw_bytes(n)!
			unsafe {
				*&string(dst) = bytes.bytestr()
			}
		}
	)
}
