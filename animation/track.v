module animation

pub struct Keyframe[T] {
pub:
	time f32
	ease EaseFn @[required]
pub mut:
	value T
}

pub interface ITrack {
mut:
	sample(f32)
	reset()
}

pub struct Track[T] {
mut:
	keys      []Keyframe[T]
	lerp_fn   fn (T, T, f32) T @[required]
	setter_cb fn (T)           @[required]
}

// pub fn (mut tr Track[T]) write(value T) {
//	tr.setter_cb(value)
//}

pub fn (tr &Track[T]) sample(time f32) {
	n := tr.keys.len
	if n == 0 {
		return
	}

	if n == 1 || time <= tr.keys[0].time {
		tr.setter_cb(tr.keys[0].value)
		return
	}
	if time >= tr.keys[n - 1].time {
		tr.setter_cb(tr.keys[n - 1].value)
		return
	}

	mut lo := 0
	mut hi := n - 1
	for hi - lo > 1 {
		mid := (lo + hi) / 2
		if tr.keys[mid].time <= time {
			lo = mid
		} else {
			hi = mid
		}
	}

	a := tr.keys[lo]
	b := tr.keys[hi]
	local_time := (time - a.time) / (b.time - a.time)
	eased_time := b.ease(local_time)
	tr.setter_cb(tr.lerp_fn(a.value, b.value, eased_time))
}

pub fn (tr &Track[T]) reset() {
	if tr.keys.len > 0 {
		tr.setter_cb(tr.keys[0].value)
	}
}
