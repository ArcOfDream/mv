// Minimal repro: cgen error triggered by setter_cb closing over and mutating
// an external variable through a generic Track.

struct Vec2 {
pub mut:
	x f32
	y f32
}

struct Track[T] {
mut:
	keys      []T
	setter_cb fn (T)
}

fn invoke_setter[T](f fn (T), value T) {
	f(value)
}

pub fn (mut tr Track[T]) write(value T) {
	invoke_setter(tr.setter_cb, value)
}

pub fn (mut tr Track[T]) sample() {
	n := tr.keys.len
	if n == 0 {
		return
	}
	tr.write(tr.keys[0])
}

fn main() {
	// Setter mutates an external Vec2 via closure capture
	mut pos := Vec2{}
	mut t := Track[Vec2]{
		keys: [Vec2{1.0, 2.0}]
		setter_cb: fn [mut pos] (v Vec2) {
			pos = v
		}
	}
	t.sample()
	println('${pos.x} ${pos.y}')

	// Setter mutates an external string
	mut label := ''
	mut ts := Track[string]{
		keys: ['hello']
		setter_cb: fn [mut label] (s string) {
			label = s
		}
	}
	ts.sample()
	println(label)
}