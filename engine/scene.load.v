module engine

import mv.typeinfo
import core { Vec2 }
import os

// node_from_json deserialises a full node subtree from JSON produced by node_to_json.
pub fn (app &App) node_from_json(json string) !INode {
	mut dec := typeinfo.JsonDecoder.parse(json)!
	return load_node(mut dec, app, os.getwd())
}

// apply_node_snapshot reads pos/scale/angle and type-specific fields from a
// shallow JSON snapshot (produced by node_to_json_shallow) back into an existing node.
pub fn (app &App) apply_node_snapshot(mut node INode, json string) ! {
	type_name := node.wren_class_name()
	reg := app.scene_registry.nodes[type_name] or {
		return error('apply_node_snapshot: unregistered type "${type_name}"')
	}
	mut dec := typeinfo.JsonDecoder.parse(json)!
	dec.enter_object()!
	dec.seek_key('pos') or {}
	node.set_pos(read_vec2_scene(mut dec) or { node.get_pos() })
	dec.rewind_object()
	dec.seek_key('scale') or {}
	node.set_scale(read_vec2_scene(mut dec) or { node.get_scale() })
	dec.rewind_object()
	dec.seek_key('angle_deg') or {}
	node.set_angle_deg(f32(dec.read_f64() or { f64(node.get_angle_deg()) }))
	dec.rewind_object()
	reg.read(mut dec, node.node_ptr(), app)!
}

// load_scene_as_instance loads a scene file and returns the root node without
// replacing app.scene_root. The caller sets scene_file on the returned node.
pub fn (app &App) load_scene_as_instance(path string) !INode {
	src := os.read_file(path)!
	mut dec := typeinfo.JsonDecoder.parse(src)!
	return load_node(mut dec, app, os.dir(path))
}

pub fn (mut app App) load_scene(path string) ! {
	src := os.read_file(path)!
	mut dec := typeinfo.JsonDecoder.parse(src)!
	mut root := load_node(mut dec, &app, os.dir(path))!
	if mut old := app.scene_root {
		old.queue_free()
	}
	app.scene_root = unsafe { &Node(root.node_ptr()) }
}

fn load_node(mut dec typeinfo.JsonDecoder, app &App, base_dir string) !INode {
	dec.enter_object()!
	defer { dec.exit_object() or {} }

	// scene instance reference: {"scene":"path",...}
	if _ := dec.seek_key('scene') {
		scene_ref := dec.read_string()!
		scene_path := if os.is_abs_path(scene_ref) {
			scene_ref
		} else {
			os.join_path(base_dir, scene_ref)
		}
		sub_src := os.read_file(scene_path) or {
			return error('load_node: cannot read scene "${scene_path}": ${err}')
		}
		mut sub_dec := typeinfo.JsonDecoder.parse(sub_src)!
		mut node := load_node(mut sub_dec, app, os.dir(scene_path))!
		mut base_node := unsafe { &Node(node.node_ptr()) }
		base_node.scene_file = scene_ref
		// apply per-instance overrides stored alongside the reference
		dec.rewind_object()
		if _ := dec.seek_key('name') {
			if n := dec.read_string() {
				node.set_name(n)
			}
		}
		dec.rewind_object()
		if _ := dec.seek_key('pos') {
			node.set_pos(read_vec2_scene(mut dec) or { node.get_pos() })
		}
		dec.rewind_object()
		if _ := dec.seek_key('scale') {
			node.set_scale(read_vec2_scene(mut dec) or { node.get_scale() })
		}
		dec.rewind_object()
		if _ := dec.seek_key('angle_deg') {
			node.set_angle_deg(f32(dec.read_f64() or { f64(node.get_angle_deg()) }))
		}
		return node
	}
	dec.rewind_object()

	dec.seek_key('type')!
	type_name := dec.read_string()!
	dec.seek_key('name')!
	name := dec.read_string()!

	if type_name !in app.scene_registry.nodes {
		return error('load_node: unknown type "${type_name}"')
	}
	reg := app.scene_registry.nodes[type_name]

	mut node := reg.construct(name, app)

	dec.seek_key('pos') or {}
	node.set_pos(read_vec2_scene(mut dec) or { Vec2{} })

	dec.seek_key('scale') or {}
	node.set_scale(read_vec2_scene(mut dec) or { Vec2{1, 1} })

	dec.seek_key('angle_deg') or {}
	node.set_angle_deg(f32(dec.read_f64() or { 0.0 }))

	mut base_node := unsafe { &Node(node.node_ptr()) }
	if _ := dec.seek_key('script_class') {
		base_node.script_class = dec.read_string() or { '' }
	}
	if _ := dec.seek_key('script_module') {
		base_node.script_module = dec.read_string() or { '' }
	}

	dec.rewind_object()
	reg.read(mut dec, node.node_ptr(), app)!

	dec.seek_key('children') or { return node }
	dec.enter_array()!
	mut child_buf := []INode{}
	for dec.has_next_element() {
		child_buf << load_node(mut dec, app, base_dir)!
	}
	dec.exit_array()!
	for mut c in child_buf {
		node.add_child(mut c)
	}

	return node
}
