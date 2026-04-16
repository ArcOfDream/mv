# mv.animation

`animation` covers time-based value interpolation at two levels. The lower level provides easing functions, lerp helpers, and a lightweight fire-and-forget `Tweener` for simple one-shot transitions. The upper level provides a full keyframe track system and a named animation library with loop modes, inspired by Godot's `AnimationPlayer`.

## Easing functions

`EaseFn` is a type alias for `fn (f32) f32` — a function that maps a normalised input `t ∈ [0, 1]` to a shaped output. The full standard set is provided:

`linear`, `step`, `in_sine` / `out_sine` / `in_out_sine`, `in_quad` / `out_quad` / `in_out_quad`, `in_cubic` / `out_cubic` / `in_out_cubic`, `in_quart` / `out_quart` / `in_out_quart`, `in_quint` / `out_quint` / `in_out_quint`, `in_expo` / `out_expo` / `in_out_expo`, `in_circ` / `out_circ` / `in_out_circ`, `in_back` / `out_back` / `in_out_back`, `in_elastic` / `out_elastic` / `in_out_elastic`, `in_bounce` / `out_bounce` / `in_out_bounce`.

Any `fn (f32) f32` qualifies as an `EaseFn`, so a sampled `core.BakedCurve` can be dropped in wherever a built-in easing function would be used.

## Lerp helpers

Pre-built interpolation functions for the types most commonly animated:

- `lerp_f32(a, b, t)` — scalar float
- `lerp_vec2(a, b, t)` — `core.Vec2` / `C.Vector2`
- `lerp_color(a, b, t)` — `rl.Color` via Raylib's `color_lerp`
- `lerp_generic[T](a, b, t)` — generic fallback for numeric types supporting `+`, `-`, and scalar multiply

## Tweener / TweenManager

`Tweener[T]` interpolates a value of any type from `from` to `to` over `duration` seconds, applying an `EaseFn` and a supplied lerp function each tick. The result is written to either a direct target pointer or a callback function. A tweener marks itself done when `elapsed >= duration` and is automatically pruned by `TweenManager`.

`TweenManager` holds the active tweener list, advances all of them each frame, and removes finished ones:

```v
// direct pointer target
tm.tween(&sprite.alpha, 0.0, 1.0, 0.3, animation.out_quad, animation.lerp_f32)

// callback target — useful when a direct pointer isn't convenient
tm.cb_tween(fn (v f32) { sprite.set_alpha(v) }, 0.0, 1.0, 0.3, animation.out_cubic, animation.lerp_f32)

// call each frame
tm.update(dt)
```

## Track / Animation / AnimationPlayer

For anything more complex than a single transition, the track system lets multiple properties be animated together over a shared timeline.

**`Track[T]`** holds an ordered list of `Keyframe[T]` values and fires a setter callback each time it is sampled. Keyframes carry a timestamp and an `EaseFn` that shapes the curve entering that keyframe from the previous one. At sample time the track binary-searches for the surrounding keyframe pair, computes a local `t`, applies the easing function, and calls the lerp function to produce the interpolated value. Tracks write through a setter callback rather than a direct pointer, which keeps the track generic while allowing struct field writes, node property calls, or anything else.

**`CallTrack`** fires zero-argument callbacks at specific timestamps. It detects edge crossings — a callback fires when `last_time < event.time <= current_time` — so callbacks are not missed during large time steps and are not re-fired on a loop's wrap-around.

**`Animation`** groups any number of `ITrack` implementations (value tracks and call tracks) under a shared duration and loop mode. `add_track` takes a direct mutable target; `add_track_cb` takes an explicit setter function for cases where a direct reference is not available.

**`AnimationPlayer`** maintains a named library of `Animation` values and drives the active one each frame:

```v
import animation

mut player := animation.AnimationPlayer{}

// build an animation
mut anim := animation.Animation{ duration: 1.0, loop_mode: .loop }
anim.add_track_cb(
    fn (v f32) { sprite.alpha = v },
    [
        animation.Keyframe[f32]{ time: 0.0, value: 0.0, ease: animation.linear },
        animation.Keyframe[f32]{ time: 1.0, value: 1.0, ease: animation.in_out_sine },
    ],
    animation.lerp_f32
)

player.add('fade', anim)
player.play('fade')

// each frame
player.update(dt)
```

`play` resets the animation to its first keyframe values before starting, preventing a one-frame pop from a stale previous state. `seek(time)` samples the animation at an arbitrary position without changing the playing state, useful for scrubbing or initialising to a mid-point. `on_finish` accepts an optional `fn (name string)` callback fired when a non-looping animation completes.

Loop modes are `none` (stop at end), `loop` (wrap back to zero), and `ping_pong` (reverse direction at each end, driven by an internal `direction` multiplier rather than time remapping so the speed feels consistent in both directions).