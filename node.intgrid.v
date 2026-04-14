module mv

import ldtk

// IntGrid stores the raw integer grid data from an LDtk IntGrid layer
// TODO: finish collision integration
@[heap]
pub struct IntGrid {
	Node
pub:
	c_width   int
	c_height  int
	grid_size int
	cells     []int // flat row-major, 0 = empty
}

pub fn IntGrid.from_layer(layer &ldtk.LayerInstance, mut parent INode) &IntGrid {
	mut ig := &IntGrid{
		node_name: layer.identifier
		app:       parent.app
		pos:       Vec2{f32(layer.px_total_offset_x), f32(layer.px_total_offset_y)}
		c_width:   layer.c_width
		c_height:  layer.c_height
		grid_size: layer.grid_size
		cells:     layer.int_grid_csv
	}
	parent.add_child(mut ig)
	return ig
}

fn (n &IntGrid) wren_class_name() string {
	return 'IntGrid'
}

// cell returns the IntGrid value at (col, row), or 0 if out of bounds
@[inline]
pub fn (ig &IntGrid) cell(col int, row int) int {
	if col < 0 || col >= ig.c_width || row < 0 || row >= ig.c_height {
		return 0
	}
	return ig.cells[row * ig.c_width + col]
}

// cell_at_px returns the IntGrid value at a pixel position within the level
@[inline]
pub fn (ig &IntGrid) cell_at_px(x f32, y f32) int {
	return ig.cell(int(x) / ig.grid_size, int(y) / ig.grid_size)
}
