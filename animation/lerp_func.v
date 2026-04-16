module tween

import raylib { Color, color_lerp }

@[inline]
pub fn lerp_f32(a f32, b f32, t f32) f32 {
	return a + (b - a) * t
}

pub fn lerp_generic[T](a T, b T, t f32) T {
	return a + (b - a) * T(t)
}

pub fn lerp_vec2(a C.Vector2, b C.Vector2, t f32) C.Vector2 {
	return C.Vector2{lerp_f32(a.x, b.x, t), lerp_f32(a.y, b.y, t)}
}

pub fn lerp_color(a Color, b Color, t f32) Color {
	return color_lerp(a, b, t)
}
