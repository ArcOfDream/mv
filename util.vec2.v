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

pub fn (v Vec2) lerp(v2 Vec2, t f32) Vec2 {
	result := rm.vector2_lerp(v, v2, t)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) reflect(normal Vec2) Vec2 {
	result := rm.vector2_reflect(v, normal)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) rotate(angle f32) Vec2 {
	result := rm.vector2_rotate(v, angle)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) move_towards(target Vec2, max_dist f32) Vec2 {
	result := rm.vector2_move_towards(v, target, max_dist)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) clamp(min Vec2, max Vec2) Vec2 {
	result := rm.vector2_clamp(v, min, max)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) clamp_value(min f32, max f32) Vec2 {
	result := rm.vector2_clamp_value(v, min, max)
	return Vec2{result.x, result.y}
}

pub fn (v Vec2) invert() Vec2 {
	result := rm.vector2_invert(v)
	return Vec2{result.x, result.y}
}

@[inline]
pub fn (v Vec2) add_value(f f32) Vec2 {
	return Vec2{v.x + f, v.y + f}
}

@[inline]
pub fn (v Vec2) subtract_value(f f32) Vec2 {
	return Vec2{v.x - f, v.y - f}
}

@[inline]
pub fn (v Vec2) negate() Vec2 {
	return Vec2{-v.x, -v.y}
}

@[inline]
pub fn (v Vec2) perpendicular() Vec2 {
	return Vec2{-v.y, v.x}
}

@[inline]
pub fn (v Vec2) abs() Vec2 {
	return Vec2{math.abs(v.x), math.abs(v.y)}
}

@[inline]
pub fn (v Vec2) floor() Vec2 {
	return Vec2{math.floorf(v.x), math.floorf(v.y)}
}

@[inline]
pub fn (v Vec2) ceil() Vec2 {
	return Vec2{f32(math.ceil(v.x)), f32(math.ceil(v.y))}
}

@[inline]
pub fn (v Vec2) round() Vec2 {
	return Vec2{f32(math.round(v.x)), f32(math.round(v.y))}
}

@[inline]
pub fn (v Vec2) min(v2 Vec2) Vec2 {
	return Vec2{f32(math.min(v.x, v2.x)), f32(math.min(v.y, v2.y))}
}

@[inline]
pub fn (v Vec2) max(v2 Vec2) Vec2 {
	return Vec2{f32(math.max(v.x, v2.x)), f32(math.max(v.y, v2.y))}
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
