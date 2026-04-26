module main

import mv.engine
import mv.core { Vec2 }
import raylib { Color }
import os

fn make_test_app() &engine.App {
	mut app := engine.App.new(none, none, none, none)
	engine.register_builtin_nodes(mut app.scene_registry, app)
	return app
}

fn test_save_load_single_node() {
	mut app := make_test_app()

	mut root := engine.Node.new(app, 'root')
	root.set_pos(Vec2{10.0, 20.0})
	root.set_scale(Vec2{2.0, 2.0})
	root.set_angle_deg(45.0)
	app.scene_root = root

	tmp := os.join_path(os.temp_dir(), 'scene_test_single.json')
	app.save_scene(tmp)!

	app.scene_root = none
	app.load_scene(tmp)!

	mut loaded := app.scene_root or { panic('no scene root after load') }
	assert loaded.name() == 'root'
	assert loaded.get_pos().x == 10.0
	assert loaded.get_pos().y == 20.0
	assert loaded.get_scale().x == 2.0
	assert loaded.get_angle_deg() == 45.0

	os.rm(tmp) or {}
}

fn test_save_load_tree() {
	mut app := make_test_app()

	mut root := engine.Node.new(app, 'root')
	mut child_a := engine.Node.new(app, 'child_a')
	mut child_b := engine.Node.new(app, 'child_b')
	child_a.set_pos(Vec2{5.0, 0.0})
	child_b.set_pos(Vec2{0.0, 5.0})
	root.add_child(mut child_a)
	root.add_child(mut child_b)
	app.scene_root = root

	tmp := os.join_path(os.temp_dir(), 'scene_test_tree.json')
	app.save_scene(tmp)!
	app.scene_root = none
	app.load_scene(tmp)!

	mut loaded := app.scene_root or { panic('no scene root after load') }
	assert loaded.get_child_count() == 2
	children := loaded.get_children()
	assert children[0].name() == 'child_a'
	assert children[0].get_pos().x == 5.0
	assert children[1].name() == 'child_b'
	assert children[1].get_pos().y == 5.0

	os.rm(tmp) or {}
}

fn test_save_load_sprite_fields() {
	mut app := make_test_app()

	mut root := engine.Node.new(app, 'root')
	mut spr := engine.Sprite.new(app, 'hero', none)
	spr.tint = Color{128, 64, 32, 200}
	spr.h_frames = 4
	spr.v_frames = 2
	spr.flip_h = true
	spr.current_frame = 3
	spr.set_centered(false)
	spr.set_offset(Vec2{8.0, 8.0})
	root.add_child(mut spr)
	app.scene_root = root

	tmp := os.join_path(os.temp_dir(), 'scene_test_sprite.json')
	app.save_scene(tmp)!
	app.scene_root = none
	app.load_scene(tmp)!

	mut loaded_root := app.scene_root or { panic('no scene root after load') }
	children := loaded_root.get_children()
	assert children.len == 1
	assert children[0].name() == 'hero'

	loaded_spr := unsafe { &engine.Sprite(children[0].node_ptr()) }
	assert loaded_spr.tint.r == 128
	assert loaded_spr.tint.g == 64
	assert loaded_spr.tint.b == 32
	assert loaded_spr.tint.a == 200
	assert loaded_spr.h_frames == 4
	assert loaded_spr.v_frames == 2
	assert loaded_spr.flip_h == true
	assert loaded_spr.current_frame == 3
	assert loaded_spr.get_centered() == false
	assert loaded_spr.get_offset().x == 8.0
	assert loaded_spr.get_offset().y == 8.0

	os.rm(tmp) or {}
}

fn test_save_load_timer_fields() {
	mut app := make_test_app()

	mut root := engine.Node.new(app, 'root')
	mut t := engine.Timer.instantiate(app, 'ticker')
	t.wait_time = 0.5
	t.one_shot = false
	t.autostart = false
	root.add_child(mut t)
	app.scene_root = root

	tmp := os.join_path(os.temp_dir(), 'scene_test_timer.json')
	app.save_scene(tmp)!
	app.scene_root = none
	app.load_scene(tmp)!

	mut loaded_root := app.scene_root or { panic('no scene root after load') }
	children := loaded_root.get_children()
	assert children.len == 1
	loaded_t := unsafe { &engine.Timer(children[0].node_ptr()) }
	assert loaded_t.wait_time == 0.5
	assert loaded_t.one_shot == false
	assert loaded_t.autostart == false

	os.rm(tmp) or {}
}

fn test_save_load_missing_key_defaults() {
	mut app := make_test_app()

	// Partial JSON — no type-specific fields, no children key
	json := '{"type":"Node","name":"bare","pos":{"x":1.0,"y":2.0},"scale":{"x":1.0,"y":1.0},"angle_deg":0.0,"children":[]}'

	tmp := os.join_path(os.temp_dir(), 'scene_test_partial.json')
	os.write_file(tmp, json)!
	app.load_scene(tmp)!

	loaded := app.scene_root or { panic('no scene root after load') }
	assert loaded.name() == 'bare'
	assert loaded.get_pos().x == 1.0
	assert loaded.get_pos().y == 2.0

	os.rm(tmp) or {}
}
