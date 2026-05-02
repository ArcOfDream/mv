module core

type StateValue = Vec2 | bool | f32 | i64 | string

@[heap]
pub struct GameState {
mut:
	user_data voidptr = unsafe { nil }
	data      map[string]StateValue
	dt        f32
}

pub fn (gs &GameState) dt() f32 {
	return gs.dt
}

pub fn (mut gs GameState) set_dt(val f32) {
	gs.dt = val
}

pub fn (mut gs GameState) set(key string, val StateValue) {
	gs.data[key] = val
}

pub fn (mut gs GameState) set_user_data[T](data &T) {
	gs.user_data = voidptr(data)
}

pub fn (gs GameState) get_user_data[T]() &T {
	if gs.user_data == unsafe { nil } {
		panic('Accessing user_data before it is set')
	}
	return &T(gs.user_data)
}

pub fn (gs GameState) get[T](key string) ?T {
	val := gs.data[key]

	if val is T {
		return val
	}
	return none
}

// pub fn (gs GameState) get_f32(key string) f32 {
// 	val := gs.data[key] or { return 0 }

// 	if val is f32 { return val }
// 	return 0
// }

// pub fn (gs GameState) get_i64(key string) i64 {
// 	val := gs.data[key] or { return 0 }

// 	if val is i64 { return val }
// 	return 0
// }

// pub fn (gs GameState) get_bool(key string) bool {
// 	val := gs.data[key] or { return false }

// 	if val is bool { return val }
// 	return false
// }

// pub fn (gs GameState) get_string(key string) string {
// 	val := gs.data[key] or { return "" }

// 	if val is string { return val }
// 	return ""
// }
