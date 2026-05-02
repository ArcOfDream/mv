# mv.typeinfo

`typeinfo` is the runtime type registry for mv. It maps type names to `TypeInfo` records that carry per-type serialisation hooks, sizes, and kind tags. JSON and binary encoder / decoder implementations live here as well.

Nothing in `typeinfo` imports from the rest of mv. It is a pure leaf dependency.

## TypeKind

```v
enum TypeKind {
    primitive   // bool, int, f32, string, etc.
    value       // plain struct with no heap indirection (Vec2, Color, ...)
    resource    // asset handle (TextureResource, SoundResource, ...)
    node        // engine node; construction tracked separately in SceneRegistry
}
```

## TypeInfo and function type aliases

`TypeInfo` holds the metadata and hooks for one registered type:

```v
pub type WriteJsonFn = fn (src voidptr, mut enc JsonEncoder) !
pub type ReadJsonFn  = fn (mut dec JsonDecoder, dst voidptr) !
pub type WriteBinFn  = fn (src voidptr, mut enc BinEncoder) !
pub type ReadBinFn   = fn (mut dec BinDecoder, dst voidptr) !
pub type ConstructFn = fn (name string) voidptr

pub struct TypeInfo {
pub mut:
    name       string
    size       int
    kind       TypeKind
    write_json ?WriteJsonFn
    read_json  ?ReadJsonFn
    write_bin  ?WriteBinFn
    read_bin   ?ReadBinFn
    construct  ?ConstructFn
}
```

All hooks are optional. Missing hooks produce an error at the call site, not at registration time, so partially registered types are allowed.

## TypeRegistry

`TypeRegistry` is a `map[string]&TypeInfo` with typed registration methods:

```v
mut r := typeinfo.TypeRegistry.new()

r.register_primitive[bool](typeinfo.ValueOpts{ write_json: ..., read_json: ... })
r.register_value[Vec2](typeinfo.ValueOpts{ write_json: ..., read_json: ... })
r.register_resource[TextureResource](typeinfo.ResourceOpts{ read_json: ... })
r.register_node[Sprite](typeinfo.NodeOpts{ construct: ... })
```

`ValueOpts` accepts an optional `pod bool` flag: when set and no `write_bin` / `read_bin` hook is provided, a raw `memcpy` pair is installed automatically. This is suitable for plain-old-data structs with no pointer fields.

`r.lookup(name)` returns `?&TypeInfo`.

## Built-in registrations

`register_builtins(mut r)` registers primitives (`bool`, `int`, `f32`, `f64`, `string`, `u8`, `i64`) and common value types (`Vec2`, `rl.Color`).

`register_core_types(mut r)` adds `core`-module value types.

`register_engine_types(mut r, app)` adds engine-level types that require an `App` reference for handle resolution (texture/sound/font handles, etc.).

## JsonEncoder

`JsonEncoder` writes well-formed JSON to an internal buffer. All methods return `!` and propagate structural errors (e.g. closing an object that was never opened).

```v
mut enc := typeinfo.JsonEncoder.new()

enc.begin_object()!
enc.key('x')
enc.write_f64(1.0)!
enc.key('active')
enc.write_bool(true)!
enc.end_object()!

json_string := enc.to_string()
```

Key methods: `begin_object` / `end_object`, `begin_array` / `end_array`, `key(string)`, `write_string`, `write_f64`, `write_int`, `write_bool`, `write_null`.

## JsonDecoder

`JsonDecoder` reads JSON using a key-seekable cursor. The design is field-driven rather than event-driven: callers request specific keys rather than processing a token stream.

```v
mut dec := typeinfo.JsonDecoder.parse(src)!

dec.enter_object()!
dec.seek_key('x')!
x := dec.read_f64()!
dec.exit_object()!
```

`seek_key(k)` scans all keys in the current object frame (wrapping around if needed) until it finds `k`, then positions the cursor on the value. This means keys can be read in any order regardless of the JSON layout.

`rewind_object()` resets the cursor to the start of the current object frame. Used in `load_node` so the type-specific read closure can seek keys that the base loader already consumed.

`has_next_element()` returns true while an array still has unread elements. `peek_key` / `consume_key` allow non-destructive key enumeration (used internally by `serde.collect_keys`).

## BinEncoder / BinDecoder

Binary counterparts to `JsonEncoder` / `JsonDecoder`. Used for compact asset bundles. `write_raw` / `read_raw` copy raw bytes; typed helpers wrap them for primitives. POD types registered with `pod: true` use `write_raw` / `read_raw` automatically.
