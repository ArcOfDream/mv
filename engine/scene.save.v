module engine

import mv.typeinfo
import os

// node_to_json serialises a full node subtree (including children) to JSON.
pub fn (app &App) node_to_json(mut node INode) !string {
	mut enc := typeinfo.JsonEncoder.new()
	save_node(mut node, app, mut enc)!
	return enc.to_string()
}

// node_to_json_shallow serialises a node's base fields and type-specific fields
// without recursing into children. Used for inspector undo snapshots.
pub fn (app &App) node_to_json_shallow(mut node INode) !string {
	type_name := node.wren_class_name()
	reg := app.scene_registry.nodes[type_name] or {
		return error('node_to_json_shallow: unregistered type "${type_name}"')
	}
	mut enc := typeinfo.JsonEncoder.new()
	enc.begin_object()!
	enc.key('pos')
	write_vec2_scene(node.get_pos(), mut enc)!
	enc.key('scale')
	write_vec2_scene(node.get_scale(), mut enc)!
	enc.key('angle_deg')
	enc.write_f64(f64(node.get_angle_deg()))!
	reg.write(node.node_ptr(), app, mut enc)!
	enc.end_object()!
	return enc.to_string()
}

pub fn (app &App) clone_node(mut node INode) !INode {
	mut enc := typeinfo.JsonEncoder.new()
	save_node(mut node, app, mut enc)!
	src := enc.to_string()
	mut dec := typeinfo.JsonDecoder.parse(src)!
	return load_node(mut dec, app, os.getwd())
}

pub fn (app &App) save_scene(path string) ! {
	mut root := app.scene_root or { return error('save_scene: no scene root') }
	mut enc := typeinfo.JsonEncoder.new()
	mut root_node := INode(root)
	save_node(mut root_node, app, mut enc)!
	os.write_file(path, enc.to_string())!
}

fn save_node(mut node INode, app &App, mut enc typeinfo.JsonEncoder) ! {
	base := unsafe { &Node(node.node_ptr()) }

	if base.scene_file != '' {
		enc.begin_object()!
		enc.key('scene')
		enc.write_string(base.scene_file)!
		enc.key('name')
		enc.write_string(node.name())!
		enc.key('pos')
		write_vec2_scene(node.get_pos(), mut enc)!
		enc.key('scale')
		write_vec2_scene(node.get_scale(), mut enc)!
		enc.key('angle_deg')
		enc.write_f64(f64(node.get_angle_deg()))!
		enc.end_object()!
		return
	}

	type_name := node.wren_class_name()
	reg := app.scene_registry.nodes[type_name] or {
		return error('save_node: unregistered type "${type_name}"')
	}

	enc.begin_object()!
	enc.key('type')
	enc.write_string(type_name)!
	enc.key('name')
	enc.write_string(node.name())!
	enc.key('pos')
	write_vec2_scene(node.get_pos(), mut enc)!
	enc.key('scale')
	write_vec2_scene(node.get_scale(), mut enc)!
	enc.key('angle_deg')
	enc.write_f64(f64(node.get_angle_deg()))!

	if base.script_class != '' {
		enc.key('script_class')
		enc.write_string(base.script_class)!
		enc.key('script_module')
		enc.write_string(base.script_module)!
	}

	reg.write(node.node_ptr(), app, mut enc)!

	enc.key('children')
	enc.begin_array()!
	for mut child in node.get_children() {
		save_node(mut child, app, mut enc)!
	}
	enc.end_array()!

	enc.end_object()!
}
