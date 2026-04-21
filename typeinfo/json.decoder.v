module typeinfo

import x.json2

// FrameKind lets consume_value know how to interpret the top stack frame
// without relying on heuristics. a .root frame holds the unparsed root value
// and returns it verbatim (used exactly once to bootstrap enter_object /
// enter_array or to read a top-level scalar). .object_frame and .array_frame
// are entered containers that advance a cursor on each consume_value call.
enum FrameKind {
	root
	object_frame
	array_frame
}

pub struct JsonDecoder {
pub mut:
	stack []DecodeFrame
}

struct DecodeFrame {
mut:
	kind   FrameKind = .root
	value  json2.Any
	cursor int      // next array index, or next key index for objects
	keys   []string // populated for object frames
}

pub fn JsonDecoder.parse(src string) !JsonDecoder {
	root := json2.decode[json2.Any](src)!
	return JsonDecoder{
		// kind defaults to .root - this frame is consumed once by the first
		// enter_object / enter_array call (or read directly for scalars).
		stack: [DecodeFrame{
			value: root
		}]
	}
}

// --- scalar reads ---

pub fn (mut d JsonDecoder) read_i64() !i64 {
	a := d.consume_value()!
	return a.i64()
}

pub fn (mut d JsonDecoder) read_f64() !f64 {
	a := d.consume_value()!
	return a.f64()
}

pub fn (mut d JsonDecoder) read_bool() !bool {
	a := d.consume_value()!
	return a.bool()
}

pub fn (mut d JsonDecoder) read_string() !string {
	a := d.consume_value()!
	return a.str()
}

// --- container navigation ---

pub fn (mut d JsonDecoder) enter_object() ! {
	v := d.consume_value()!
	match v {
		map[string]json2.Any {
			d.stack << DecodeFrame{
				kind:   .object_frame
				value:  v
				cursor: 0
				keys:   v.keys()
			}
		}
		else {
			return error('expected object, got ${any_kind(v)}')
		}
	}
}

pub fn (mut d JsonDecoder) exit_object() ! {
	if d.stack.len == 0 || d.stack.last().kind != .object_frame {
		return error('JsonDecoder: exit_object called without a matching enter_object')
	}
	d.stack.pop()
}

pub fn (mut d JsonDecoder) enter_array() ! {
	v := d.consume_value()!
	match v {
		[]json2.Any {
			d.stack << DecodeFrame{
				kind:   .array_frame
				value:  v
				cursor: 0
			}
		}
		else {
			return error('expected array, got ${any_kind(v)}')
		}
	}
}

pub fn (mut d JsonDecoder) exit_array() ! {
	if d.stack.len == 0 || d.stack.last().kind != .array_frame {
		return error('JsonDecoder: exit_array called without a matching enter_array')
	}
	d.stack.pop()
}

// peek_key returns the next key in the current object frame without consuming
// it. returns none when all keys have been visited or the stack is empty.
pub fn (mut d JsonDecoder) peek_key() ?string {
	if d.stack.len == 0 {
		return none
	}
	top := &d.stack[d.stack.len - 1]
	if top.kind != .object_frame || top.cursor >= top.keys.len {
		return none
	}
	return top.keys[top.cursor]
}

// consume_key advances past the current key and returns it.
pub fn (mut d JsonDecoder) consume_key() ?string {
	k := d.peek_key() or { return none }
	mut top := &d.stack[d.stack.len - 1]
	top.cursor++
	return k
}

// has_next_element returns true while an array frame still has unread elements.
pub fn (mut d JsonDecoder) has_next_element() bool {
	if d.stack.len == 0 {
		return false
	}
	top := &d.stack[d.stack.len - 1]
	if top.kind != .array_frame {
		return false
	}
	arr := top.value as []json2.Any
	return top.cursor < arr.len
}

// rewind_object resets the cursor on the current object frame back to zero.
// used by collect_keys in serde/walk_json.v: collect all key names, then
// rewind so the field-driven read loop can seek to each key in turn.
pub fn (mut d JsonDecoder) rewind_object() {
	if d.stack.len == 0 {
		return
	}
	mut top := &d.stack[d.stack.len - 1]
	if top.kind != .object_frame {
		return
	}
	top.cursor = 0
}

// seek_key positions the cursor so the next consume_value call reads the
// value for key k. Used by read_struct to jump to a specific field after
// collect_keys has confirmed the key is present.
pub fn (mut d JsonDecoder) seek_key(k string) ! {
	if d.stack.len == 0 {
		return error('JsonDecoder: seek_key on empty stack')
	}
	mut top := &d.stack[d.stack.len - 1]
	if top.kind != .object_frame {
		return error('JsonDecoder: seek_key called outside an object frame')
	}
	for i, key in top.keys {
		if key == k {
			top.cursor = i
			return
		}
	}
	return error('JsonDecoder: key "${k}" not found')
}

// --- internal ---

// consume_value returns the next json2.Any from the current frame:
//
//   .root         - returns top.value verbatim (the bootstrapping read).
//   .object_frame - returns obj[keys[cursor]] and increments cursor.
//   .array_frame  - returns arr[cursor] and increments cursor.
//
// errors if the stack is empty or the current container is exhausted.
fn (mut d JsonDecoder) consume_value() !json2.Any {
	if d.stack.len == 0 {
		return error('JsonDecoder: consume_value on empty stack')
	}
	mut top := &d.stack[d.stack.len - 1]

	match top.kind {
		.root {
			// The root frame is a one-shot wrapper. Return its value directly;
			// the caller (enter_object / enter_array) will push a proper frame
			// on top of it, so this frame is never visited again.
			return top.value
		}
		.object_frame {
			if top.cursor >= top.keys.len {
				return error('JsonDecoder: object frame exhausted (${top.keys.len} keys read)')
			}
			k := top.keys[top.cursor]
			top.cursor++
			// Grab the underlying map. We know the type is correct because
			// enter_object verified it and set the kind flag.
			val := top.value
			match val {
				map[string]json2.Any {
					return val[k] or { return error('JsonDecoder: key "${k}" not found in object') }
				}
				else {
					return error('JsonDecoder: object frame holds a non-map value (bug)')
				}
			}
		}
		.array_frame {
			val := top.value
			match val {
				[]json2.Any {
					if top.cursor >= val.len {
						return error('JsonDecoder: array frame exhausted (${val.len} elements read)')
					}
					v := val[top.cursor]
					top.cursor++
					return v
				}
				else {
					return error('JsonDecoder: array frame holds a non-array value (bug)')
				}
			}
		}
	}
}

fn any_kind(a json2.Any) string {
	return match a {
		string { 'string' }
		i64 { 'integer' }
		f64 { 'number' }
		bool { 'bool' }
		[]json2.Any { 'array' }
		map[string]json2.Any { 'object' }
		json2.Null { 'null' }
		else { 'unknown' }
	}
}
