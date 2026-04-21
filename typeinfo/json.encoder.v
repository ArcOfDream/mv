module typeinfo

import x.json2

struct EncodeFrame {
mut:
	container   json2.Any
	pending_key ?string
}

pub struct JsonEncoder {
pub mut:
	stack []EncodeFrame
	root  json2.Any = json2.Any('')
}

pub fn JsonEncoder.new() JsonEncoder {
	return JsonEncoder{
		stack: []EncodeFrame{cap: 8}
	}
}

pub fn (e &JsonEncoder) to_string() string {
	return e.root.str()
}

// --- scalar writes ---

pub fn (mut e JsonEncoder) write_i64(v i64) ! {
	e.push_value(json2.Any(v))!
}

pub fn (mut e JsonEncoder) write_f64(v f64) ! {
	e.push_value(json2.Any(v))!
}

pub fn (mut e JsonEncoder) write_bool(v bool) ! {
	e.push_value(json2.Any(v))!
}

pub fn (mut e JsonEncoder) write_string(v string) ! {
	e.push_value(json2.Any(v))!
}

// --- containers ---

pub fn (mut e JsonEncoder) begin_object() ! {
	e.stack << EncodeFrame{
		container: json2.Any(map[string]json2.Any{})
	}
}

pub fn (mut e JsonEncoder) end_object() ! {
	frame := e.stack.pop()
	e.push_value(frame.container)!
}

pub fn (mut e JsonEncoder) begin_array() ! {
	e.stack << EncodeFrame{
		container: json2.Any([]json2.Any{})
	}
}

pub fn (mut e JsonEncoder) end_array() ! {
	frame := e.stack.pop()
	e.push_value(frame.container)!
}

pub fn (mut e JsonEncoder) key(k string) {
	if e.stack.len == 0 {
		return
	}
	e.stack[e.stack.len - 1].pending_key = k
}

// --- internals ---

fn (mut e JsonEncoder) push_value(v json2.Any) ! {
	if e.stack.len == 0 {
		e.root = v
		return
	}
	mut frame := e.stack[e.stack.len - 1]
	mut container := frame.container
	match mut container {
		map[string]json2.Any {
			key := frame.pending_key or {
				return error('JsonEncoder: value pushed into object without a key')
			}

			container[key] = v
			frame.pending_key = none
		}
		[]json2.Any {
			container << v
		}
		else {
			return error('JsonEncoder: stack top is not a container')
		}
	}
	frame.container = container
	e.stack[e.stack.len - 1] = frame
}

