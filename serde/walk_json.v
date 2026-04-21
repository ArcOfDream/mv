module serde

import typeinfo
import v.reflection

// write_struct: serialize a struct's @[export]-tagged fields to JSON
//
// the caller is responsible for setting up the surrounding object context

pub fn write_struct[T](src &T, registry &typeinfo.TypeRegistry, mut enc typeinfo.JsonEncoder) ! {
	enc.begin_object()!

	$for field in T.fields {
		mut is_export := false
		mut alias := field.name

		for a in field.attrs {
			if a == 'export' {
				is_export = true
			} else if a.starts_with('export:') {
				is_export = true
				alias = a.all_after(':').trim_space()
			}
		}

		if is_export {
			type_name := resolve_type_name(field.typ) or {
				return error('walk: could not resolve type name for field "${field.name}" on ${T.name}')
			}

			info := registry.lookup(type_name) or {
				return error('walk: unregistered type "${type_name}" (field "${field.name}" on ${T.name})')
			}

			hook := info.write_json or {
				return error('walk: type "${type_name}" has no write_json hook (field "${field.name}" on ${T.name})')
			}

			enc.key(alias)
			hook(voidptr(&src.$(field.name)), mut enc)!
		}
	}
	enc.end_object()!
}

// read_struct: fill a struct's @[export] fields from a JSON object.
//
// contract: the decoder's cursor is positioned such that the next value is the
// object to read. read_struct consumes that object and leaves the cursor
// positioned after it.
//
// Two iteration strategies were considered:
//   (a) Walk the struct's fields, for each one probe the JSON for a matching key
//   (b) Walk the JSON keys, look up each in a field-name->info table
//
// (a) is chosen because it gracefully handles missing keys (field stays at its
// default) and unknown keys in JSON (can warn or ignore). (b) has better
// asymptotic behavior for wide structs but that's irrelevant at scene-load
// scale. (a) also maps 1:1 with write_struct, which matters for mental model.

pub fn read_struct[T](mut dst T, registry &typeinfo.TypeRegistry, mut dec typeinfo.JsonDecoder) ! {
	dec.enter_object()!
	defer { dec.exit_object() or {} }

	// collect all keys present in the JSON object up-front so we can do
	// field-driven lookup. the alternative is to let JsonDecoder expose a
	// "has_key(k)" probe, but that couples the decoder to random-access
	// semantics that binary decoders might not want to provide.
	present_keys := collect_keys(mut dec)!

	$for field in T.fields {
		mut is_export := false
		mut alias := field.name

		for a in field.attrs {
			if a == 'export' {
				is_export = true
			} else if a.starts_with('export:') {
				is_export = true
				alias = a.all_after(':').trim_space()
			}
		}

		if is_export {
			if alias in present_keys {
				type_name := resolve_type_name(field.typ) or {
					return error('walk: could not resolve type name for field "${field.name}" on ${T.name}')
				}

				info := registry.lookup(type_name) or {
					return error('walk: unregistered type "${type_name}" (field "${field.name}" on ${T.name})')
				}

				hook := info.read_json or {
					return error('walk: type "${type_name}" has no read_json hook (field "${field.name}" on ${T.name})')
				}

				// reposition the decoder at the value for this key, then invoke
				// the hook. the decoder handles its own cursor after this.
				dec.seek_key(alias)!
				hook(mut dec, voidptr(&dst.$(field.name)))!
			}
			// missing key: field keeps its default. Silent by design - scenes
			// with partial property maps should just load cleanly.
		}
	}
}

// --- internals ---

// Map a V comptime type index to the registry's string key.
//
// NOTE: v.reflection.get_type is the runtime path. If your V version supports
// field.typ.name at comptime, replace this with a direct comptime expression
// baked into the $for loop - it's faster and preserves more info at codegen.
// Worth revisiting once the walker is proven working.
fn resolve_type_name(type_idx int) ?string {
	t := reflection.get_type(type_idx) or { return none }
	return t.name
}

fn collect_keys(mut dec typeinfo.JsonDecoder) ![]string {
	mut keys := []string{}
	for {
		k := dec.peek_key() or { break }
		keys << k
		dec.consume_key() // advance key cursor without consuming the value
	}
	dec.rewind_object() // reset cursor to start of current object
	return keys
}
