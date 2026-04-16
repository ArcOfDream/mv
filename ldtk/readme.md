# mv.ldtk

A pure-V parser for [LDtk](https://ldtk.io) project files. Decodes the LDtk JSON format into idiomatic V structs with no dependencies on mv or Raylib: it can be used in any V project that needs to read LDtk data.

## Usage

```v
import ldtk

// load a project
project := ldtk.load('world.ldtk')!

// if externalLevels is enabled, layer_instances will be null until hydrated
dir := 'path/to/project'
for level in project.all_levels() {
    full := ldtk.load_external_level(level, dir)!
    for layer in full.layer_instances? {
        match layer.layer_type() {
            .tiles, .auto_layer {
                ts := project.tileset_by_uid(layer.tileset_def_uid?) or { continue }
                for tile in layer.tiles() {
                    // tile.px[0], tile.px[1] = destination in level space
                    // tile.src[0], tile.src[1] = source in tileset image
                    // tile.flip_flags() = FlipFlags{x, y}
                }
            }
            .int_grid {
                // layer.int_grid_csv is a flat row-major array, width = layer.c_width
            }
            .entities {
                for entity in layer.entity_instances {
                    // entity.field_instances carries custom field data as raw JSON strings
                }
            }
            .unknown {}
        }
    }
}
```

## Structure

The parsed type hierarchy mirrors the LDtk JSON structure directly:

```
Project
 ├── defs.tilesets []TilesetDef
 ├── worlds []World          (LDtk 1.0+ multi-world projects)
 │    └── levels []Level
 └── levels []Level          (single-world / pre-1.0 compatibility)
      └── layer_instances ?[]LayerInstance
           ├── grid_tiles / auto_layer_tiles []Tile
           ├── int_grid_csv []int
           └── entity_instances []EntityInstance
                └── field_instances []FieldInstance
```

**`Project`**: the root of a `.ldtk` file. `all_levels()` returns every level regardless of whether the project uses the `worlds[]` layout (LDtk 1.0+) or the flat `levels[]` layout, so calling code doesn't need to branch on this. `external_levels` is `true` when the project is saved with "Save levels separately"; in that case each `Level.layer_instances` will be `none` until `load_external_level` is called.

**`Level`**: a single room or area. Carries pixel dimensions, world-space coordinates for GridVania and Free layouts, a `neighbours[]` adjacency list, and an optional `external_rel_path` for the sidecar `.ldtkl` file.

**`LayerInstance`**: one layer within a level. `layer_type()` converts the raw `__type` string to the `LayerType` enum. `tiles()` returns whichever of `grid_tiles` or `auto_layer_tiles` is populated, so Tiles and AutoLayer layers can be iterated identically. `px_total_offset_x/y` includes both the layer definition offset and any per-instance override and should be added to tile pixel coordinates when placing tiles in world space.

**`Tile`**: a single placed tile. `px` is the destination position within the level; `src` is the top-left corner of the source rectangle in the tileset image; `t` is the tile UID within the tileset; `a` is per-tile alpha. `flip_flags()` decodes the `f` bitmask into a `FlipFlags` value with `x` and `y` bits.

**`TilesetDef`**: a tileset definition from the project's `defs` block. `tileset_by_uid` on `Project` provides a lookup by UID, which is the reference format used by `LayerInstance.tileset_def_uid`. `rel_path` is `none` for embedded or atlas tilesets.

**`EntityInstance`**: a placed entity. `field_instances` carries custom field values as raw JSON strings alongside a `__type` hint (`"Int"`, `"Float"`, `"String"`, `"Bool"`, `"Color"`, `"Point"`, `"Array<...>"`, etc.); callers decode the value string according to the type. `world_x` / `world_y` are only populated for GridVania and Free world layouts.

## External levels

When "Save levels separately" is enabled in LDtk, call `load_external_level` for each level before accessing its layers. Pass the directory containing the `.ldtk` project file as `project_dir`; the loader resolves the `externalRelPath` relative to it:

```v
dir := os.dir('world.ldtk')
for level in project.all_levels() {
    full := ldtk.load_external_level(level, dir) or {
        eprintln('could not load level ${level.identifier}: ${err}')
        continue
    }
    // full.layer_instances is now populated
}
```