# mv: Making Videogames

A lightweight 2D game engine written in [V](https://vlang.io), built as a project to explore game engine internals and understanding how it works under the hood.

**mv** takes heavy inspiration from [Godot](https://godotengine.org)'s design - scene trees, node composition, canvas layers, animation players - reimplemented from scratch in a fast, simple, compiled language.

---

## Features

- **Scene tree**: Godot-inspired node hierarchy with propagation, notifications, and tree manipulation
- **Transform system**: matrix stack-based 2D transforms with `CameraNode` and `DrawLayer` support
- **Input map**: action-based input mapping with `StringName`-interned keys
- **Animation**: generic keyframe tracks, easing library, call events, and ping-pong loop support
- **Wren scripting** *(WIP)*: embedded scripting via [Wren](https://wren.io) with foreign class bindings for engine types
- **Resource management**: [rres](https://github.com/raysan5/rres)-backed asset loading for textures, fonts, and data

---
 
## Dependencies
 
| Library | Purpose |
|---|---|
| [vlang/raylib](https://github.com/vlang/raylib) | bindings for Raylib |
| [larpon/wren](https://github.com/larpon/wren) | bindings for the Wren scripting language |

---

## Built With

| Project | Role |
|---|---|
| [V](https://vlang.io) | Implementation language |
| [Raylib](https://www.raylib.com) | Core framework |
| [Wren](https://wren.io) | Embedded scripting language (with bindings by Larpon) |
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