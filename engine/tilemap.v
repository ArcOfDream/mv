module engine

import raylib as rl
import core { Vec2 }
import resourcemanager { Handle, TextureResource }
import ldtk

/*
TileMap: usage example

TileMap and IntGrid are constructed directly from LDtk layer instances.
The typical pattern is to load the project once, then walk the level's
layers and create the appropriate node for each layer type.

	import ldtk

	project := ldtk.load('assets/world.ldtk')!
	dir     := 'assets'

	for level in project.all_levels() {
		full := ldtk.load_external_level(level, dir) or { continue }

		for layer in full.layer_instances? {
			match layer.layer_type() {
				.tiles, .auto_layer {
					// TileMap requires the tileset texture to already be loaded.
					// The tileset name is used as the resource manager key.
					ts := project.tileset_by_uid(layer.tileset_def_uid?) or { continue }
					mut tm := TileMap.from_layer(&layer, mut scene_root)
					tm.set_tileset_id(ts.identifier) or {}
				}
				.int_grid {
					// IntGrid.from_layer builds static PhysicsBody collision
					// shapes automatically from non-zero cell runs.
					mut ig := IntGrid.from_layer(&layer, mut scene_root)
					ig.collision_layer = 1
				}
				else {}
			}
		}
	}

TileMap.from_layer sets pos from the layer's px_total_offset, so layer
offsets defined in LDtk are applied automatically. It also calls
parent.add_child internally, so you do not need a separate add_child call.

To look up which cell value a PhysicsBody collision came from (e.g. to
determine tile type on hit):

	hits := player.move_and_collide(velocity)
	for hit in hits {
		if val := intgrid.cell_value_at(int(voidptr(hit.other))) {
			if val == 2 { // e.g. hazard tile
				player.take_damage()
			}
		}
	}
*/

@[heap]
pub struct TileMap {
	Node
mut:
	tileset_id string
	tileset    Handle[TextureResource]
	tiles      []ldtk.Tile
	grid_size  int
	opacity    f32 = 1.0
}

pub fn TileMap.instantiate(app &App, name string) &TileMap {
	return &TileMap{
		app:       app
		node_name: name
	}
}

// from_layer constructs a TileMap from an LDtk layer instance, adds it as a child of parent
// and returns a reference to TileMap
// ---
// only Tiles and AutoLayer layer types are meaningful here - IntGrid layers should use IntGrid.from_layer
pub fn TileMap.from_layer(layer &ldtk.LayerInstance, mut parent INode) &TileMap {
	mut tm := &TileMap{
		node_name: layer.identifier
		app:       parent.app
		grid_size: layer.grid_size
		opacity:   layer.opacity
		pos:       Vec2{f32(layer.px_total_offset_x), f32(layer.px_total_offset_y)}
		tiles:     layer.tiles()
	}
	parent.add_child(mut tm)
	return tm
}

pub fn (mut t TileMap) unload() {
	t.tileset.release()
}

fn (n &TileMap) wren_class_name() string {
	return 'TileMap'
}

// --- tileset ---

pub fn (t &TileMap) get_tileset_handle() Handle[TextureResource] {
	return t.tileset
}

@[inline]
pub fn (t &TileMap) get_tileset() ?&TextureResource {
	return t.tileset.get()
}

pub fn (mut t TileMap) set_tileset_id(val string) !Handle[TextureResource] {
	t.tileset_id = val
	t.tileset.release()
	t.tileset = t.app.textures.get_handle(val) or {
		t.tileset = Handle[TextureResource]{}
		return error('tileset not found: ${val}')
	}
	return t.tileset
}

pub fn (mut t TileMap) set_tileset_handle(h Handle[TextureResource]) {
	t.tileset_id = t.app.textures.name_of(h.id) or { '' }
	t.tileset.release()
	t.tileset = h
}

pub fn (t &TileMap) get_tileset_id() ?string {
	if !t.tileset.is_valid() {
		return none
	}
	return t.app.textures.name_of(t.tileset.id)
}

fn (mut t TileMap) draw_internal() {
	tex := t.get_tileset() or { return }
	color := rl.Color{255, 255, 255, u8(t.opacity * 255)}
	w := f32(t.grid_size)

	for tile in t.tiles {
		flags := tile.flip_flags()
		src := rl.Rectangle{f32(tile.src[0]), f32(tile.src[1]), if flags.has(.x) { -w } else { w }, if flags.has(.y) {
			-w
		} else {
			w
		}}
		dst := rl.Rectangle{f32(tile.px[0]), f32(tile.px[1]), w, w}
		rl.draw_texture_pro(tex.tex, src, dst, rl.Vector2{0, 0}, 0, color)
	}
}
