# mv.serde

`serde` provides a generic field walker that serialises and deserialises V structs to JSON using the `typeinfo` registry. It relies on V's comptime `$for field in T.fields` reflection and the `@[export]` struct field attribute to select which fields participate.

## @[export] attribute

Only fields tagged `@[export]` are included in serialisation. An optional alias can be specified:

```v
struct Player {
    node_name string  // not serialised
    @[export]
    health    int     // key: "health"
    @[export: 'mp']
    mana      int     // key: "mp"
}
```

Fields without `@[export]` are silently skipped. Unknown keys in the JSON input are also silently ignored, so partial JSON round-trips cleanly.

## write_struct

```v
pub fn write_struct[T](src &T, registry &typeinfo.TypeRegistry, mut enc typeinfo.JsonEncoder) !
```

Writes a complete JSON object for `src`. For each `@[export]` field, looks up the field's type in `registry` and calls its `write_json` hook. Array fields are handled transparently: each element's hook is called in sequence inside a JSON array.

The caller controls the surrounding context: `write_struct` always wraps its output in `begin_object` / `end_object`, so the caller must not wrap it again.

## read_struct

```v
pub fn read_struct[T](mut dst T, registry &typeinfo.TypeRegistry, mut dec typeinfo.JsonDecoder) !
```

Reads a JSON object into `dst`. The decoder must be positioned at the object to read. `read_struct` enters the object, collects all present keys up-front, then iterates the struct's `@[export]` fields. For each field present in the JSON, it looks up the type and calls its `read_json` hook. Missing keys leave the field at its zero / default value.

The key-collection step (`collect_keys`) calls `rewind_object` after enumeration so that subsequent `seek_key` calls can find any key regardless of order in the JSON.

## Registry dependency

Both functions require a populated `typeinfo.TypeRegistry`. Every type that appears as an `@[export]` field must be registered with a `write_json` / `read_json` hook before calling `write_struct` / `read_struct`. The engine's `register_builtins`, `register_core_types`, and `register_engine_types` cover all built-in mv types.

## Relationship to SceneRegistry

`write_struct` / `read_struct` handle plain value structs. They are not used for node serialisation directly, because:

- Node structs embed `Node` as their first field; `$for field in T.fields` sees it as a single opaque field rather than promoted fields.
- Resource handles need `App` context (for `name_of` / `get_handle`) that `WriteJsonFn` / `ReadJsonFn` do not receive.

Node save / load uses `engine.SceneRegistry` instead, which carries explicit `app &App` parameters. See `engine/readme.md` for details.
