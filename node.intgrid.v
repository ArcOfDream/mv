module mv

import core { Vec2 }
import ldtk
import physics

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
pub mut:
	collision_layer u32 = 1
	collision_mask  u32 = 1
mut:
	// heap-allocated static bodies, one per merged horizontal run
	cell_bodies []&PhysicsBody
	// maps body ID → IntGrid cell value, for callers to inspect what was hit
	cell_values map[int]int
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

fn (mut ig IntGrid) ready_internal() {
	ig.build_collision_bodies()
}

fn (mut ig IntGrid) exit_tree_internal() {
	for body in ig.cell_bodies {
		id := int(voidptr(body))
		ig.app.bodies.delete(id)
		ig.app.physics_world.hash.unregister_static(id)
	}
	ig.cell_bodies.clear()
	ig.cell_values.clear()
}

fn (n &IntGrid) wren_class_name() string {
	return 'IntGrid'
}

// build_collision_bodies scans each row for contiguous non-zero runs and
// registers one static AABB per run. Called once from ready_internal.
fn (mut ig IntGrid) build_collision_bodies() {
	gs  := f32(ig.grid_size)
	// world origin of this IntGrid layer, resolved from the node transform
	ox  := ig.transform.translation.x
	oy  := ig.transform.translation.y

	for row in 0 .. ig.c_height {
		mut col := 0
		for col < ig.c_width {
			v := ig.cell(col, row)
			if v == 0 {
				col++
				continue
			}

			// extend run while value remains non-zero
			run_start := col
			for col < ig.c_width && ig.cell(col, row) != 0 {
				col++
			}
			run_end := col // exclusive

			// world-space AABB for this run — baked directly into shape,
			// body transform stays at zero so world_shape() returns as-is
			min_x := ox + f32(run_start) * gs
			min_y := oy + f32(row)       * gs
			max_x := ox + f32(run_end)   * gs
			max_y := min_y + gs

			mut body := &PhysicsBody{
				node_name:       'intgrid_cell'
				app:             ig.app
				body_type:       .static_body
				collision_layer: ig.collision_layer
				collision_mask:  ig.collision_mask
				shape:           physics.AABB{
					min: physics.Vec{min_x, min_y}
					max: physics.Vec{max_x, max_y}
				}
			}

			id := int(voidptr(body))
			ig.app.bodies[id] = body
			ig.app.physics_world.hash.register_static_shape(id, body.world_shape())
			ig.cell_bodies << body
			ig.cell_values[id] = v
		}
	}
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

// cell_value_for returns the IntGrid value associated with a CollisionResult,
// if that result came from one of this IntGrid's cell bodies. Returns 0 if
// the collision was not against this IntGrid.
@[inline]
pub fn (ig &IntGrid) cell_value_for(result &CollisionResult) int {
	id := int(voidptr(result.other))
	return ig.cell_values[id] or { 0 }
}

// is_intgrid_collision returns true if the CollisionResult came from a cell
// body owned by this IntGrid.
@[inline]
pub fn (ig &IntGrid) is_intgrid_collision(result &CollisionResult) bool {
	id := int(voidptr(result.other))
	return id in ig.cell_values
}