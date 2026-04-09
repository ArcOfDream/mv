module mv

import raylib as rl
import resourcemanager { Handle, TextureResource }
import ldtk

pub struct TileMap {
	Node
mut:
	tileset_id string
	tileset    Handle[TextureResource]
	tiles      []ldtk.Tile
	grid_size  int
	opacity    f32 = 1.0
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

pub fn (mut t TileMap) set_tileset_id(val string) {
	t.tileset_id = val
	if handle := t.app.textures.get_handle(val) {
		t.tileset = handle
	}
}

@[inline]
pub fn (t &TileMap) get_tileset() ?TextureResource {
	return t.app.textures.get(t.tileset)
}

fn (mut t TileMap) draw_internal() {
	tex := t.get_tileset() or { return }
	color := rl.Color{255, 255, 255, u8(t.opacity * 255)}
	w := f32(t.grid_size)

	for tile in t.tiles {
		flags := tile.flip_flags()
		src := rl.Rectangle{
			f32(tile.src[0]),
			f32(tile.src[1]),
			if flags.has(.x) { -w } else { w },
			if flags.has(.y) { -w } else { w },
		}
		dst := rl.Rectangle{f32(tile.px[0]), f32(tile.px[1]), w, w}
		rl.draw_texture_pro(tex.tex, src, dst, rl.Vector2{0, 0}, 0, color)
	}
}
