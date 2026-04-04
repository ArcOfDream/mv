module tween

import math

pub enum Ease {
	// linear
	linear

	// sine
	in_sine
	out_sine
	in_out_sine

	// quad
	in_quad
	out_quad
	in_out_quad

	// cubic
	in_cubic
	out_cubic
	in_out_cubic

	// quart
	in_quart
	out_quart
	in_out_quart

	// quint
	in_quint
	out_quint
	in_out_quint

	// expo
	in_expo
	out_expo
	in_out_expo

	// circ
	in_circ
	out_circ
	in_out_circ

	// back (overshoots slightly)
	in_back
	out_back
	in_out_back

	// elastic (spring-like overshoots)
	in_elastic
	out_elastic
	in_out_elastic

	// bounce
	in_bounce
	out_bounce
	in_out_bounce

	// step (immediate snap, no interpolation)
	step
}

const back_c1 = f32(1.70158)
const back_c2 = back_c1 * 1.525
const back_c3 = back_c1 + 1.0

const elastic_c4 = f32((2.0 * math.pi) / 3.0)
const elastic_c5 = f32((2.0 * math.pi) / 4.5)

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

pub fn apply_ease(e Ease, t f32) f32 {
	return match e {
		// linear
		.linear {
			t
		}
		.step {
			if t < 1.0 {
				0.0
			} else {
				1.0
			}
		}
		// sine
		.in_sine {
			1.0 - f32(math.cos((t * math.pi) / 2.0))
		}
		.out_sine {
			f32(math.sin((t * math.pi) / 2.0))
		}
		.in_out_sine {
			-(f32(math.cos(math.pi * t)) - 1.0) / 2.0
		}
		// quad
		.in_quad {
			t * t
		}
		.out_quad {
			1.0 - (1.0 - t) * (1.0 - t)
		}
		.in_out_quad {
			if t < 0.5 {
				2.0 * t * t
			} else {
				1.0 - f32(math.pow(-2.0 * t + 2.0, 2)) / 2.0
			}
		}
		// cubic
		.in_cubic {
			t * t * t
		}
		.out_cubic {
			1.0 - f32(math.pow(1.0 - t, 3))
		}
		.in_out_cubic {
			if t < 0.5 {
				4.0 * t * t * t
			} else {
				1.0 - f32(math.pow(-2.0 * t + 2.0, 3)) / 2.0
			}
		}
		// quart
		.in_quart {
			t * t * t * t
		}
		.out_quart {
			1.0 - f32(math.pow(1.0 - t, 4))
		}
		.in_out_quart {
			if t < 0.5 {
				8.0 * t * t * t * t
			} else {
				1.0 - f32(math.pow(-2.0 * t + 2.0, 4)) / 2.0
			}
		}
		// quint
		.in_quint {
			t * t * t * t * t
		}
		.out_quint {
			1.0 - f32(math.pow(1.0 - t, 5))
		}
		.in_out_quint {
			if t < 0.5 {
				16.0 * t * t * t * t * t
			} else {
				1.0 - f32(math.pow(-2.0 * t + 2.0, 5)) / 2.0
			}
		}
		// expo
		.in_expo {
			if t == 0.0 {
				0.0
			} else {
				f32(math.pow(2.0, 10.0 * t - 10.0))
			}
		}
		.out_expo {
			if t == 1.0 {
				1.0
			} else {
				1.0 - f32(math.pow(2.0, -10.0 * t))
			}
		}
		.in_out_expo {
			if t == 0.0 {
				0.0
			} else if t == 1.0 {
				1.0
			} else if t < 0.5 {
				f32(math.pow(2.0, 20.0 * t - 10.0)) / 2.0
			} else {
				(2.0 - f32(math.pow(2.0, -20.0 * t + 10.0))) / 2.0
			}
		}
		// circ
		.in_circ {
			1.0 - f32(math.sqrt(1.0 - math.pow(t, 2)))
		}
		.out_circ {
			f32(math.sqrt(1.0 - math.pow(t - 1.0, 2)))
		}
		.in_out_circ {
			if t < 0.5 {
				(1.0 - f32(math.sqrt(1.0 - math.pow(2.0 * t, 2)))) / 2.0
			} else {
				(f32(math.sqrt(1.0 - math.pow(-2.0 * t + 2.0, 2))) + 1.0) / 2.0
			}
		}
		// back
		.in_back {
			back_c3 * t * t * t - back_c1 * t * t
		}
		.out_back {
			1.0 + back_c3 * f32(math.pow(t - 1.0, 3)) + back_c1 * f32(math.pow(t - 1.0, 2))
		}
		.in_out_back {
			if t < 0.5 {
				(f32(math.pow(2.0 * t, 2)) * ((back_c2 + 1.0) * 2.0 * t - back_c2)) / 2.0
			} else {
				(f32(math.pow(2.0 * t - 2.0, 2)) * ((back_c2 + 1.0) * (2.0 * t - 2.0) + back_c2) +
					2.0) / 2.0
			}
		}
		// elastic
		.in_elastic {
			if t == 0.0 {
				0.0
			} else if t == 1.0 {
				1.0
			} else {
				-f32(math.pow(2.0, 10.0 * t - 10.0)) * f32(math.sin((t * 10.0 - 10.75) * elastic_c4))
			}
		}
		.out_elastic {
			if t == 0.0 {
				0.0
			} else if t == 1.0 {
				1.0
			} else {
				f32(math.pow(2.0, -10.0 * t)) * f32(math.sin((t * 10.0 - 0.75) * elastic_c4)) + 1.0
			}
		}
		.in_out_elastic {
			if t == 0.0 {
				0.0
			} else if t == 1.0 {
				1.0
			} else if t < 0.5 {
				-(f32(math.pow(2.0, 20.0 * t - 10.0)) * f32(math.sin((20.0 * t - 11.125) * elastic_c5))) / 2.0
			} else {
				(f32(math.pow(2.0, -20.0 * t +
					10.0)) * f32(math.sin((20.0 * t - 11.125) * elastic_c5))) / 2.0 + 1.0
			}
		}
		// bounce
		.out_bounce {
			bounce_out(t)
		}
		.in_bounce {
			1.0 - bounce_out(1.0 - t)
		}
		.in_out_bounce {
			if t < 0.5 {
				(1.0 - bounce_out(1.0 - 2.0 * t)) / 2.0
			} else {
				(1.0 + bounce_out(2.0 * t - 1.0)) / 2.0
			}
		}
	}
}
