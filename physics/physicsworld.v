module physics

pub struct PhysicsWorld {
pub mut:
	hash    SpatialHash
	gravity f32
}

// clear resets the spatial hash for the next frame.
// call this once per frame before bodies re-register
pub fn (mut pw PhysicsWorld) clear() {
	pw.hash.cells.clear()
}
