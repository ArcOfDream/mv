module mv

import audio

pub struct MusicPlayer {
	Node
pub mut:
    bus       string = 'Music'
mut:
	process_flags ProcessFlags
    stream_id ?audio.StreamID
}

pub fn MusicPlayer.new(app &App, name string) &MusicPlayer {
	return &MusicPlayer{
		app: app
		node_name: name
	}
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

// Called by AudioServer.process() when the stream ends naturally.
pub fn (mut p MusicPlayer) on_stream_finished() {
    p.stream_id = none
    // emit signal here
}