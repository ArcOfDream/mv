module audio

pub type StreamId = u32

// commands (main → audio thread)

pub struct LoadMsg {
pub:
	id     StreamId
	source MusicSource
}

pub struct StopMsg {
pub:
	id StreamId
}

pub struct PauseMsg {
pub:
	id StreamId
}

pub struct ResumeMsg {
pub:
	id StreamId
}

pub struct UnloadMsg {
pub:
	id StreamId
}

pub struct SeekMsg {
pub:
	id       StreamId
	position f32
} // always in seconds

pub struct VolumeMsg {
pub:
	id     StreamId
	volume f32
} // linear [0.0, 1.0]

pub enum GlobalCmd {
	quit
}

pub type AudioMessage = LoadMsg
	| StopMsg
	| PauseMsg
	| ResumeMsg
	| UnloadMsg
	| SeekMsg
	| VolumeMsg
	| GlobalCmd

// events (audio thread → main)

pub struct StreamFinishedEvent {
pub:
	id StreamId
}

pub type AudioEvent = StreamFinishedEvent
