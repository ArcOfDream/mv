module engine

import raylib as rl
import rand
import math
import core { Vec2 }

@[heap]
pub struct CameraNode {
	Node
pub mut:
	camera rl.Camera2D

	// position smoothing: lerps camera.target toward the node's world position
	smoothing_enabled bool
	smoothing_speed   f32 = 5.0

	// world-space limits: camera target is clamped so the viewport edge never
	// crosses the boundary. only active when limit_enabled is true.
	limit_enabled bool
	limit_left    f32
	limit_right   f32
	limit_top     f32
	limit_bottom  f32

	// drag dead zone: camera only moves once the target leaves a central region
	// defined as a fraction of the viewport size (0 = no dead zone, 1 = full viewport)
	drag_enabled    bool
	drag_horizontal f32 = 0.2
	drag_vertical   f32 = 0.2

	// screen shake: add_trauma() increases magnitude; it decays automatically
	shake_magnitude f32
	shake_decay     f32 = 5.0
}

pub fn CameraNode.instantiate(app &App, name string) &CameraNode {
	return &CameraNode{
		app:       app
		node_name: name
	}
}

pub fn CameraNode.new(app &App, name string) &CameraNode {
	return &CameraNode{
		app:       app
		node_name: name
	}
}

fn (n &CameraNode) wren_class_name() string {
	return 'CameraNode'
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

// add_trauma increases the shake magnitude by amount (clamped to a sane ceiling).
// call once per event (explosion, hit, landing) rather than every frame.
pub fn (mut cam CameraNode) add_trauma(amount f32) {
	cam.shake_magnitude = math.min(cam.shake_magnitude + amount, 40.0)
}

fn (mut cam CameraNode) update_internal(dt f32) {
	vp := cam.app.get_viewport_size()
	zoom := if cam.camera.zoom > 0.001 { cam.camera.zoom } else { f32(1) }
	mut target := cam.get_global_pos()

	// drag: only move once the node leaves the dead zone around the current target
	if cam.drag_enabled {
		dead_x := vp.x * cam.drag_horizontal * 0.5
		dead_y := vp.y * cam.drag_vertical * 0.5
		cur := Vec2{cam.camera.target.x, cam.camera.target.y}
		dx := target.x - cur.x
		dy := target.y - cur.y
		target.x = if math.abs(dx) > dead_x {
			cur.x + dx - f32(math.sign(dx)) * dead_x
		} else {
			cur.x
		}
		target.y = if math.abs(dy) > dead_y {
			cur.y + dy - f32(math.sign(dy)) * dead_y
		} else {
			cur.y
		}
	}

	// limits: clamp so the viewport edge stays within the boundary.
	// half-extents account for zoom so limits remain correct at any zoom level.
	if cam.limit_enabled {
		hw := vp.x * 0.5 / zoom
		hh := vp.y * 0.5 / zoom
		target.x = f32(math.clamp(f64(target.x), f64(cam.limit_left + hw), f64(cam.limit_right - hw)))
		target.y = f32(math.clamp(f64(target.y), f64(cam.limit_top + hh), f64(cam.limit_bottom - hh)))
	}

	// smoothing: lerp current target toward desired target
	if cam.smoothing_enabled {
		cur := Vec2{cam.camera.target.x, cam.camera.target.y}
		t := f32(math.min(f64(cam.smoothing_speed * dt), 1.0))
		cam.camera.target.x = cur.x + (target.x - cur.x) * t
		cam.camera.target.y = cur.y + (target.y - cur.y) * t
	} else {
		cam.camera.target.x = target.x
		cam.camera.target.y = target.y
	}

	// screen shake: randomise offset each frame, decay magnitude
	if cam.shake_magnitude > 0 {
		cam.camera.offset.x = (rand.f32() * 2 - 1) * cam.shake_magnitude
		cam.camera.offset.y = (rand.f32() * 2 - 1) * cam.shake_magnitude
		cam.shake_magnitude = f32(math.max(f64(cam.shake_magnitude - cam.shake_decay * dt),
			0))
	} else {
		cam.camera.offset = rl.Vector2{}
	}

	cam.camera.rotation = cam.get_global_angle_deg()
	cam.camera.zoom = cam.get_global_scale().x
}
