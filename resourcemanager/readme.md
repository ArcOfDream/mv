# mv.resourcemanager

`resourcemanager` handles loading, storing, and unloading GPU and CPU resources across the lifetime of the application. It separates the question of *where assets come from* (files, rres archives, memory, async background loading) from the question of *how they are stored and referenced* (a generation-counted slot allocator). All resources are accessed through typed `Handle[T]` values rather than raw pointers or string keys, so dangling references are detected rather than silently returning stale data.

## Contents

**`ResourceManager[T]`**: a generic slot allocator for any type that implements the `IResource` interface (`unload()`). Internally maintains a flat `[]Slot[T]` with a parallel free-list for O(1) reuse of vacated slots, and a `map[string]int` for name-to-index lookup. Slots carry a generation counter that increments on every unload; a `Handle[T]` stores both the slot index and the generation it was issued at, so `get(handle)` returns `none` if the slot has been recycled since the handle was created. `add` is intentionally private: resource types expose their own named constructors (`load`, `load_from_image`, `load_from_rres`, etc.) that call `add` internally, keeping the allocation path type-safe. `clear()` unloads and resets all slots at once, suitable for scene transitions.

**`Handle[T]`**: a lightweight value type (`id int`, `generation int`) that safely references a slot. Copyable, comparable, and safe to store in node fields. A zeroed `Handle[T]` is never valid since slot generations start at 0 and the handle generation must match.

**`TextureResource`**: wraps `rl.Texture2D` with an optional `[]rl.Rectangle` frame list for sprite sheets. `generate_frames_grid(cols, rows)` slices the texture into a uniform grid and stores the resulting rectangles as frames, replacing any previously set list. Individual frames can also be added with `add_frame` or `add_frame_rect`. Load paths: from a file path, from an existing `rl.Image` (GPU upload without re-reading disk), from a raw `rl.Texture2D`, or from an rres `IMGE` chunk.

**`SoundResource`**: wraps `rl.Sound` (a fully decoded, GPU-side audio buffer, distinct from the streamed `rl.Music` used by `audio.AudioServer`). Suitable for short sound effects that need low-latency playback. Load paths: from a file path, from an `rl.Wave` (decoded CPU-side buffer, unloaded after upload), or from an rres `WAVE` chunk.

**`FontResource`**: wraps `rl.Font`. The rres path uses `load_multi` rather than `load_single` because fonts are stored as two paired chunks: an `IMGE` atlas and an `FNTG` glyph metrics table.

**`ShaderResource`**: wraps `rl.Shader`. Supports loading from file paths (GLSL source files), from source strings already in memory (`load_from_source`), or from rres `TEXT` chunks. Either stage (vertex or fragment) can be left empty to use Raylib's default shader for that stage.

**`ThreadLoader`**: a background worker that handles the CPU-side phase of asset loading (file I/O, image decoding, wave decoding, shader source reading) off the main thread. Communicates with the caller via two buffered channels: `commands` (caller → worker, capacity 64) and `events` (worker → caller, capacity 64). The split between CPU work (done in the worker) and GPU work (done on the main thread) is intentional: Raylib's OpenGL context is single-threaded, so `rl.load_texture_from_image` and `rl.load_sound_from_wave` must happen on the main thread after the worker sends back the decoded `rl.Image` or `rl.Wave`.

The typical per-frame pattern is:

```v
for event in thread_loader.poll_events() {
    if event.err != '' {
        eprintln('load failed: ${event.err}')
        continue
    }
    match event.content {
        rl.Image  { textures.load_from_image(event.name, event.content) }
        rl.Wave   { sounds.load_from_wave(event.name, event.content) }
        ShaderFile { shaders.load_from_source(event.name, event.content.vs, event.content.fs) }
        else {}
    }
}
```

`ThreadLoader` supports two source types: `FileSource` (raw filesystem paths) and `RresSource` (keys into an rres archive, with an optional `aux_key` for the second chunk of multi-chunk resources like shaders). If an `rres_path` is supplied at construction, the worker opens a single `RresLoader` for the lifetime of the thread and uses it for all `RresSource` commands. `shutdown()` closes the command channel, causing the worker to drain remaining commands and exit cleanly.