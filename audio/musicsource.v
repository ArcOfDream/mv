module audio

import raylib as rl
import mv.pxtn { Pxtone }

// musicsource.v implements the types of audio streams handled by the engine

pub struct RaylibMusic {
pub mut:
	music rl.Music
}

pub struct PxtoneMusic {
pub mut:
	handle &Pxtone
	stream rl.AudioStream
	buffer []u8
}

pub type MusicSource = RaylibMusic | PxtoneMusic

// methods to keep the audio thread logic clean

@[inline]
fn init_source(s &MusicSource) {
	match s {
		RaylibMusic { rl.play_music_stream(s.music) }
		PxtoneMusic { rl.play_audio_stream(s.stream) }
	}
}

@[inline]
fn stop_source(s &MusicSource) {
	match s {
		RaylibMusic { rl.stop_music_stream(s.music) }
		PxtoneMusic { rl.stop_audio_stream(s.stream) }
	}
}

@[inline]
fn pause_source(s &MusicSource) {
	match s {
		RaylibMusic { rl.pause_music_stream(s.music) }
		PxtoneMusic { rl.pause_audio_stream(s.stream) }
	}
}

@[inline]
fn resume_source(s &MusicSource) {
	match s {
		RaylibMusic { rl.resume_music_stream(s.music) }
		PxtoneMusic { rl.play_audio_stream(s.stream) }
	}
}

@[inline]
fn seek_source(s &MusicSource, pos f32) {
	match s {
		RaylibMusic {
			rl.seek_music_stream(s.music, pos)
		}
		PxtoneMusic {
			frame := usize(pos * pxtn_sps)
			s.handle.seek(frame)
		}
	}
}

@[inline]
fn apply_volume(s &MusicSource, vol f32) {
	match s {
		RaylibMusic { rl.set_music_volume(s.music, vol) }
		PxtoneMusic { rl.set_audio_stream_volume(s.stream, vol) }
	}
}

@[inline]
fn unload_source(s &MusicSource) {
	match s {
		RaylibMusic {
			rl.unload_music_stream(s.music)
		}
		PxtoneMusic {
			rl.stop_audio_stream(s.stream)
			rl.unload_audio_stream(s.stream)
			s.handle.close()
		}
	}
}

// returns true if the stream has finished playing by itself
@[inline]
fn update_source(mut s MusicSource) bool {
	match mut s {
		RaylibMusic {
			rl.update_music_stream(s.music)
			return !rl.is_music_stream_playing(s.music)
		}
		PxtoneMusic {
			if !rl.is_audio_stream_processed(s.stream) {
				return false
			}

			written := s.handle.gen_buffer(s.buffer.data, buffer_frames)
			rl.update_audio_stream(s.stream, s.buffer.data, int(written))
			if written < buffer_frames {
				if s.handle.get_loop() {
					s.handle.seek(s.handle.repeat_sample())
					return false
				}
				return true
			}
			return false
		}
	}
}
