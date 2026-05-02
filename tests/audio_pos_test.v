module tests

import mv.audio

fn test_sample_pos_defaults_to_zero_for_unknown_id() {
	mut srv := audio.AudioServer.new()
	defer { srv.shutdown() }
	assert srv.sample_pos(audio.StreamID(99)) == 0
}
