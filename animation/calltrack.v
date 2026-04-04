module animation

pub struct CallEvent {
	time     f32
	callback fn () @[required]
}

pub struct CallTrack implements ITrack {
mut:
	events    []CallEvent
	last_time f32 // tracks previous sample time to catch crossings
}

pub fn (mut tr CallTrack) sample(time f32) {
	for e in tr.events {
		if e.time > tr.last_time && e.time <= time {
			e.callback()
		}
	}
	tr.last_time = time
}

pub fn (mut tr CallTrack) reset() {
	tr.last_time = 0.0
}
