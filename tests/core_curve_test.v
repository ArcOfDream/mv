module main

import mv.core { BakedCurve, Curve, CurvePoint, Vec2 }

// --- constructors ---

fn test_linear_has_two_points() {
	c := Curve.linear()
	assert c.points.len == 2
}

fn test_linear_endpoints() {
	c := Curve.linear()
	assert c.points[0].pos.x == 0.0
	assert c.points[0].pos.y == 0.0
	assert c.points[1].pos.x == 1.0
	assert c.points[1].pos.y == 1.0
}

fn test_flat_has_two_points() {
	c := Curve.flat(0.5)
	assert c.points.len == 2
}

fn test_flat_y_value() {
	c := Curve.flat(0.25)
	assert c.points[0].pos.y == 0.25
	assert c.points[1].pos.y == 0.25
}

fn test_ease_in_out_has_three_points() {
	c := Curve.ease_in_out()
	assert c.points.len == 3
}

// --- sampling ---

fn test_sample_linear_midpoint() {
	c := Curve.linear()
	result := c.sample(0.5)
	assert result > 0.49 && result < 0.51
}

fn test_sample_linear_at_zero() {
	c := Curve.linear()
	assert c.sample(0.0) == 0.0
}

fn test_sample_linear_at_one() {
	c := Curve.linear()
	assert c.sample(1.0) == 1.0
}

fn test_sample_clamps_below_min() {
	mut c := Curve.flat(-1.0)
	c.min_value = 0.0
	assert c.sample(0.5) == 0.0
}

fn test_sample_clamps_above_max() {
	mut c := Curve.flat(2.0)
	c.max_value = 1.0
	assert c.sample(0.5) == 1.0
}

fn test_sample_unbound_bypasses_clamp() {
	mut c := Curve.flat(2.0)
	c.max_value = 1.0
	assert c.sample_unbound(0.5) == 2.0
}

fn test_sample_empty_curve_returns_zero() {
	c := Curve.new()
	assert c.sample(0.5) == 0.0
}

fn test_sample_single_point_returns_its_y() {
	mut c := Curve.new()
	c.add_point(Vec2{0.5, 0.75}, 0.0, 0.0)
	assert c.sample(0.0) == 0.75
	assert c.sample(1.0) == 0.75
}

fn test_sample_extrapolates_flat_at_edges() {
	c := Curve.linear()
	assert c.sample(-1.0) == 0.0
	assert c.sample(2.0) == 1.0
}

// --- add_point sorts by x ---

fn test_add_point_sorts() {
	mut c := Curve.new()
	c.add_point(Vec2{1.0, 1.0}, 0.0, 0.0)
	c.add_point(Vec2{0.0, 0.0}, 0.0, 0.0)
	assert c.points[0].pos.x == 0.0
	assert c.points[1].pos.x == 1.0
}

fn test_add_point_clamps_x_to_zero_one() {
	mut c := Curve.new()
	c.add_point(Vec2{-0.5, 0.0}, 0.0, 0.0)
	assert c.points[0].pos.x == 0.0
	c.add_point(Vec2{1.5, 1.0}, 0.0, 0.0)
	assert c.points.last().pos.x == 1.0
}

fn test_remove_point() {
	mut c := Curve.linear()
	c.remove_point(0)
	assert c.points.len == 1
	assert c.points[0].pos.x == 1.0
}

// --- baking ---

fn test_bake_produces_correct_resolution() {
	c := Curve.linear()
	bc := c.bake(64)
	assert bc.samples.len == 64
}

fn test_baked_sample_linear_midpoint() {
	c := Curve.linear()
	bc := c.bake(256)
	result := bc.sample(0.5)
	assert result > 0.49 && result < 0.51
}

fn test_baked_sample_endpoints() {
	c := Curve.linear()
	bc := c.bake(64)
	assert bc.sample(0.0) == 0.0
	assert bc.sample(1.0) == 1.0
}

fn test_bake_preserves_range() {
	mut c := Curve.linear()
	c.min_value = 0.1
	c.max_value = 0.9
	bc := c.bake(64)
	assert bc.min_value == 0.1
	assert bc.max_value == 0.9
}

fn test_baked_curve_direct_construction() {
	bc := BakedCurve{
		samples:   [f32(0.0), 0.5, 1.0]
		min_value: 0.0
		max_value: 1.0
	}
	assert bc.sample(0.0) == 0.0
	assert bc.sample(1.0) == 1.0
	result := bc.sample(0.5)
	assert result > 0.49 && result < 0.51
}

// --- CurvePoint ---

fn test_curve_point_fields() {
	p := CurvePoint{
		pos:       Vec2{0.3, 0.7}
		tangent_l: 0.5
		tangent_r: 1.0
	}
	assert p.pos.x == 0.3
	assert p.pos.y == 0.7
	assert p.tangent_l == 0.5
	assert p.tangent_r == 1.0
}
