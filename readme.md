# mv (Making Videogames)

A 2D game engine written in [V](https://vlang.io), built as a project to explore game engine internals and understanding how it works under the hood.

**mv** takes heavy inspiration from [Godot](https://godotengine.org)'s design - scene trees, node composition, canvas layers, animation players - reimplemented from scratch in a fast, simple, compiled language.

---

## Features

- **Scene tree**: Godot-inspired node hierarchy with propagation, notifications, and tree manipulation
- **Scene save / load**: JSON-based scene persistence with a typed `SceneRegistry`; save and reload live scene trees at runtime
- **Transform system**: matrix stack-based 2D transforms with `CameraNode` and `DrawLayer` support
- **Physics**: `SpatialHash` broad phase, AABB / circle / capsule shapes, `move_and_slide` and `move_and_collide` for kinematic bodies
- **Input map**: action-based input mapping with `StringName`-interned keys
- **Audio**: multi-bus `AudioServer` with background thread, Raylib audio and PXTone music sources
- **Animation**: generic keyframe tracks, easing library, call events, and ping-pong loop support
- **Scene instancing**: Godot-style scene references; a node subtree saved as its own file can be instantiated by reference inside another scene, with per-instance overrides for position, scale, and rotation
- **Wren scripting**: embedded scripting via [Wren](https://wren.io) with foreign class bindings for nodes, transforms, input, and Raylib draw calls; supports entry-script scenes and V-node script attachment
- **Resource management**: [rres](https://github.com/raysan5/rres)-backed asset loading for textures, fonts, and data
- **Serialisation**: `typeinfo` type registry with JSON encoder / decoder; `serde` field walker using `@[export]` struct attributes

---
 
## Dependencies
 
Besides V for building, the project depends on [vlang/raylib](https://github.com/vlang/raylib) to provide bindings for Raylib.

---

## Built With

| Project | Role |
|---|---|
| [V](https://vlang.io) | Implementation language |
| [Raylib](https://www.raylib.com) | Core framework |
| [Wren](https://wren.io) | Embedded scripting language (with bindings by [larpon](https://github.com/larpon/wren)) |
| [rres](https://github.com/raysan5/rres) | Resource packaging format |
| [libmpxtn](https://github.com/stkchp/libmpxtn) | PXTone file playback |
| [cute_c2](https://github.com/RandyGaul/cute_headers/blob/master/cute_c2.h) | Collision detection routines |
| [Godot Engine](https://godotengine.org) | Architectural inspiration |

---

## Status

Currently still early into development. Functional, although the API itself will be subject to change.

---

## License
 
Unless otherwise stated, mv is licensed under the [zlib License](LICENSE).