module graphics

import mv.math

pub struct Camera2D {
pub mut:
	size     math.Vec2
	position math.Vec2
	offset   math.Vec2
	scale    math.Vec2 = math.Vec2{1, 1}
	rotation f32

	center_camera bool = true
mut:
	dirty bool
	view  math.Mat32
}

[inline]
pub fn (mut cam Camera2D) set_position(x f32, y f32) {
	cam.position.x = x
}

pub fn (mut cam Camera2D) update() {
	mut origin := cam.offset
	if cam.center_camera {
		origin += cam.size.mul(0.5)
	}

	cam.view = math.Mat32.identity()
	mut rotation_matrix := math.Mat32.identity()

	rotation_matrix.translate(origin.x, origin.y)
	rotation_matrix.scale(cam.scale.x, cam.scale.y)
	rotation_matrix.rotate(cam.rotation)
	rotation_matrix.translate(-origin.x, -origin.y)

	cam.view.translate(-origin.x, -origin.y)
	cam.view.translate(cam.position.x, cam.position.y)
	cam.view *= rotation_matrix

	// cam.view.translate(origin.x+cam.position.x, origin.y+cam.position.y)
	// cam.view.scale(cam.scale.x, cam.scale.y)
	// cam.view.rotate(cam.rotation)
	// cam.view.translate(-origin.x, -origin.y)
	cam.view = cam.view.inverse()
}
