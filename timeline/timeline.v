module timeline

pub struct TimelineEvent {
	frame    int
	callback fn ()
}

pub struct Timeline {
mut:
	events  []TimelineEvent
	cursor  int // index into events, not the frame number
	current int // current frame
	playing bool
}

pub fn (mut tl Timeline) add(frame int, callback fn ()) {
	tl.events << TimelineEvent{
		frame:    frame
		callback: callback
	}
	// keep sorted so the cursor advance is a simple forward scan
	tl.events.sort(a.frame < b.frame)
}

pub fn (mut tl Timeline) play() {
	tl.playing = true
}

pub fn (mut tl Timeline) stop() {
	tl.playing = false
}

pub fn (mut tl Timeline) reset() {
	tl.current = 0
	tl.cursor = 0
	tl.playing = false
}

pub fn (mut tl Timeline) seek(frame int) {
	tl.current = frame
	// reposition cursor to the first event at or after this frame
	tl.cursor = 0
	for i, e in tl.events {
		if e.frame >= frame {
			tl.cursor = i
			break
		}
		tl.cursor = tl.events.len // seeked past everything
	}
}

// call once per game frame — fires all events that land on the current frame,
// then advances. Handles multiple events on the same frame naturally.
pub fn (mut tl Timeline) step() {
	if !tl.playing {
		return
	}

	for tl.cursor < tl.events.len && tl.events[tl.cursor].frame == tl.current {
		tl.events[tl.cursor].callback()
		tl.cursor++
	}

	tl.current++
}

// if you want to jump multiple frames at once (e.g. catch-up after a lag spike)
// and fire every event in between rather than skipping them:
pub fn (mut tl Timeline) step_by(frames int) {
	for _ in 0 .. frames {
		tl.step()
	}
}
