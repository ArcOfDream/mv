module animation

pub struct AnimationPlayer {
mut:
	library   map[string]Animation
	current   string
	time      f32
	speed     f32 = 1.0
	direction f32 = 1.0 // -1 during ping-pong return
	playing   bool
	on_finish ?fn (name string)
}

pub fn (mut ap AnimationPlayer) add(name string, anim Animation) {
	ap.library[name] = anim
}

pub fn (mut ap AnimationPlayer) play(name string) {
	if name !in ap.library {
		return
	}
	ap.current = name
	ap.time = 0.0
	ap.direction = 1.0
	ap.playing = true
	ap.library[name].reset()
}

pub fn (mut ap AnimationPlayer) stop() {
	ap.playing = false
	ap.time = 0.0
}

pub fn (mut ap AnimationPlayer) pause() {
	ap.playing = !ap.playing
}

pub fn (mut ap AnimationPlayer) seek(time f32) {
	if ap.current !in ap.library {
		return
	}
	ap.time = time
	ap.library[ap.current].sample(time)
}

pub fn (mut ap AnimationPlayer) update(dt f32) {
	if !ap.playing || ap.current !in ap.library {
		return
	}

	mut anim := ap.library[ap.current]
	ap.time += dt * ap.speed * ap.direction

	match anim.loop_mode {
		.none {
			if ap.time >= anim.duration {
				ap.time = anim.duration
				ap.playing = false
				anim.sample(ap.time)
				if cb := ap.on_finish {
					cb(ap.current)
				}
				return
			}
		}
		.loop {
			// Wrap — also resets call track crossing detection cleanly
			if ap.time >= anim.duration {
				anim.reset()
				ap.time = ap.time - anim.duration
			}
		}
		.ping_pong {
			if ap.time >= anim.duration {
				ap.time = anim.duration
				ap.direction = -1.0
			} else if ap.time <= 0.0 {
				ap.time = 0.0
				ap.direction = 1.0
			}
		}
	}

	anim.sample(ap.time)
	// Write back — map returns a copy in V
	ap.library[ap.current] = anim
}
