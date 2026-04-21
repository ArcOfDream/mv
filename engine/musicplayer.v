module engine

import audio

/*
MusicPlayer: usage example

MusicPlayer wraps AudioServer stream management as a node. It holds one
active stream at a time; calling any play method stops the current stream
before starting the new one.

	mut bgm := MusicPlayer.new(app, 'BGM')
	scene_root.add_child(mut bgm)

	// play a .ptcop file loaded into memory (e.g. from rres)
	data := os.read_bytes('assets/theme.ptcop')!
	bgm.play_pxtone(data)!

	// play a file path (MP3, OGG, FLAC, XM, MOD via Raylib)
	bgm.play_file('assets/ambient.ogg')!

	// play from a memory slice with format hint
	bgm.play_from_memory('.ogg', ogg_bytes)!

	// transport controls
	bgm.pause()    // toggle pause
	bgm.resume()
	bgm.seek(4.5)  // jump to 4.5 seconds
	bgm.loop(true) // enable looping
	bgm.stop()

MusicPlayer routes to the 'Music' bus by default. To route to a different
bus, set the field before calling play:

	bgm.bus = 'Ambient'
	bgm.play_file('rain.ogg')!

Bus volume and mute are controlled on the AudioServer directly:

	app.audio_server.set_bus_volume('Music', -6.0)  // decibels
	app.audio_server.set_bus_mute('Music', true)

To crossfade between two tracks, use two MusicPlayer nodes on the same bus
and tween their streams' volumes via the AudioServer's per-stream volume,
or fade the bus itself.
*/

@[heap]
pub struct MusicPlayer {
	Node
pub mut:
	bus string = 'Music'
mut:
	process_flags ProcessFlags
	stream_id     ?audio.StreamID
}

pub fn MusicPlayer.instantiate(app &App, name string) &MusicPlayer {
	return &MusicPlayer{
		app:       app
		node_name: name
	}
}

pub fn MusicPlayer.new(app &App, name string) &MusicPlayer {
	return &MusicPlayer{
		app:       app
		node_name: name
	}
}

fn (n &MusicPlayer) wren_class_name() string {
	return 'MusicPlayer'
}

pub fn (mut p MusicPlayer) play_pxtone(data []u8) ! {
	p.stop()
	id := p.app.audio_server.play_pxtone(data, p.bus)!
	p.stream_id = id
}

pub fn (mut p MusicPlayer) play_file(path string) ! {
	p.stop()
	id := p.app.audio_server.play_file(path, p.bus)!
	p.stream_id = id
}

pub fn (mut p MusicPlayer) stop() {
	if id := p.stream_id {
		p.app.audio_server.unload(id)
	}
}

pub fn (p &MusicPlayer) pause() {
	if id := p.stream_id {
		p.app.audio_server.pause(id)
	}
}

pub fn (p &MusicPlayer) resume() {
	if id := p.stream_id {
		p.app.audio_server.resume(id)
	}
}

pub fn (p &MusicPlayer) seek(position f32) {
	if id := p.stream_id {
		p.app.audio_server.seek(id, position)
	}
}

pub fn (p &MusicPlayer) loop(toggle bool) {
	if id := p.stream_id {
		p.app.audio_server.loop(id, toggle)
	}
}

// called by AudioServer.process() when the stream ends naturally
pub fn (mut p MusicPlayer) on_stream_finished() {
	p.stream_id = none
	// emit signal here
}
