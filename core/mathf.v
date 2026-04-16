module core

import math

// adapted from prime31's via

// approach moves start toward target by shift, clamping at target.
// start may be less than or greater than target.
// example: approach(2.0, 10.0, 4.0) == 6.0
@[inline]
pub fn approach(start f32, target f32, shift f32) f32 {
	if start < target {
		return math.min(start + shift, target)
	}
	return math.max(start - shift, target)
}

// unlerp returns the normalized position of x within [a, b].
// inverse of lerp: unlerp(a, b, lerp(a, b, t)) == t.
// returns values outside 0..1 when x is outside [a, b].
@[inline]
pub fn unlerp(a f32, b f32, x f32) f32 {
	return (x - a) / (b - a)
}

// remap maps x from the range [a, b] to the range [c, d] without clamping.
// equivalent to lerp(c, d, unlerp(a, b, x)).
@[inline]
pub fn remap(a f32, b f32, c f32, d f32, x f32) f32 {
	t := (x - a) / (b - a)
	return c + t * (d - c)
}

// between returns true if val lies within [lo, hi] inclusive.
@[inline]
pub fn between(val f32, lo f32, hi f32) bool {
	return lo <= val && val <= hi
}

// repeat loops t within [0, length), wrapping back to 0 at length.
// Unlike fmod, handles negative t correctly.
// Example: repeat(-0.1, 1.0) == 0.9
@[inline]
pub fn repeat(t f32, length f32) f32 {
	return t - math.floorf(t / length) * length
}

// ping_pong oscillates t back and forth in [0, length].
// repeat(t) goes 0->1->0->1; ping_pong(t) goes 0->1->0->1 with the return trip.
@[inline]
pub fn ping_pong(t f32, length f32) f32 {
	tt := repeat(t, length * 2)
	return length - math.abs(tt - length)
}

// sincos returns (sin(angle), cos(angle)) together.
// Use when both values are needed for a rotation to avoid two separate trig calls.
@[inline]
pub fn sincos(angle f32) (f32, f32) {
	return f32(math.sin(f64(angle))), f32(math.cos(f64(angle)))
}

// angle_between returns the angle in radians from (x1, y1) to (x2, y2).
// Result is in [-π, π]; 0 points right, positive values rotate counter-clockwise.
@[inline]
pub fn angle_between(x1 f32, y1 f32, x2 f32, y2 f32) f32 {
	return f32(math.atan2(f64(y2 - y1), f64(x2 - x1)))
}

// ceilpow2_int returns the smallest power of two that is >= i.
// Useful for texture dimensions, buffer sizes, and hash table capacity.
@[inline]
pub fn ceilpow2_int(i int) int {
	mut x := i
	x--
	x |= x >> 1
	x |= x >> 2
	x |= x >> 4
	x |= x >> 8
	x |= x >> 16
	return x + 1
}

// ceilpow2_i64 returns the smallest power of two that is >= val.
// Returns 1 for val == 0.
@[inline]
pub fn ceilpow2_i64(val i64) i64 {
	if val == 0 {
		return 1
	}
	mut x := val
	x--
	x |= x >> 1
	x |= x >> 2
	x |= x >> 4
	x |= x >> 8
	x |= x >> 16
	x |= x >> 32
	return x + 1
}