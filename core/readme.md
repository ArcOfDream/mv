# mv.core

`core` is the shared foundation of the mv engine. It defines the value types, math utilities, input handling, and data resources that every other module depends on. Nothing in `core` imports from the rest of mv — it sits at the bottom of the dependency graph.

## Contents

**`Vec2`**: the engine's primary 2D vector type, aliased directly to Raylib's `C.Vector2` to avoid conversion overhead at rendering boundaries. Carries the usual arithmetic operators, `dot`, `cross`, `normalize`, `length`, `lerp`, and angle helpers.

**`StringName`**: an interned string type backed by a reference-counted global table. Two `StringName` values with the same content compare equal via pointer identity (`==`) rather than character-by-character, making them safe and cheap to use as map keys in hot paths. Used by `InputMap` for action names and available for any system that keys on string labels at runtime.

**`InputMap`**: a Godot-style action system that maps named actions (identified as `StringName`s) to one or more `InputBinding`s covering keyboard keys and mouse buttons. Decouples game logic from raw keycodes: scripts and nodes query `input.is_action_pressed("jump")` rather than specific keys, making bindings configurable without touching game code.

**`Curve`**: a piecewise cubic curve sampled over a normalised \[0, 1\] domain. Points carry independent left and right tangents for asymmetric handles. Supports linear and Hermite interpolation, output clamping, and baking into a `BakedCurve` lookup table for zero-cost runtime sampling. Useful for easing shapes, speed profiles, spawn rate envelopes, or any value that should follow an authored curve over time.

**`Gradient`**: a multi-stop color ramp sampled by a normalised offset. Interpolation mode is selectable per gradient: `constant` (hard steps), `linear`, `cubic` (Catmull-Rom per channel), or `monotone_cubic` (Fritsch-Carlson, prevents hue overshoots). An optional `BakedCurve` can remap the sample position before color lookup, combining curve shaping with color output in one resource.

**`Gradient2D`**: generates a `rl.Image` from a `Gradient`, mapping the gradient across a given pixel width. The output image can be uploaded to a `rl.Texture2D` and used directly in rendering or passed to a shader as a lookup texture.

**Math utilities**: a collection of scalar and geometric helpers that complement V's standard `math` module for game use: `approach`, `unlerp`, `remap`, `between`, `repeat`, `ping_pong`, `sincos`, `angle_between`, and power-of-two utilities (`ceilpow2_int`, `ceilpow2_i64`).

**`RectF`**: a float rectangle (`x, y, w, h`) for general geometry: camera bounds, UI layout, sprite source regions, scissor rects, and trigger zones. Distinct from `physics.AABB`, which is min/max and intended for collision shapes. Carries `overlaps`, `contains`, `intersection` (returns `?RectF`), `union_rect`, `expand`, `grow`, `expand_edge`, `half_rect`, and `minkowski_diff`.

**`Edge`**: a four-value enum (`left`, `right`, `top`, `bottom`) with helpers for `opposing`, `is_horizontal`, `is_vertical`, and `is_max`. Used by `RectF` and available for any system that reasons about directional sides — tilemap adjacency, layout constraints, collision normals.

**`Timeline`**: a callback dispatcher using an integer as a unit of time. Provides a `step` to progress the time, and `step_by` to progress by multiple frames.