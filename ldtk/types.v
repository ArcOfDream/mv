module ldtk

@[flag]
pub enum FlipFlags {
	x
	y
}

// tile data
@[minify]
pub struct Tile {
pub:
	px  []int @[json: 'px']  // [dest_x, dest_y] in pixels within the level
	src []int @[json: 'src'] // [src_x, src_y] in the tileset image
	f   int   @[json: 'f']   // flip bitmask: 0=none, 1=X, 2=Y, 3=both
	t   int   @[json: 't']   // tile uid within the tileset
	a   f32   @[json: 'a']   // alpha, 0.0–1.0
}

pub fn (t &Tile) flip_flags() FlipFlags {
	return FlipFlags.from(t.f) or { unsafe { FlipFlags(0) } }
}

// entity fields

// field values in LDtk are polymorphic (int, float, string, bool, array...)
// we store the raw JSON string here; callers decode based on __type
@[minify]
pub struct FieldInstance {
pub:
	identifier string @[json: '__identifier']
	typ        string @[json: '__type']
	value      string @[json: '__value'] // raw JSON — decode per typ
	def_uid    int    @[json: 'defUid']
}

// entity instances

@[minify]
pub struct EntityInstance {
pub:
	identifier      string          @[json: '__identifier']   // Entity definition identifier
	iid             string          @[json: 'iid']            // Unique instance identifier
	grid            []int           @[json: '__grid']         // [col, row]
	px              []int           @[json: 'px']             // Pixel coordinates ([x,y] format) in current level coordinate space. Don't forget optional layer offsets, if they exist!
	world_x         ?int            @[json: '__worldX']       // X world coordinate in pixels. Only available in GridVania or Free world layouts.
	world_y         ?int            @[json: '__worldY']       // Y world coordinate in pixels Only available in GridVania or Free world layouts.
	width           int             @[json: 'width']          // Entity width in pixels. For non-resizable entities, it will be the same as Entity definition.
	height          int             @[json: 'height']         // Entity height in pixels. For non-resizable entities, it will be the same as Entity definition.
	def_uid         int             @[json: 'defUid']         // Reference of the Entity definition UID
	field_instances []FieldInstance @[json: 'fieldInstances'] // An array of all custom fields and their values.
}

// layer instances

pub enum LayerType {
	int_grid
	tiles
	auto_layer
	entities
	unknown
}

@[inline]
pub fn layer_type_from_string(s string) LayerType {
	return match s {
		'IntGrid' { .int_grid }
		'Tiles' { .tiles }
		'AutoLayer' { .auto_layer }
		'Entities' { .entities }
		else { .unknown }
	}
}

@[minify]
pub struct LayerInstance {
pub:
	identifier        string           @[json: '__identifier']     // Layer definition identifier
	typ               string           @[json: '__type']           // Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)
	c_width           int              @[json: '__cWid']           // layer width in cells
	c_height          int              @[json: '__cHei']           // layer height in cells
	grid_size         int              @[json: '__gridSize']       // cell size in pixels
	opacity           f32              @[json: '__opacity']        // Layer opacity as Float [0-1]
	px_total_offset_x int              @[json: '__pxTotalOffsetX'] // Total layer X pixel offset, including both instance and definition offsets.
	px_total_offset_y int              @[json: '__pxTotalOffsetY'] // Total layer Y pixel offset, including both instance and definition offsets.
	px_offset_x       int              @[json: 'pxOffsetX']
	px_offset_y       int              @[json: 'pxOffsetY']
	tileset_rel_path  ?string          @[json: '__tilesetRelPath'] // null for IntGrid/Entities
	tileset_def_uid   ?int             @[json: '__tilesetDefUid']  // The definition UID of corresponding Tileset, if any.
	int_grid_csv      []int            @[json: 'intGridCsv']       // flat row-major grid
	grid_tiles        []Tile           @[json: 'gridTiles']        // Tiles layer
	auto_layer_tiles  []Tile           @[json: 'autoLayerTiles']   // AutoLayer
	entity_instances  []EntityInstance @[json: 'entityInstances']
	layer_def_uid     int              @[json: 'layerDefUid'] // Reference to the Layer definition UID
	level_id          int              @[json: 'levelId']     // Reference to the UID of the level containing this layer instance
	iid               string           @[json: 'iid']         // Unique layer instance identifier
}

@[inline]
pub fn (l &LayerInstance) layer_type() LayerType {
	return layer_type_from_string(l.typ)
}

// returns whichever tile array is populated for this layer type
pub fn (l &LayerInstance) tiles() []Tile {
	return if l.grid_tiles.len > 0 { l.grid_tiles } else { l.auto_layer_tiles }
}

// levels

pub struct Neighbour {
pub:
	level_iid string @[json: 'levelIid'] // Neighbour Instance Identifier

	// dir (String) Generic badge : A lowercase string tipping on the level location (north, south, west, east).
	// Since 1.4.0, this value can also be < (neighbour depth is lower), > (neighbour depth is greater) or o (levels overlap and share the same world depth).
	// Since 1.5.3, this value can also be nw,ne,sw or se for levels only touching corners.
	dir string @[json: 'dir']
}

@[minify]
pub struct Level {
pub:
	identifier  string @[json: 'identifier'] // User defined unique identifier
	iid         string @[json: 'iid']        // Unique instance identifier
	uid         int    @[json: 'uid']        // Unique Int identifier
	world_x     int    @[json: 'worldX']     // World X coordinate in pixels.
	world_y     int    @[json: 'worldY']     // World Y coordinate in pixels.
	world_depth int    @[json: 'worldDepth'] // Index that represents the "depth" of the level in the world.
	px_width    int    @[json: 'pxWid']      // Width of the level in pixels
	px_height   int    @[json: 'pxHei']      // Height of the level in pixels
	bg_color    string @[json: '__bgColor']  // Background color of the level (same as bgColor, except the default value is automatically used here if its value is null)

	// An array containing all Layer instances. IMPORTANT: if the project option "Save levels separately" is enabled, this field will be null.
	// This array is sorted in display order: the 1st layer is the top-most and the last is behind.
	// null when using external level files — call load_external_level() to fill it
	layer_instances ?[]LayerInstance @[json: 'layerInstances']

	// This value is not null if the project option "Save levels separately" is enabled. In this case, this relative path points to the level Json file.
	external_rel_path ?string @[json: 'externalRelPath']

	// An array listing all other levels touching this one on the world map. Since 1.4.0, this includes levels that overlap in the same world layer, or in nearby world layers.
	// Only relevant for world layouts where level spatial positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, this array is always empty.
	neighbours []Neighbour @[json: '__neighbours']
}

// tileset definitions

@[minify]
pub struct TilesetDef {
pub:
	uid            int     @[json: 'uid']        // Unique Intidentifier
	identifier     string  @[json: 'identifier'] // User defined unique identifier
	rel_path       ?string @[json: 'relPath']    // null for embedded/atlas tilesets
	tile_grid_size int     @[json: 'tileGridSize']
	px_width       int     @[json: 'pxWid']   // Image width in pixels
	px_height      int     @[json: 'pxHei']   // Image height in pixels
	spacing        int     @[json: 'spacing'] // Space in pixels between all tiles
	padding        int     @[json: 'padding'] // Distance in pixels from image borders
}

pub struct Defs {
pub:
	tilesets []TilesetDef @[json: 'tilesets']
}

// worlds

@[minify]
pub struct World {
pub:
	identifier string @[json: 'identifier'] // User defined unique identifier
	iid        string @[json: 'iid']        // Unique instance identifer

	// All levels from this world.
	// The order of this array is only relevant in LinearHorizontal and linearVertical world layouts (see worldLayout value).
	// Otherwise, you should refer to the worldX,worldY coordinates of each Level.
	levels       []Level @[json: 'levels']
	world_layout string  @[json: 'worldLayout'] // "Free", "GridVania", "LinearHorizontal", "LinearVertical"
}

// project root

@[minify]
pub struct Project {
pub:
	json_version string @[json: 'jsonVersion'] // File format version
	iid          string @[json: 'iid']         // Unique project identifier
	defs         Defs   @[json: 'defs']        // A structure containing all the definitions of this project

	// LDtk 1.0+: levels live inside worlds[]. The top-level levels[] is kept
	// for backward compatibility but will be empty when worlds are used.
	worlds          []World @[json: 'worlds']
	levels          []Level @[json: 'levels']
	external_levels bool    @[json: 'externalLevels']
}

// Returns all levels regardless of whether the project uses worlds or not.
pub fn (p &Project) all_levels() []Level {
	if p.worlds.len > 0 {
		mut out := []Level{}
		for w in p.worlds {
			out << w.levels
		}
		return out
	}
	return p.levels
}
