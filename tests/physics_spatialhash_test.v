module main

import mv.physics

fn test_query_returns_registered_body() {
	mut sh := physics.SpatialHash{}
	sh.register(1, 0.0, 0.0, 32.0, 32.0)
	candidates := sh.query(0.0, 0.0, 32.0, 32.0)
	assert 1 in candidates
}

fn test_query_excludes_non_overlapping_body() {
	mut sh := physics.SpatialHash{}
	sh.register(1, 0.0, 0.0, 32.0, 32.0)
	candidates := sh.query(200.0, 200.0, 32.0, 32.0)
	assert 1 !in candidates
}

fn test_query_no_duplicates_for_large_body() {
	mut sh := physics.SpatialHash{}
	// body spans many cells
	sh.register(1, 0.0, 0.0, 512.0, 512.0)
	candidates := sh.query(0.0, 0.0, 512.0, 512.0)
	count := candidates.filter(it == 1).len
	assert count == 1
}

fn test_multiple_bodies_in_same_cell() {
	mut sh := physics.SpatialHash{}
	sh.register(1, 0.0, 0.0, 32.0, 32.0)
	sh.register(2, 10.0, 10.0, 16.0, 16.0)
	candidates := sh.query(0.0, 0.0, 32.0, 32.0)
	assert 1 in candidates
	assert 2 in candidates
}

fn test_clear_removes_dynamic_bodies() {
	mut sh := physics.SpatialHash{}
	sh.register(1, 0.0, 0.0, 32.0, 32.0)
	sh.clear()
	candidates := sh.query(0.0, 0.0, 32.0, 32.0)
	assert 1 !in candidates
}

fn test_static_body_survives_clear() {
	mut sh := physics.SpatialHash{}
	sh.register_static_shape(42, physics.Shape(physics.AABB{
		min: physics.Vec{0, 0}
		max: physics.Vec{32, 32}
	}))
	sh.clear()
	candidates := sh.query(0.0, 0.0, 32.0, 32.0)
	assert 42 in candidates
}

fn test_unregister_static_removes_body() {
	mut sh := physics.SpatialHash{}
	sh.register_static_shape(42, physics.Shape(physics.AABB{
		min: physics.Vec{0, 0}
		max: physics.Vec{32, 32}
	}))
	sh.unregister_static(42)
	candidates := sh.query(0.0, 0.0, 32.0, 32.0)
	assert 42 !in candidates
}

fn test_query_adjacent_cell_not_included() {
	mut sh := physics.SpatialHash{
		cell_size: 64
	}
	sh.register(1, 0.0, 0.0, 32.0, 32.0)
	// query a region in a clearly different cell
	candidates := sh.query(128.0, 128.0, 32.0, 32.0)
	assert 1 !in candidates
}
