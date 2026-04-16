# mv.audio

`audio` manages playback of music and sound streams. The design is inspired by Godot's `AudioServer` and the bus architecture of the SoLoud library: streams are routed through named buses that form a send chain to a master output, giving volume and mute control at any level without touching individual streams.

All playback runs on a dedicated background thread, keeping the audio update loop decoupled from frame timing on the main thread.

## Contents

**`AudioServer`**: the public API surface. Owns the bus table and the set of active `StreamID`s, and communicates with the audio thread exclusively via typed channels. Provides:

- `play_pxtone(data, bus)`: loads a `.ptcop` file from a memory slice and begins playback through the PXTone decoder.
- `play_file(path, bus)`: streams a file in any Raylib-native format (MP3, OGG, FLAC, XM, MOD).
- `play_from_memory(ext, data, bus)`: same as above but from a memory slice, using the extension hint for format detection.
- `play_music(source, bus)`: lower-level entry point that accepts a pre-constructed `MusicSource` directly.
- `stop`, `pause`, `resume`, `seek`, `loop`, `unload`: per-stream playback controls, all non-blocking (sent as channel messages).
- `set_bus_volume(bus, db)` / `set_bus_mute(bus, mute)`: bus-level controls that automatically propagate recalculated volumes to every stream whose send chain passes through the affected bus.
- `process()`: drains the event channel; call once per frame to collect `StreamFinishedEvent`s and clean up completed stream entries.
- `shutdown()`: sends a quit command and blocks until the audio thread confirms a clean exit.

The server starts with three buses: `master` (the root), `music` → `master`, and `sfx` → `master`, mirroring Godot's default layout.

**`AudioBus`**: a named node in the send graph. Stores `volume_db` (in decibels, converted to linear gain via `db_to_linear`) and a `mute` flag. Volume is resolved by walking the send chain from a stream's assigned bus up to the root, multiplying linear gains; any muted bus in the chain silences all streams below it.

**`MusicSource`**: a sum type (`RaylibMusic | PxtoneMusic`) that abstracts over the two supported stream backends. All backend-specific operations (init, stop, pause, resume, seek, volume, loop, unload, update) are handled through internal match functions, keeping the audio thread loop backend-agnostic. Adding a new backend means adding a variant here without touching anything else.

- `RaylibMusic` wraps `rl.Music` and delegates entirely to Raylib's streaming API.
- `PxtoneMusic` wraps a `pxtn.Pxtone` decoder handle alongside a Raylib `AudioStream` and a PCM fill buffer. Each tick it calls `gen_buffer` to fill the next `buffer_frames` (4096 frames, ~93ms at 44100 Hz) of 16-bit stereo PCM and pushes it to the stream. Loop point is handled via the decoder's `repeat_sample` position rather than restarting from zero.

**`AudioThread`**: manages the spawned goroutine and its three channels: `cmd_ch` (main → thread, buffered to 16), `event_ch` (thread → main, buffered to 16), and `done_ch` (shutdown handshake). The thread loop drains all pending commands first, then ticks every active stream, then sleeps for 2ms to yield the CPU. Finished streams are reported back as `StreamFinishedEvent`s on `event_ch`.

**`AudioMessage` / `AudioEvent`**: typed channel sum types. Commands are `LoadMsg`, `StopMsg`, `PauseMsg`, `ResumeMsg`, `UnloadMsg`, `SeekMsg`, `VolumeMsg`, `LoopMsg`, and the `GlobalCmd.quit` sentinel. Events are currently `StreamFinishedEvent` only, with the type left as a sum type for future expansion.