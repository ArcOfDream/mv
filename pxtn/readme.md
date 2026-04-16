# mv.pxtn

A V wrapper for [libmpxtn](https://github.com/stkchp/libmpxtn) by stkchp, a C decoder for the PXTone Collage `.ptcop` music format originally created by Studio Pixel (author of Cave Story). The C library is provided under the MIT license and is compiled directly from source alongside the module: no external library installation is required.

Also includes a decoder for `.ptnoise` waveform files (used by PXTone's instrument system) via the `ptn` / `descriptor` C sources from the same library.

## Usage

```v
import pxtn

// load from a memory slice (typical path when using ResourceManager)
data := os.read_bytes('song.ptcop')!
handle := pxtn.from_memory(data)!
defer { handle.close() }

// or load directly from a file path
handle := pxtn.from_file('song.ptcop')!
defer { handle.close() }

// decode PCM into a buffer: frames are stereo s16 LE at 44100 Hz (4 bytes each)
buffer := []u8{len: 4096 * 4}
written := handle.gen_buffer(buffer.data, 4096)
// written < 4096 means the track has ended

// implement the intro → loop structure common in .ptcop files
if written < count {
    if handle.get_loop() {
        handle.seek(handle.repeat_sample())
    }
}
```

## API

**`from_memory(data []u8) !&Pxtone`**: loads a `.ptcop` from a byte slice. This is the primary entry point when assets are loaded through `resourcemanager.ThreadLoader`, which delivers files as `[]u8`.

**`from_file(path string) !&Pxtone`**: loads a `.ptcop` directly from a file path using a C file handle.

**`gen_buffer(buffer voidptr, count usize) usize`**: decodes up to `count` sample frames into `buffer`. Each frame is 4 bytes: two interleaved signed 16-bit samples (left, right) in little-endian byte order at 44100 Hz. Returns the number of frames actually written; a return value less than `count` means playback reached the end of the track.

**`seek(smp_num usize) bool`**: moves the playback position to the given sample frame offset from the start.

**`reset() bool`**: returns playback to the beginning; equivalent to `seek(0)`.

**`repeat_sample() usize`**: returns the sample frame the track loops back to. PXTone tracks commonly have a non-looping intro followed by a looping body; the intro plays once and subsequent loops begin at `repeat_sample` rather than frame 0. Use with `seek` after `gen_buffer` returns less than the requested count.

**`total_samples() usize`** / **`current_sample() usize`**: total length and current playback position, both in sample frames.

**`set_loop(bool)` / `get_loop() bool`**: controls whether the track should loop. This flag is checked externally by the caller (see `repeat_sample` above) rather than being handled inside the decoder.

**`close()`**: frees all resources held by the decoder. Always call this when done; the handle is heap-allocated by the C library and V's GC will not reclaim it automatically.

**`wave_from_ptnoise(data []u8) !rl.Wave`**: decodes a `.ptnoise` waveform file into a Raylib `rl.Wave` struct (mono, s16, 44100 Hz). Useful for loading PXTone instrument samples as one-shot sound effects. Note: this function depends on Raylib and is only available when building against mv; the `Pxtone` type and file-loading functions have no Raylib dependency.

## Audio format

All decoded output is **stereo signed 16-bit little-endian PCM at 44100 Hz**. When feeding a Raylib `AudioStream`, configure it with `sample_rate: 44100`, `sample_size: 16`, `channels: 2`. The buffer size passed to `gen_buffer` should match the `AudioStream`'s buffer frame count (mv defaults to 4096 frames, ~93ms of audio per fill).

## C sources

The module compiles the following C sources directly via `#flag` directives in `pxtn_ext_c.v`, requiring no separate build step: `descriptor`, `error`, `freq`, `master`, `evelist`, `oscillator`, `pcm`, `ogg`, `ptn_tbl`, `ptn`, `ptv`, `woice`, `overdrive`, `delay`, `unit`, `service`, `mpxtn`. Ogg Vorbis support is enabled via `-DMPXTN_OGGVORBIS`. The math library is linked via `-lm`.