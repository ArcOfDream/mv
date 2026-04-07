module audio

// commands (main → audio thread)

pub struct LoadMsg {
pub:
	id     StreamID
	source MusicSource
}

pub struct StopMsg {
pub:
	id StreamID
}

pub struct PauseMsg {
pub:
	id StreamID
}

pub struct ResumeMsg {
pub:
	id StreamID
}

pub struct UnloadMsg {
pub:
	id StreamID
}

pub struct SeekMsg {
pub:
	id       StreamID
	position f32
} // always in seconds

pub struct VolumeMsg {
pub:
	id     StreamID
	volume f32
} // linear [0.0, 1.0]

pub struct LoopMsg {
pub:
	id     StreamID
	toggle bool
}

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
	| LoopMsg
	| GlobalCmd

// events (audio thread → main)

pub struct StreamFinishedEvent {
pub:
	id StreamID
}

pub type AudioEvent = StreamFinishedEvent
