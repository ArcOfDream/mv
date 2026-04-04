module audio

import math { powf }

pub struct AudioBus {
mut:
	name string
	send string
	volume_db f32
	mute bool
	solo bool
}

pub fn db_to_linear(db f32) f32 {
	return powf(10, db / 20)
}