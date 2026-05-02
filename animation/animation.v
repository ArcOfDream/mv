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

// add_track registers a new track that writes animated values into `target`.
//
// NOTE: V's closure capture for mutable function parameters (`mut target`)
// has compiler-version-dependent semantics.  The `fn [T]` below defines a
// generic closure (type param shadows outer T); `target` is captured from
// the enclosing scope.  This compiles and works on current V but relies on
// V's implicit capture of mutable parameters.  See code-review.md item #4
// for the caveat.
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
