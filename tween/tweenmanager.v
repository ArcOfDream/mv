module tween

pub struct TweenManager {
mut:
	tweeners []ITweener
}

pub fn (mut m TweenManager) update(dt f32) {
	for mut tw in m.tweeners {
		tw.update(dt)
	}
	m.tweeners = m.tweeners.filter(!it.is_done())
}

pub fn (mut m TweenManager) tween[T](target &T, from T, to T, dur f32, ease Ease, lerp fn (T, T, f32) T) {
	m.tweeners << Tweener[T]{
		target:   target
		from:     from
		to:       to
		duration: dur
		ease:     ease
		lerp_fn:  lerp
	}
}

pub fn (mut m TweenManager) cb_tween[T](cb fn (T), from T, to T, dur f32, ease Ease, lerp fn (T, T, f32) T) {
	m.tweeners << Tweener[T]{
		from:     from
		to:       to
		duration: dur
		ease:     ease
		lerp_fn:  lerp
		callback_fn : cb
	}
}
