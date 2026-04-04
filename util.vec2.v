module mv

import raylib.raymath as rm
import math

pub type Vec2 = C.Vector2

pub const vec2_one = Vec2{1, 1}
pub const vec2_unit_x = Vec2{1, 0}
pub const vec2_unit_y = Vec2{0, 1}

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
	return rm.float_equals(a.x, b.x) == 1 && rm.float_equals(a.y, b.y) == 1
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
