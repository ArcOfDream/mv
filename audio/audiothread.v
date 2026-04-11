module audio

import time

struct AudioThread {
	cmd_ch   chan AudioMessage // messages to send to the audio thread
	event_ch chan AudioEvent   // events recieved from the audio thread
	done_ch  chan bool         // signals clean shutdown
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
	event_ch := chan AudioEvent{cap: 16}
	done_ch := chan bool{cap: 1}

	spawn fn [cmd_ch, event_ch, done_ch] () {
		audio_thread_loop(cmd_ch, event_ch, done_ch)
	}()

	return AudioThread{
		cmd_ch:   cmd_ch
		event_ch: event_ch
		done_ch:  done_ch
	}
}

fn audio_thread_loop(cmd_ch chan AudioMessage, event_ch chan AudioEvent, done_ch chan bool) {
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
			if update_source(mut s.src) {
				s.playing = false
				finished << id
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
