module mv

import raylib as rl

@[heap]
pub struct CameraNode {
	Node
pub mut:
	camera rl.Camera2D
}

pub fn (mut cam CameraNode) register() {
	cam.app.set_active_camera(cam)
}

pub fn (mut cam CameraNode) deregister() {
	if cam.is_active() {
		cam.app.active_camera = ?&CameraNode(none)
	}
}

pub fn (cam &CameraNode) is_active() bool {
	if c := cam.app.active_camera {
		return c == cam
	}

	return false
}

fn (mut cam CameraNode) update_internal(_ f32) {
	p := cam.get_global_pos()
	cam.camera.target = rl.Vector2{p.x, p.y}
	cam.camera.rotation = cam.get_global_angle_deg()
	cam.camera.zoom = cam.get_global_scale().x
}
