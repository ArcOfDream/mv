module main

import math

pub struct Timer {
pub mut:
	duration f32
	elapsed  f32
	looping  bool
	running  bool
}

pub fn (mut t Timer) start() {
	t.elapsed = 0
	t.running = true
}

pub fn (mut t Timer) stop() {
	t.running = false
}

pub fn (mut t Timer) reset() {
	t.elapsed = 0
}

pub fn (mut t Timer) tick(dt f32) bool {
	if !t.running {
		return false
	}
	t.elapsed += dt
	if t.elapsed >= t.duration {
		if t.looping {
			t.elapsed -= t.duration
		} else {
			t.elapsed = t.duration
			t.running = false
		}
		return true
	}
	return false
}

@[inline]
pub fn (t &Timer) progress() f32 {
	if t.duration == 0 {
		return 0
	}
	return f32(math.clamp(t.elapsed / t.duration, 0, 1))
}

@[inline]
pub fn (t &Timer) is_done() bool {
	return !t.running && t.elapsed >= t.duration
}

@[inline]
pub fn (t &Timer) time_left() f32 {
	return math.max(f32(0), t.duration - t.elapsed)
}
