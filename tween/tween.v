module tween

import math { min }

interface ITweener {
	is_done() bool
mut:
	update(f32)
}

pub struct Tweener[T] implements ITweener {
mut:
	target   ?&T
	from     T
	to       T
	duration f32
	elapsed  f32
	ease     Ease
	done     bool
	lerp_fn  fn (T, T, f32) T @[required]
	setter_cb ?fn (T)
}

pub fn (mut tw Tweener[T]) update(dt f32) {
	if tw.done {
		return
	}

	tw.elapsed += dt
	time := min(tw.elapsed / tw.duration, 1.0)
	eased_time := apply_ease(tw.ease, time)
	
	if cb := tw.setter_cb {
		cb(tw.lerp_fn(tw.from, tw.to, eased_time))
	}
	else if _t := tw.target {
		_t = tw.lerp_fn(tw.from, tw.to, eased_time)
	}
	
	if time >= 1.0 {
		tw.done = true
	}
}

pub fn (tw &Tweener[T]) is_done() bool {
	return tw.done
}
