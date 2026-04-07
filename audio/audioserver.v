module audio

import pxtn
import raylib as rl

pub type StreamID = u32

const max_streams = 8
const pxtn_sps = 44100
const pxtn_channels = 2
const pxtn_bps = 16
const buffer_frames = 4096 // ~93ms at 44100 Hz

struct StreamEntry {
pub:
	bus string
}

pub struct AudioServer {
mut:
	next_id      StreamID
	streams      map[StreamID]StreamEntry
	buses        map[string]AudioBus
	audio_thread AudioThread
}

pub fn AudioServer.new() AudioServer {
    mut s := AudioServer{
        audio_thread: start_audio_thread()
    }
    // Default bus layout mirroring Godot's defaults.
    s.buses['master'] = AudioBus{ name: 'master' send: '' }
    s.buses['music']  = AudioBus{ name: 'music'  send: 'master' }
    s.buses['sfx']    = AudioBus{ name: 'sfx'    send: 'master' }
    return s
}

pub fn (mut s AudioServer) process() {
	for {
		select {
			ev := <- s.audio_thread.event_ch {
				// only one type of event is implemented, so we just use AudioEvent directly
				// and assume it's StreamFinishedEvent
				s.streams.delete(ev.id)
			}
			else {
				break
			}
		}
		
		//match ev {
		//	StreamFinishedEvent {
		//		s.streams.delete(ev.id)
		//	}
		//}
	}
}

pub fn (mut s AudioServer) shutdown() {
	s.audio_thread.cmd_ch <- GlobalCmd.quit
	_ := <- s.audio_thread.done_ch
}


// stream allocation

pub fn (mut s AudioServer) alloc_id() !StreamID {
	if s.streams.len >= max_streams {
		return error('audio stream limit reached (${max_streams})')
	}
	id := s.next_id
	s.next_id++
	return id
}

// loads a .ptcop from memory and begins playback
pub fn (mut s AudioServer) play_pxtone(data []u8, bus string) !StreamID {
	id := s.alloc_id()!
	handle := pxtn.from_memory(data)!
	
	rl.set_audio_stream_buffer_size_default(buffer_frames)
	stream := rl.load_audio_stream(pxtn_sps, pxtn_bps, pxtn_channels)
	
	source := PxtoneMusic{
		handle: handle
		stream: stream
		buffer: []u8{ len: buffer_frames * 4 }
	}
	
	s.streams[id] = StreamEntry{ bus: bus }
	s.audio_thread.cmd_ch <- LoadMsg{ id: id, source: source }
	s.audio_thread.cmd_ch <- VolumeMsg{ id: id, volume: s.effective_volume(bus) }
	return id
}

// loads a Raylib-native file format (MP3, OGG, FLAC, XM, MOD) by path
pub fn (mut s AudioServer) play_file(path string, bus string) !StreamID {
	id := s.alloc_id()!
	music := rl.load_music_stream(path)
	
	s.streams[id] = StreamEntry{ bus: bus }
	s.audio_thread.cmd_ch <- LoadMsg{ id: id, source: RaylibMusic{ music: music } }
	s.audio_thread.cmd_ch <- VolumeMsg{ id: id, volume: s.effective_volume(bus) }
	return id
}

// loads a Raylib-native file format from a memory slice
// the ext parameter expects the file extension e.g. '.flac', '.ogg' etc.
pub fn (mut s AudioServer) play_from_memory(ext string, data []u8, bus string) !StreamID {
	id := s.alloc_id()!
	music := rl.load_music_stream_from_memory(ext, data.data, data.len)
	
	s.streams[id] = StreamEntry{ bus: bus }
	s.audio_thread.cmd_ch <- LoadMsg{ id: id, source: RaylibMusic{ music: music } }
	s.audio_thread.cmd_ch <- VolumeMsg{ id: id, volume: s.effective_volume(bus) }
	return id
}

pub fn (mut s AudioServer) play_music(source &MusicSource, bus string) !StreamID {
	id := s.alloc_id()!

	s.streams[id] = StreamEntry{
		bus: bus
	}
	s.audio_thread.cmd_ch <- LoadMsg{
		id:     id
		source: source
	}

	// applying initial volume here
	vol := s.effective_volume(bus)
	s.audio_thread.cmd_ch <- VolumeMsg{
		id:     id
		volume: vol
	}

	return id
}

// stream control funcs

pub fn (s &AudioServer) stop(id StreamID) {
    s.audio_thread.cmd_ch <- StopMsg{ id: id }
}

pub fn (s &AudioServer) pause(id StreamID) {
    s.audio_thread.cmd_ch <- PauseMsg{ id: id }
}

pub fn (s &AudioServer) resume(id StreamID) {
    s.audio_thread.cmd_ch <- ResumeMsg{ id: id }
}

pub fn (s &AudioServer) seek(id StreamID, position f32) {
    s.audio_thread.cmd_ch <- SeekMsg{ id: id, position: position }
}

pub fn (s &AudioServer) loop(id StreamID, toggle bool) {
	s.audio_thread.cmd_ch <- LoopMsg{ id: id, toggle: toggle }
}

pub fn (mut s AudioServer) unload(id StreamID) {
    s.streams.delete(id)
    s.audio_thread.cmd_ch <- UnloadMsg{ id: id }
}

// bus control funcs

pub fn (mut s AudioServer) set_bus_volume(bus_name string, db f32) {
    mut bus := s.buses[bus_name] or { return }
    bus.volume_db = db
    s.buses[bus_name] = bus
    s.propagate_volume(bus_name)
}

pub fn (mut s AudioServer) set_bus_mute(bus_name string, mute bool) {
    mut bus := s.buses[bus_name] or { return }
    bus.mute = mute
    s.buses[bus_name] = bus
    s.propagate_volume(bus_name)
}

// propagate_volume recomputes and sends VolumeMsg for every stream
// whose send chain passes through the named bus
fn (s &AudioServer) propagate_volume(bus_name string) {
    for id, entry in s.streams {
        if s.bus_in_chain(entry.bus, bus_name) {
            vol := s.effective_volume(entry.bus)
            s.audio_thread.cmd_ch <- VolumeMsg{ id: id, volume: vol }
        }
    }
}

// effective_volume walks the send chain from bus_name to master,
// multiplying linear volumes 
// returns 0.0 if any bus in the chain is muted
fn (s &AudioServer) effective_volume(bus_name string) f32 {
    mut vol  := f32(1.0)
    mut name := bus_name
    for {
        bus := s.buses[name] or { break }
        if bus.mute { return 0.0 }
        vol *= db_to_linear(bus.volume_db)
        if bus.send == '' { break }
        name = bus.send
    }
    return vol
}

// bus_in_chain returns true if target_bus appears anywhere in the
// send chain starting from from_bus
fn (s &AudioServer) bus_in_chain(from_bus string, target_bus string) bool {
    mut name := from_bus
    for {
        if name == target_bus { return true }
        bus := s.buses[name] or { break }
        if bus.send == '' { break }
        name = bus.send
    }
    return false
}

