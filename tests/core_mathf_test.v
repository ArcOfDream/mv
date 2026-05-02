module main

import mv.core

fn test_approach_toward_target() {
	assert core.approach(2.0, 10.0, 4.0) == 6.0
}

fn test_approach_clamps_at_target() {
	assert core.approach(8.0, 10.0, 4.0) == 10.0
}

fn test_approach_from_above() {
	assert core.approach(10.0, 2.0, 4.0) == 6.0
}

fn test_approach_from_above_clamps() {
	assert core.approach(4.0, 2.0, 4.0) == 2.0
}

fn test_unlerp_midpoint() {
	assert core.unlerp(0.0, 10.0, 5.0) == 0.5
}

fn test_unlerp_at_start() {
	assert core.unlerp(0.0, 10.0, 0.0) == 0.0
}

fn test_unlerp_at_end() {
	assert core.unlerp(0.0, 10.0, 10.0) == 1.0
}

fn test_unlerp_extrapolates() {
	assert core.unlerp(0.0, 10.0, 15.0) == 1.5
}

fn test_remap_basic() {
	result := core.remap(0.0, 1.0, 0.0, 100.0, 0.5)
	assert result == 50.0
}

fn test_remap_different_ranges() {
	result := core.remap(0.0, 10.0, 100.0, 200.0, 5.0)
	assert result == 150.0
}

fn test_between_inside() {
	assert core.between(5.0, 0.0, 10.0) == true
}

fn test_between_at_lo() {
	assert core.between(0.0, 0.0, 10.0) == true
}

fn test_between_at_hi() {
	assert core.between(10.0, 0.0, 10.0) == true
}

fn test_between_outside() {
	assert core.between(11.0, 0.0, 10.0) == false
}

fn test_repeat_basic() {
	assert core.repeat(0.5, 1.0) == 0.5
}

fn test_repeat_wraps_at_length() {
	result := core.repeat(1.0, 1.0)
	assert result == 0.0
}

fn test_repeat_negative() {
	result := core.repeat(-0.1, 1.0)
	assert result > 0.89 && result < 0.91
}

fn test_ping_pong_forward() {
	assert core.ping_pong(0.25, 1.0) == 0.25
}

fn test_ping_pong_at_peak() {
	assert core.ping_pong(1.0, 1.0) == 1.0
}

fn test_ping_pong_return() {
	result := core.ping_pong(1.5, 1.0)
	assert result > 0.49 && result < 0.51
}

fn test_ceilpow2_int_exact() {
	assert core.ceilpow2_int(8) == 8
}

fn test_ceilpow2_int_rounds_up() {
	assert core.ceilpow2_int(9) == 16
}

fn test_ceilpow2_int_one() {
	assert core.ceilpow2_int(1) == 1
}

fn test_ceilpow2_int_large() {
	assert core.ceilpow2_int(1000) == 1024
}

fn test_ceilpow2_i64_exact() {
	assert core.ceilpow2_i64(i64(64)) == i64(64)
}

fn test_ceilpow2_i64_rounds_up() {
	assert core.ceilpow2_i64(i64(65)) == i64(128)
}

fn test_ceilpow2_i64_zero() {
	assert core.ceilpow2_i64(i64(0)) == i64(1)
}
