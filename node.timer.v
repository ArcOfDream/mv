module mv

@[heap]
pub struct Timer {
	Node
pub mut:
	wait_time  f32  = 1
	one_shot   bool = true
	autostart  bool
	on_timeout ?fn ()
mut:
	process_flags ProcessFlags
	elapsed       f32
	running       bool
}

pub fn Timer.new(app &App, name string, timeout_fn ?fn ()) &Timer {
	return &Timer{
		node_name:  name
		app:        app
		on_timeout: timeout_fn
	}
}

pub fn (mut t Timer) ready_internal() {
	if t.autostart {
		t.start()
	}
}

pub fn (mut t Timer) process_internal(dt f32) {
	if !t.running {
		return
	}

	t.elapsed += dt
	if t.elapsed >= t.wait_time {
		t.elapsed = if t.one_shot { t.elapsed } else { t.elapsed - t.wait_time }
		if t.one_shot {
			t.running = false
		}
		if func := t.on_timeout {
			func()
		}
	}
}

pub fn (mut t Timer) start() {
	t.elapsed = 0.0
	t.running = true
}

pub fn (mut t Timer) stop() {
	t.elapsed = 0.0
	t.running = false
}

pub fn (mut t Timer) pause() {
	t.running = false
}

pub fn (mut t Timer) resume() {
	t.running = true
}

pub fn (t &Timer) time_left() f32 {
	if !t.running {
		return 0.0
	}
	return t.wait_time - t.elapsed
}

pub fn (t &Timer) is_running() bool {
	return t.running
}
