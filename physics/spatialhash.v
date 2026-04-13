module physics

import math as m

pub struct SpatialHash {
mut:
	cell_size    int
	cells        map[u64][]int // dynamic bodies, cleared each frame
	static_cells map[u64][]int // static bodies, never cleared
	seen         map[int]bool  // reused scratch — cleared per query
}

// hashing coordinates to a single u64 so that the final value
// looks like this: 0bXXXXXXXXYYYYYYYY
@[inline]
fn hash_key(x int, y int) u64 {
	return (u64(x) << 32) | (u64(y) & 0xFFFFFFFF)
}

@[inline]
fn (sh &SpatialHash) get_coords(x f32, y f32) (int, int) {
	gx := int(m.floorf(x / f32(sh.cell_size)))
	gy := int(m.floorf(y / f32(sh.cell_size)))

	return gx, gy
}

pub fn (mut sh SpatialHash) clear() {
	sh.cells.clear()
}

pub fn (mut sh SpatialHash) register(id int, x f32, y f32, w f32, h f32) {
	// check all cells the bounding box touches
	sx, sy := sh.get_coords(x, y)
	ex, ey := sh.get_coords(x + w, y + h)

	for ix in sx .. (ex + 1) {
		for iy in sy .. (ey + 1) {
			sh.cells[hash_key(ix, iy)] << id
		}
	}
}

pub fn (mut sh SpatialHash) query(x f32, y f32, w f32, h f32) []int {
	sx, sy := sh.get_coords(x, y)
	ex, ey := sh.get_coords(x + w, y + h)

	mut candidates := []int{}
	sh.seen.clear()

	for ix in sx .. (ex + 1) {
		for iy in sy .. (ey + 1) {
			key := hash_key(ix, iy)
			for id in sh.cells[key] {
				if id !in sh.seen {
					sh.seen[id] = true
					candidates << id
				}
			}
			for id in sh.static_cells[key] {
				if id !in sh.seen {
					sh.seen[id] = true
					candidates << id
				}
			}
		}
	}

	return candidates
}

pub fn (mut sh SpatialHash) register_shape(id int, shape Shape) {
	x, y, w, h := shape.bounds()
	sh.register(id, x, y, w, h)
}

pub fn (mut sh SpatialHash) register_static_shape(id int, shape Shape) {
	x, y, w, h := shape.bounds()
	sx, sy := sh.get_coords(x, y)
	ex, ey := sh.get_coords(x + w, y + h)
	for ix in sx .. (ex + 1) {
		for iy in sy .. (ey + 1) {
			sh.static_cells[hash_key(ix, iy)] << id
		}
	}
}

pub fn (mut sh SpatialHash) unregister_static(id int) {
	for key in sh.static_cells.keys() {
		sh.static_cells[key] = sh.static_cells[key].filter(it != id)
	}
}

pub fn (mut sh SpatialHash) query_shape(shape Shape) []int {
	x, y, w, h := shape.bounds()
	return sh.query(x, y, w, h)
}
