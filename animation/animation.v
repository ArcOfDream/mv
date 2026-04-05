module animation

pub enum LoopMode {
	none
	loop
	ping_pong
}

pub struct Animation {
pub:
	duration  f32
	loop_mode LoopMode
mut:
	tracks []ITrack
}

pub fn (mut anim Animation) add_track[T](mut target T, keys []Keyframe[T], lerp_fn fn (T, T, f32) T) {
	anim.tracks << Track[T]{
		keys:      keys
		lerp_fn:   lerp_fn
		setter_cb: fn [T](v T) {
			target = v
		}
	}
}

pub fn (mut anim Animation) add_track_cb[T](setter_cb fn (T), keys []Keyframe[T], lerp_fn fn (T, T, f32) T) {
	anim.tracks << Track[T]{
		setter_cb: setter_cb
		keys:      keys
		lerp_fn:   lerp_fn
	}
}

pub fn (mut anim Animation) add_call_track(events []CallEvent) {
	anim.tracks << CallTrack{
		events: events
	}
}

pub fn (mut anim Animation) sample(time f32) {
	for mut tr in anim.tracks {
		tr.sample(time)
	}
}

pub fn (mut anim Animation) reset() {
	for mut tr in anim.tracks {
		tr.reset()
	}
}
