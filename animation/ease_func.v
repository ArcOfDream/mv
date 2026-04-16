module tween

import math { cosf, powf, sinf, sqrtf }

pub type EaseFn = fn (f32) f32

const back_c1 = f32(1.70158)
const back_c2 = back_c1 * 1.525
const back_c3 = back_c1 + 1.0

const elastic_c4 = f32((2.0 * math.pi) / 3.0)
const elastic_c5 = f32((2.0 * math.pi) / 4.5)

// vfmt off

fn bounce_out(t f32) f32 {
	n := f32(7.5625)
	d := f32(2.75)
	if t < 1.0 / d {
		return n * t * t
	} else if t < 2.0 / d {
		t2 := t - 1.5 / d
		return n * t2 * t2 + 0.75
	} else if t < 2.5 / d {
		t2 := t - 2.25 / d
		return n * t2 * t2 + 0.9375
	} else {
		t2 := t - 2.625 / d
		return n * t2 * t2 + 0.984375
	}
}

// linear
pub fn linear(t f32) f32 { return t }
pub fn step(t f32) f32   { return if t < f32(1.0) { f32(0.0) } else { f32(1.0) } }

// sine
pub fn in_sine(t f32) f32     { return 1.0 - cosf((t * math.pi) / 2.0) }
pub fn out_sine(t f32) f32    { return sinf((t * math.pi) / 2.0) }
pub fn in_out_sine(t f32) f32 { return -(cosf(math.pi * t) - 1.0) / 2.0 }

// quad (quadratic)
pub fn in_quad(t f32) f32     { return t * t }
pub fn out_quad(t f32) f32    { return 1.0 - (1.0 - t) * (1.0 - t) }
pub fn in_out_quad(t f32) f32 {
	b := -2.0 * t + 2.0
	return if t < 0.5 { 2.0 * t * t } else { 1.0 - b * b / 2.0 }
}

// cubic
pub fn in_cubic(t f32) f32     { return t * t * t }
pub fn out_cubic(t f32) f32    { c := 1.0 - t; return 1.0 - c * c * c }
pub fn in_out_cubic(t f32) f32 {
	b := -2.0 * t + 2.0
	return if t < 0.5 { 4.0 * t * t * t } else { 1.0 - b * b * b / 2.0 }
}

// quart (quartic)
pub fn in_quart(t f32) f32     { return t * t * t * t }
pub fn out_quart(t f32) f32    { c := 1.0 - t; return 1.0 - c * c * c * c }
pub fn in_out_quart(t f32) f32 {
	b := -2.0 * t + 2.0
	return if t < 0.5 { 8.0 * t * t * t * t } else { 1.0 - b * b * b * b / 2.0 }
}

// quint (quintic)
pub fn in_quint(t f32) f32     { return t * t * t * t * t }
pub fn out_quint(t f32) f32    { c := 1.0 - t; return 1.0 - c * c * c * c * c }
pub fn in_out_quint(t f32) f32 {
	b := -2.0 * t + 2.0
	return if t < 0.5 { 16.0 * t * t * t * t * t } else { 1.0 - b * b * b * b * b / 2.0 }
}

// expo (exponential)
pub fn in_expo(t f32) f32 {
	return if t == 0.0 { 0.0 } else { powf(2.0, 10.0 * t - 10.0) }
}
pub fn out_expo(t f32) f32 {
	return if t == 1.0 { 1.0 } else { 1.0 - powf(2.0, -10.0 * t) }
}
pub fn in_out_expo(t f32) f32 {
	if t == 0.0 { return 0.0 }
	if t == 1.0 { return 1.0 }
	if t < 0.5  { return powf(2.0, 20.0 * t - 10.0) / 2.0 }
	return (2.0 - powf(2.0, -20.0 * t + 10.0)) / 2.0
}

// circ (circular)
pub fn in_circ(t f32) f32  { return 1.0 - sqrtf(1.0 - t * t) }
pub fn out_circ(t f32) f32 { c := t - 1.0; return sqrtf(1.0 - c * c) }
pub fn in_out_circ(t f32) f32 {
	b := -2.0 * t + 2.0
	return if t < 0.5 {
		(1.0 - sqrtf(1.0 - 4.0 * t * t)) / 2.0
	} else {
		(sqrtf(1.0 - b * b) + 1.0) / 2.0
	}
}

// back
pub fn in_back(t f32) f32  { return back_c3 * t * t * t - back_c1 * t * t }
pub fn out_back(t f32) f32 {
	c := t - 1.0
	return 1.0 + back_c3 * c * c * c + back_c1 * c * c
}
pub fn in_out_back(t f32) f32 {
	a := 2.0 * t
	b := 2.0 * t - 2.0
	return if t < 0.5 {
		(a * a * ((back_c2 + 1.0) * a - back_c2)) / 2.0
	} else {
		(b * b * ((back_c2 + 1.0) * b + back_c2) + 2.0) / 2.0
	}
}

// elastic
pub fn in_elastic(t f32) f32 {
	if t == 0.0 { return 0.0 }
	if t == 1.0 { return 1.0 }
	return -powf(2.0, 10.0 * t - 10.0) * sinf((t * 10.0 - 10.75) * elastic_c4)
}
pub fn out_elastic(t f32) f32 {
	if t == 0.0 { return 0.0 }
	if t == 1.0 { return 1.0 }
	return powf(2.0, -10.0 * t) * sinf((t * 10.0 - 0.75) * elastic_c4) + 1.0
}
pub fn in_out_elastic(t f32) f32 {
	if t == 0.0 { return 0.0 }
	if t == 1.0 { return 1.0 }
	if t < 0.5  { return -(powf(2.0, 20.0 * t - 10.0) * sinf((20.0 * t - 11.125) * elastic_c5)) / 2.0 }
	return (powf(2.0, -20.0 * t + 10.0) * sinf((20.0 * t - 11.125) * elastic_c5)) / 2.0 + 1.0
}

// bounce
pub fn in_bounce(t f32) f32     { return 1.0 - bounce_out(1.0 - t) }
pub fn out_bounce(t f32) f32    { return bounce_out(t) }
pub fn in_out_bounce(t f32) f32 {
	return if t < 0.5 {
		(1.0 - bounce_out(1.0 - 2.0 * t)) / 2.0
	} else {
		(1.0 + bounce_out(2.0 * t - 1.0)) / 2.0
	}
}

// vfmt on
