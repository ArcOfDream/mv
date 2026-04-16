# mv.physics

`physics` provides shape primitives, collision detection, and spatial partitioning for 2D rigid-body simulation. It has two distinct collision layers that complement each other: a broad phase that quickly eliminates non-contacting pairs using a spatial hash, and a narrow phase that computes exact contact data through two different backends depending on the shape pair involved.

The module has no knowledge of nodes or the scene tree: those concerns live in `PhysicsBody` on the mv side, which owns the integration between the physics module and the node lifecycle.

## Contents

**`SpatialHash`**: the broad phase. Divides world space into a fixed-size grid and maintains two cell maps: `cells` for dynamic bodies (cleared each frame) and `static_cells` for static bodies (populated once at `ready` and updated only on structural changes). A shared `seen` map deduplicates candidates per query. Provides `register_shape`, `register_static_shape`, `unregister_static`, and `query_shape`, all operating in terms of the `Shape` sum type so callers never deal with raw coordinates directly.

**`Shape`**: the sum type `AABB | Circle | Capsule | Polygon | Ray | Vec` shared across all physics operations. Each variant maps directly to a cute_c2 struct. The `bounds()` method on `Shape` returns a conservative AABB for any variant, which is what the spatial hash uses for cell registration. `Polygon.from_rect` and `Polygon.from_aabb` are convenience constructors; polygons store vertices in local space and are transformed at collision time via `XTransform`.

**`XTransform`**: cute_c2's position and rotation representation, storing a `Vec` position and a `Rotation` as a pre-computed cos/sin pair rather than a raw angle. `XTransform.from(pos, angle)` is the bridge from the engine's world-space position and rotation to this form. Scale is not representable; polygon vertices must be pre-scaled in local space. `xtransform_identity` is provided as a constant for non-polygon shapes whose coordinates are already in world space.

**`manifold_between` / `manifold_between_xf`**: the cute_c2 narrow phase, dispatching through a full match over all shape pair combinations to the appropriate underlying C function. The manifold normal always points from `s1` toward `s2`; asymmetric pairs (e.g. Circle vs AABB, where cute_c2 only supports one argument ordering) swap arguments and negate the normal to maintain that convention. `manifold_between` is the simpler entry point for shapes already in world space; `manifold_between_xf` accepts explicit transforms for polygon pairs. A non-zero `Manifold.count` indicates contact; `depths[0]` holds the penetration depth.

**`sweep_aabb`**: the Liang-Barsky sweep narrow phase for AABB vs AABB pairs, implementing the Minkowski difference approach from Bump.lua. Inflates the obstacle by the mover's size to reduce the problem to a ray-vs-rect test, then clips the velocity ray against all four slab boundaries. Returns a `SweepResult` with a parametric time-of-impact `ti` in \[0, 1\], the contact normal, and the touch position (mover's min corner at the moment of contact). `ti == 0` means the shapes are already overlapping; the overlap case resolves to a minimum-separation normal rather than a sweep normal. This path is preferred over cute_c2 for AABB pairs because it produces a `ti` value directly usable by `move_and_slide` without additional computation.

**`PhysicsWorld`**: a thin container holding the `SpatialHash` and a `gravity` scalar. Owned by `App` and passed by reference to `PhysicsBody` during its update. `clear()` resets the dynamic cell map each frame before bodies re-register.

## Two-backend design

The split between `sweep_aabb` and `manifold_between` is intentional. cute_c2 is an overlap detector: it reports whether shapes intersect and by how much, but not *when* during a frame's motion the contact first occurred. `sweep_aabb` fills that gap for the dominant AABB case by returning a time-of-impact, enabling `move_and_slide` to move the body forward to the exact contact point before projecting remaining velocity along the surface. For all other shape combinations (circle, capsule, polygon) the cute_c2 manifold path is used, resolving overlaps by penetration depth.