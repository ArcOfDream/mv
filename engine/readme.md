# mv.engine

`engine` is the central runtime module of mv. It owns the application lifecycle, the scene tree, and all node types. It is the one module that imports from every other: `core`, `physics`, `audio`, `resourcemanager`, `animation`, `ldtk`, `pxtn`, and `wren`: and in turn nothing in those modules imports from `engine`. All game code lives here or extends from it.

## App

`App` is the top-level runtime context. It owns every subsystem and is passed by reference to all nodes via their `app` field. A single `App` is created at program entry and lives for the duration of the process.

Subsystems held by `App`:

- `textures`, `shaders`, `sounds`: typed `ResourceManager` instances for GPU and CPU assets
- `physics_world`: the `SpatialHash` and gravity scalar; cleared each frame before bodies re-register
- `audio_server`: the `AudioServer` with its background thread and bus graph
- `input_map`: the `InputMap` action table, polled each frame
- `state`: a `GameState` carrying `dt` and the optional typed `user_data` pointer
- `names`: the shared `StringNameMap` for `StringName` interning
- `bodies`: the flat map of live `PhysicsBody` references keyed by pointer-as-int, used by physics queries
- `active_camera`: the currently registered `CameraNode`; if set, its `rl.Camera2D` wraps the scene draw

`App.run()` opens the Raylib window, starts the Wren VM if configured, and enters the main loop. The loop has two compilation modes selected by the `-d single_thread` flag: in the default multi-threaded mode, update and physics run on a background goroutine synchronised with the render thread via two channels; in single-threaded mode everything runs sequentially. The viewport is rendered to an `rl.RenderTexture2D` and then scaled to the window with optional integer scaling, letterboxed or pillarboxed to fit.

User callbacks (`init_func`, `update_func`, `draw_func`, `backdrop_draw_func`, `input_func`) are optional function references set at construction. They run alongside the scene tree's notification passes, not instead of them.

`App.new_node[T]` is the generic factory for creating any node type: it allocates, sets `app` and initial position, then fires `.init` before returning.

## Scene tree and notifications

The scene tree is a single-root hierarchy of `INode` values. `App.scene_root` holds the root; nodes are added and removed via `add_child` / `remove_child` / `queue_free`. `queue_free` defers removal to the end of the current update pass via `App.pending_free`, preventing mid-iteration invalidation.

`emit_notification` and `notify` drive the tree. `emit_notification` handles the recursive tree walk and the per-notification ordering; `notify` dispatches a single notification to a single node. The ordering rules are:

- `.update`: node fires before its children (pre-order); matrix rebuild and transform decomposition happen here if the node is dirty
- `.draw`: push matrix -> draw self -> draw children recursively -> pop matrix (wraps the subtree in the node's local transform)
- `.ready`, `.init`, `.exit_tree`: children are notified before the parent (post-order)

`ProcessFlags` is a bitmask with two bits: `.transform` (participate in matrix rebuild during update) and `.draw` (participate in the draw pass). Nodes can opt out of either independently: `Timer` and `MusicPlayer` clear both flags since they have no visual or transform work.

## INode and Node

`INode` is the interface every node type satisfies. It declares the full set of fields and methods the engine uses when traversing the tree: transform accessors, child management, notification callbacks, and Wren integration hooks. Every concrete node embeds `Node` which provides default implementations for all of them.

`Node` stores local position, rotation (kept in both degrees and radians), and scale, plus a lazy `local_matrix` rebuilt only when `dirty` is set. The global matrix is computed on demand by multiplying up the parent chain. `Transform2D` is cached from the global matrix and marked dirty whenever the matrix changes; `sync_transform` redecomposes it on the next read. Global setters invert the parent's matrix to derive the correct local value.

Nodes can be Wren-owned (`wren_owned = true`), in which case `notify` calls back into the Wren VM after the V-side `update_internal` and `draw_internal` complete, passing `dt` and the node's persistent Wren handle.

## Node types

**`Sprite`**: renders a `TextureResource` with optional frame grid (h_frames × v_frames), centering, offset, tint, and an optional `ShaderResource`. `set_texture_id` and `set_shader_id` look up handles from the app's resource managers by name.

**`CameraNode`**: wraps `rl.Camera2D`. `register()` sets this node as `App.active_camera`, causing the scene draw to be wrapped in `begin_mode_2d` / `end_mode_2d`.

**`DrawLayer`**: renders its children in screen-space rather than inheriting the parent transform chain. Equivalent to Godot's `CanvasLayer`: it resets the matrix stack to identity before drawing, so its subtree always draws at fixed screen coordinates regardless of camera or parent transforms.

**`Viewport`**: renders its children into a private `rl.RenderTexture2D`. Exposes the resulting texture for use as an input to other draw operations. Useful for render-to-texture effects, minimap captures, or offscreen compositing.

**`Timer`**: counts down `wait_time` seconds and fires `on_timeout`. Supports `one_shot` and `autostart`. Exposes `play`, `stop`, `pause`, and `reset`. Has no transform or draw work; `process_flags` is cleared.

**`MusicPlayer`**: a node wrapper around `AudioServer` stream management. Holds a `StreamID` for the currently playing stream and exposes `play_pxtone`, `play_file`, `play_from_memory`, `stop`, `pause`, `resume`, `seek`, and `loop`. Routes to the configured `bus` (defaults to `'Music'`).

**`PhysicsBody`**: a 2D rigid body with a `physics.Shape` and collision layer/mask bitmasks. Supports `static_body` (immovable, registers once at ready) and `kinematic` (registers each frame). Provides `move_and_collide` (returns all hits along a proposed velocity without moving) and `move_and_slide` (iterative velocity resolution with surface projection). Surface query helpers `is_on_floor`, `is_on_wall`, `is_on_ceiling`, and their normal variants read from `slide_collisions` populated by the last `move_and_slide` call.

**`TileMap`**: renders a set of `ldtk.Tile` values against a tileset `TextureResource`. Constructed directly from an `ldtk.LayerInstance` via `TileMap.from_layer`, which also adds it as a child of the supplied parent node. Handles Tiles and AutoLayer layer types; IntGrid layers use `IntGrid` instead.

**`IntGrid`**: stores the flat row-major integer grid from an LDtk IntGrid layer and builds static `PhysicsBody` collision shapes from non-zero cells using horizontal run-length merging. Exposes `cell_value_at(id)` so collision handlers can identify which cell value a body represents. Collision integration is still in progress.

**`ParticleEmitter`**: a physics-driven particle system. Particles have velocity, gravity, and optional radial/tangential acceleration. Emission is continuous at a configurable rate or burst-only. Lifecycle shape is controlled by optional `BakedCurve` instances for scale and alpha, and an optional `Gradient` for color. Supports `local_coords`, `fixed_fps` simulation decoupling, and `preprocess` warm-start. Emits `sig_emitter_finished` when a one-shot burst has fully expired.

**`BurstEmitter`**: a curve-driven particle system adapted from BurstParticles2D by Ian Sly (MIT). Particles have no velocity or forces; position is computed each frame as a pure function of normalised lifetime `t` via authored curves (`distance_curve`, `rotation_curve`, `offset_curve`, `angle_curve`, `scale_curve`, `x_scale_curve`, `y_scale_curve`). Supports `center_concentration` for exponential spread distribution, `distance_falloff_curve` for angular distance attenuation, `start_radius`, and a gradient map shader path (`gradient_map.glsl` / `gradient_map_add.glsl`) for luminance-based color remapping. Emits `sig_burst_finished` when all particles from the last `burst()` call have expired.

**`BurstGroup`**: coordinates multiple `BurstEmitter` children, firing them all simultaneously via `burst()` and emitting `sig_group_finished` only after every child's particles have expired. Supports `repeat` for looping composite effects.

## Wren integration

Nodes with `wren_owned = true` have their `update` and `draw` methods called back into the Wren VM each frame via pre-made call handles stored on `App`. The Wren VM is optional: if no `WrenSetup` is provided to `App`, the entire Wren path is a no-op. Signal emission passes `app.wren_vm` and `app.wren_signal_call_handles` to `SignalTable.emit`, enabling Wren closures to be registered as signal handlers alongside V callbacks.