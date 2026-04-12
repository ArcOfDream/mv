module mv

import raylib.raymath as rm
import math

pub type Vec2 = C.Vector2

pub const vec2_one = Vec2{1, 1}
pub const vec2_unit_x = Vec2{1, 0}
pub const vec2_unit_y = Vec2{0, 1}

pub fn Vec2.f32(f f32) Vec2 {
	return Vec2{f, f}
}

pub fn (v Vec2) length() f32 {
	return rm.vector2_length(v)
}

pub fn (v Vec2) length_sqr() f32 {
	return rm.vector2_length_sqr(v)
}

pub fn (v Vec2) dot(v2 Vec2) f32 {
	return rm.vector_2dot_product(v, v2)
}

pub fn (v Vec2) cross(v2 Vec2) f32 {
	return rm.vector2_cross_product(v, v2)
}

pub fn (v Vec2) distance(v2 Vec2) f32 {
	return rm.vector_2distance(v, v2)
}

pub fn (v Vec2) distance_sqr(v2 Vec2) f32 {
	return rm.vector_2distance_sqr(v, v2)
}

pub fn (v Vec2) angle(v2 Vec2) f32 {
	return rm.vector2_angle(v, v2)
}

pub fn (v Vec2) line_angle(v2 Vec2) f32 {
	return rm.vector2_line_angle(v, v2)
}

pub fn (v Vec2) scale(f f32) Vec2 {
	result := rm.vector2_scale(v, f)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) normalize() Vec2 {
	result := rm.vector2_normalize(v)
	return Vec2{result.x, result.y}
}

pub fn (a Vec2) + (b Vec2) Vec2 {
	return Vec2{a.x + b.x, a.y + b.y}
}

pub fn (a Vec2) - (b Vec2) Vec2 {
	return Vec2{a.x - b.x, a.y - b.y}
}

pub fn (a Vec2) * (b Vec2) Vec2 {
	return Vec2{a.x * b.x, a.y * b.y}
}

pub fn (a Vec2) / (b Vec2) Vec2 {
	if b.x == 0 || b.y == 0 {
		return Vec2{0, 0}
	}
	return Vec2{a.x / b.x, a.y / b.y}
}

pub fn (a Vec2) == (b Vec2) bool {
	return rm.float_equals(a.x, b.x) != 0 && rm.float_equals(a.y, b.y) != 0
}

pub fn (a Vec2) < (b Vec2) bool {
	return a.x < b.x && a.y < b.y
}

pub fn (a Vec2) % (b Vec2) Vec2 {
	mut x := f32(math.mod(a.x, b.x))
	mut y := f32(math.mod(a.y, b.y))

	if x == math.nan() {
		x = 0
	}
	if y == math.nan() {
		y = 0
	}

	return Vec2{x, y}
}
