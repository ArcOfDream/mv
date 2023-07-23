module math

pub struct Vec2i {
pub mut:
	x int
	y int
}

pub fn (a Vec2i) str() string {
	return '{${a.x}, ${a.y}}'
}

[inline]
fn (a Vec2i) + (b Vec2i) Vec2i {
	return Vec2i{a.x + b.x, a.y + b.y}
}

[inline]
fn (a Vec2i) - (b Vec2i) Vec2i {
	return Vec2i{a.x - b.x, a.y - b.y}
}

[inline]
fn (a Vec2i) * (b Vec2i) Vec2i {
	return Vec2i{a.x * b.x, a.y * b.y}
}

[inline]
fn (a Vec2i) / (b Vec2i) Vec2i {
	return Vec2i{a.x / b.x, a.y / b.y}
}

[inline]
pub fn (self Vec2i) as_vec2() Vec2 {
	return Vec2{self.x, self.y}
}

[inline]
pub fn (a Vec2i) eq(b Vec2i) bool {
	return a.x == b.x && a.y == b.y
}

[inline]
pub fn (self Vec2i) scale(s int) Vec2i {
	return Vec2i{self.x * s, self.y * s}
}

[inline]
pub fn (self Vec2i) mul(s int) Vec2i {
	return Vec2i{self.x * s, self.y * s}
}

[inline]
pub fn (self Vec2i) abs() Vec2i {
	return Vec2i{abs(self.x), abs(self.y)}
}

[inline]
pub fn (self Vec2i) sq_magnitude() int {
	return self.x * self.x + self.y * self.y
}

[inline]
pub fn (self Vec2i) magnitude() int {
	return int(sqrt(self.sq_magnitude()))
}

// [inline]
// pub fn (self Vec2i) normalize() Vec2i { return self.scale(1 / self.magnitude()) }

[inline]
pub fn (self Vec2i) dot(other Vec2i) int {
	return self.x * other.x + self.y * other.y
}

[inline]
pub fn (self Vec2i) cross(other Vec2i) int {
	return self.x * other.y - self.y * other.x
}

[inline]
pub fn (self Vec2i) distance_to(other Vec2i) int {
	return (other - self).magnitude()
}

[inline]
pub fn (self Vec2i) sq_distance_to(other Vec2i) int {
	return (other - self).sq_magnitude()
}
