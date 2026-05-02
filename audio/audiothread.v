module audio

import time

struct AudioThread {
	cmd_ch      chan AudioMessage // messages to send to the audio thread
	event_ch    chan AudioEvent   // events recieved from the audio thread
	done_ch     chan bool         // signals clean shutdown
	waveform_ch chan WaveformMsg  // latest mono waveform with fill timestamp
}

struct WaveformMsg {
	data      []f32
	fill_time i64 // time.now().unix_nano() recorded in the audio thread at fill time
}

struct ActiveStream {
mut:
	src     MusicSource
	playing bool
	volume  f32
	bus     string
}

pub fn start_audio_thread() AudioThread {
	cmd_ch := chan AudioMessage{cap: 16}
	event_ch := chan AudioEvent{cap: 64}
	done_ch := chan bool{cap: 1}
	waveform_ch := chan WaveformMsg{cap: 2}

	spawn fn [cmd_ch, event_ch, done_ch, waveform_ch] () {
		audio_thread_loop(cmd_ch, event_ch, done_ch, waveform_ch)
	}()

	return AudioThread{
		cmd_ch:      cmd_ch
		event_ch:    event_ch
		done_ch:     done_ch
		waveform_ch: waveform_ch
	}
}

fn audio_thread_loop(cmd_ch chan AudioMessage, event_ch chan AudioEvent, done_ch chan bool, waveform_ch chan WaveformMsg) {
	mut streams := map[StreamID]&ActiveStream{}

	for {
		// draining pending commands from cmd_ch
		for {
			select {
				msg := <-cmd_ch {
					match msg {
						LoadMsg {
							streams[msg.id] = &ActiveStream{
								src:     msg.source
								playing: true
								volume:  1.0
							}
							init_source(msg.source)
						}
						StopMsg {
							if mut s := streams[msg.id] {
								stop_source(s.src)
								s.playing = false
							}
						}
						PauseMsg {
							if mut s := streams[msg.id] {
								pause_source(s.src)
								s.playing = false
							}
						}
						ResumeMsg {
							if mut s := streams[msg.id] {
								resume_source(s.src)
								s.playing = true
							}
						}
						SeekMsg {
							if mut s := streams[msg.id] {
								seek_source(s.src, msg.position)
							}
						}
						VolumeMsg {
							if mut s := streams[msg.id] {
								s.volume = msg.volume
								apply_volume(s.src, msg.volume)
							}
						}
						LoopMsg {
							if mut s := streams[msg.id] {
								set_loop(mut s.src, msg.toggle)
							}
						}
						UnloadMsg {
							if s := streams[msg.id] {
								unload_source(s.src)
								streams.delete(msg.id)
							}
						}
						GlobalCmd {
							match msg {
								.quit {
									for _, s in streams {
										unload_source(s.src)
									}
									done_ch <- true
									return
								}
							}
						}
					}
				}
				else {
					break
				}
			}
		}

		// update all active streams; collect finished IDs
		mut finished := []StreamID{}
		for id, mut s in streams {
			if !s.playing {
				continue
			}
			finished_now := update_source(mut s.src)
			if finished_now {
				s.playing = false
				finished << id
			} else {
				select {
					event_ch <- StreamPosEvent{
						id:     id
						sample: get_source_pos(s.src)
					} {}
					else {}
				}
				// Capture full buffer as mono f32 for smooth oscilloscope scrolling.
				if mut s.src is PxtoneMusic {
					buf := s.src.buffer
					n := buf.len / 4
					mut snap := []f32{len: n}
					for fi in 0 .. n {
						l := i16(u16(buf[fi * 4]) | (u16(buf[fi * 4 + 1]) << 8))
						r := i16(u16(buf[fi * 4 + 2]) | (u16(buf[fi * 4 + 3]) << 8))
						snap[fi] = f32(int(l) + int(r)) / 65536.0
					}
					msg := WaveformMsg{
						data:      snap
						fill_time: time.now().unix_nano()
					}
					select {
						waveform_ch <- msg {}
						else {}
					}
				}
			}
		}

		// fire finish events without holding the loop
		for id in finished {
			event_ch <- StreamFinishedEvent{
				id: id
			}
		}

		time.sleep(2 * time.millisecond)
	}
}
