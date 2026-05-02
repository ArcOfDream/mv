module engine

import raylib as rl
import raylib.raymath as rm
import math
import mv.lib.wren
import core { Transform2D, Vec2 }

@[heap]
pub struct Node {
mut:
	queued_free    bool
	dirty          bool = true
	app            &App
	node_name      string
	parent         ?&INode
	children       []INode
	local_matrix   rl.Matrix
	global_matrix  rl.Matrix
	local_matrix_f rm.Float16
	signals        SignalTable

	// set by the Wren allocator; its presence means
	// "call back into Wren for update/draw"
	// doubles as the persistent Wren object handle
	wren_handle ?&wren.Handle
	wren_owned  bool
pub mut:
	process_flags ProcessFlags = .transform | .draw
	// script_class/script_module: Wren class to attach on ready.
	// script_module is the import path (e.g. "game/player"); empty = "main".
	// script_class is the Wren class name (e.g. "Player").
	script_class  string
	script_module string
	scene_file    string // non-empty = this node is a scene instance loaded from that path
	angle_deg     f32
	angle_rad     f32
	pos           Vec2
	scale         Vec2        = Vec2{1, 1}
	transform     Transform2D = Transform2D{
		dirty: true
	}

	path_cache map[string]?INode
}

pub fn Node.instantiate(app &App, name string) &Node {
	return &Node{
		app:       app
		node_name: name
	}
}

pub fn Node.new(app &App, name string) &Node {
	return Node.instantiate(app, name)
}

pub fn (mut n Node) init_from_wren(vm &wren.VM) {
	n.node_name = vm.get_slot_string(1)
	n.app = unsafe { &App(vm.get_user_data()) }
	n.wren_handle = vm.get_slot_handle(0)
	n.wren_owned = true
	n.process_flags = .transform | .draw
	n.dirty = true
	n.transform = Transform2D{
		dirty: true
	}
	n.scale = Vec2{1, 1}
	n.parent = ?&INode(none)
	n.children = []
	n.signals = SignalTable{}
}

@[inline]
pub fn (n &Node) app() &App {
	return n.app
}

@[inline]
pub fn (n &Node) get_parent() ?&INode {
	return n.parent
}

@[inline]
pub fn (n &Node) name() string {
	return n.node_name
}

pub fn (mut n Node) set_name(val string) {
	n.node_name = val
}

// node_ptr returns the address of the concrete struct. because Node is always
// embedded as the first field, this pointer equals the outer struct's address
// regardless of which concrete type is behind the INode interface.
@[inline]
pub fn (n &Node) node_ptr() voidptr {
	return voidptr(n)
}

fn (n &Node) wren_class_name() string {
	return 'Node'
}

// --- local getters and setters ---

@[inline]
pub fn (n &Node) get_pos() Vec2 {
	return n.pos
}

@[inline]
pub fn (mut n Node) set_pos(val Vec2) {
	if n.pos != val {
		n.dirty = true
		n.transform.dirty = true
		n.pos = val
	}
}

@[inline]
pub fn (n &Node) get_scale() Vec2 {
	return n.scale
}

@[inline]
pub fn (mut n Node) set_scale(val Vec2) {
	if n.scale != val {
		n.dirty = true
		n.transform.dirty = true
		n.scale = val
	}
}

@[inline]
pub fn (n &Node) get_angle_deg() f32 {
	return n.angle_deg
}

@[inline]
pub fn (mut n Node) set_angle_deg(val f32) {
	if n.angle_deg != val {
		n.dirty = true
		n.transform.dirty = true
		n.angle_deg = val
		n.angle_rad = f32(math.radians(val))
	}
}

@[inline]
pub fn (n &Node) get_angle_rad() f32 {
	return n.angle_rad
}

@[inline]
pub fn (mut n Node) set_angle_rad(val f32) {
	if n.angle_rad != val {
		n.dirty = true
		n.transform.dirty = true
		n.angle_deg = f32(math.degrees(val))
		n.angle_rad = val
	}
}

// --- matrix funcs ---

@[inline]
pub fn (mut n Node) get_global_matrix() rl.Matrix {
	if mut p := n.parent {
		n.global_matrix = rm.matrix_multiply(n.get_local_matrix(), p.get_global_matrix())
	} else {
		n.global_matrix = n.get_local_matrix()
	}
	return n.global_matrix
}

@[inline]
pub fn (mut n Node) get_local_matrix() rl.Matrix {
	if n.dirty {
		n.rebuild_local_matrix()
	}
	return n.local_matrix
}

@[inline]
fn (mut n Node) rebuild_local_matrix() {
	mut mat := rm.matrix_identity()
	mat = rm.matrix_multiply(mat, rm.matrix_scale(n.scale.x, n.scale.y, 1))
	mat = rm.matrix_multiply(mat, rm.matrix_rotate_z(n.angle_rad))
	mat = rm.matrix_multiply(mat, rm.matrix_translate(n.pos.x, n.pos.y, 0))
	n.local_matrix = mat
	n.local_matrix_f = rm.matrix_to_float_v(mat)
	n.dirty = false
}

@[inline]
fn (mut n Node) sync_transform() {
	if n.transform.dirty {
		n.transform = core.decompose_matrix(n.get_global_matrix())
	}
}

// --- global getters ---

@[inline]
pub fn (mut n Node) get_global_pos() Vec2 {
	n.sync_transform()
	return n.transform.translation
}

@[inline]
pub fn (mut n Node) get_global_scale() Vec2 {
	n.sync_transform()
	return n.transform.scale
}

@[inline]
pub fn (mut n Node) get_global_angle_rad() f32 {
	n.sync_transform()
	return n.transform.rotation
}

@[inline]
pub fn (mut n Node) get_global_angle_deg() f32 {
	n.sync_transform()
	return f32(math.degrees(n.transform.rotation))
}

// --- global setters ---

@[inline]
pub fn (mut n Node) set_global_pos(val Vec2) {
	if p := n.parent {
		inv_mat := rm.matrix_invert(p.global_matrix)
		n.set_pos(rm.vector2_transform(val, inv_mat))
	} else {
		n.set_pos(val)
	}
	n.transform.dirty = true
}

@[inline]
pub fn (mut n Node) set_global_scale(val Vec2) {
	if p := n.parent {
		n.set_scale(val / p.transform.scale)
	} else {
		n.set_scale(val)
	}
	n.transform.dirty = true
}

@[inline]
pub fn (mut n Node) set_global_angle_rad(val f32) {
	if p := n.parent {
		n.set_angle_rad(val - p.transform.rotation)
	} else {
		n.set_angle_rad(val)
	}
	n.transform.dirty = true
}

@[inline]
pub fn (mut n Node) set_global_angle_deg(val f32) {
	if p := n.parent {
		n.set_angle_deg(val - f32(math.degrees(p.transform.rotation)))
	} else {
		n.set_angle_deg(val)
	}
	n.transform.dirty = true
}

// --- overridable functions ---

@[inline]
fn (mut n Node) push_mat_internal() {
	push_matrix()
	mult_matrix_f(n.local_matrix_f)
}

// push_local_matrix is for external node types overriding push_mat_internal.
// Call it in the .fix branch to replicate standard Node matrix behaviour.
@[inline]
pub fn (mut n Node) push_local_matrix() {
	push_matrix()
	mult_matrix_f(n.local_matrix_f)
}

@[inline]
fn (mut n Node) pop_mat_internal() {
	pop_matrix()
}

@[inline]
fn (n &Node) init_internal() {}

pub fn (n &Node) init() {}

fn (mut n Node) ready_internal() {}

pub fn (mut n Node) ready() {}

// node_wren_attach runs the Wren script attachment for a node that has
// script_class set. Must be called via INode so wren_class_name() dispatches
// to the correct concrete type (e.g. Sprite -> NativeSprite).
fn node_wren_attach(mut node INode) {
	if node.wren_owned {
		return
	}
	base := unsafe { &Node(node.node_ptr()) }
	if base.script_class == '' {
		return
	}
	mut vm := node.app.wren_vm or { return }
	h := node.app.wren_from_native_handle or { return }

	mod := if base.script_module != '' { base.script_module } else { 'main' }
	native_cls := match node.wren_class_name() {
		'Sprite' { 'NativeSprite' }
		else { 'NativeNode' }
	}

	// bootstrap into a unique throwaway module to avoid re-defining 'main' and
	// to sidestep wrenGetVariable limitations - both user class and native class
	// are imported here so they can be looked up via the bootstrap module name.
	node.app.wren_bootstrap_seq++
	bootstrap := '__ready_${node.app.wren_bootstrap_seq}'
	src := 'import "${mod}" for ${base.script_class}\nimport "mv/node" for ${native_cls}'
	if vm.interpret(bootstrap, src) != .success {
		return
	}

	vm.ensure_slots(3)
	vm.get_variable(bootstrap, base.script_class, 0)
	vm.get_variable(bootstrap, native_cls, 2)
	raw := vm.set_slot_new_foreign(1, 2, sizeof(voidptr))
	unsafe {
		*(&voidptr(raw)) = node.node_ptr()
	}
	if vm.call(h) != .success {
		return
	}
	node.wren_owned = true
}

fn (n &Node) exit_tree_internal() {}

pub fn (n &Node) exit_tree() {}

@[inline]
fn (mut n Node) update_internal(_dt f32) {}

pub fn (mut n Node) update(_dt f32) {}

@[inline]
fn (mut n Node) draw_internal() {}

pub fn (mut n Node) draw() {}

// --- scene tree funcs ---

@[inline]
pub fn (mut n Node) get_children() []INode {
	return n.children
}

@[inline]
pub fn (n &Node) get_child_count() int {
	return n.children.len
}

pub fn (mut n Node) add_child(mut child INode) {
	child.set_name(n.unique_child_name(child.name()))
	child.parent = n
	n.children << child
	n.path_cache.clear()
	emit_notification(mut child, .ready)
}

fn (n &Node) unique_child_name(desired string) string {
	existing := n.children.map(it.name())
	if desired !in existing {
		return desired
	}
	mut i := 2
	for {
		candidate := '${desired}${i}'
		if candidate !in existing {
			return candidate
		}
		i++
	}
	return desired
}

pub fn (mut n Node) create_and_add_child[T](name string) &T {
	mut node := &T{
		node_name: name
		app:       n.app
	}
	emit_notification(mut node, .init)
	n.add_child(mut node)

	return node
}

@[inline]
pub fn (n &Node) find_child(child INode) int {
	target := child.node_ptr()
	for i, c in n.children {
		if c.node_ptr() == target {
			return i
		}
	}
	return -1
}

@[inline]
pub fn (mut n Node) remove_child(index int) {
	if index < 0 || index >= n.children.len {
		return
	}

	mut child := n.children[index]
	child.parent = ?&INode(none)
	n.path_cache.clear()
	child.path_cache.clear()
	emit_notification(mut child, .exit_tree)
	n.children.delete(index)
}

pub fn (mut n Node) insert_child_at(index int, mut child INode) {
	child.set_name(n.unique_child_name(child.name()))
	child.parent = n
	n.children.insert(index, child)
	emit_notification(mut child, .ready)
}

pub fn (mut n Node) reparent(mut new_parent INode) {
	if mut p := n.parent {
		idx := p.find_child(n)
		if idx != -1 {
			p.children.delete(idx)
			p.path_cache.clear()
		}
	}
	n.path_cache.clear()
	new_parent.add_child(mut n)
}

pub fn (mut n Node) replace_by(mut node INode) {
	if mut p := n.parent {
		idx := p.find_child(n)
		if idx != -1 {
			p.children.delete(idx)
			p.path_cache.clear()
			p.insert_child_at(idx, mut node)
		}
	}
	emit_notification(mut n, .exit_tree)
	n.path_cache.clear()
	n.parent = ?&INode(none)
}

pub fn (mut n Node) move_child(index int, to int) {
	if index < 0 || index >= n.children.len || to < 0 || to >= n.children.len || index == to {
		return
	}
	child := n.children[index]
	n.children.delete(index)
	n.children.insert(to, child)
	n.path_cache.clear()
}

pub fn (mut n Node) swap_children(index_a int, index_b int) {
	if index_a < 0 || index_a >= n.children.len || index_b < 0 || index_b >= n.children.len
		|| index_a == index_b {
		return
	}
	n.children[index_a], n.children[index_b] = n.children[index_b], n.children[index_a]
}

pub fn (mut n Node) queue_free() {
	if !n.queued_free {
		n.queued_free = true
		n.app.pending_free << n
	}
}

// --- node path ---

pub fn (node &Node) get_path() NodePath {
	mut parts := []string{}
	mut cur_ptr := node.node_ptr()
	for {
		cur := unsafe { &Node(cur_ptr) }
		parts.prepend(cur.name())
		if p := cur.parent {
			cur_ptr = p.node_ptr()
		} else {
			break
		}
	}
	return NodePath{
		parts:    parts
		absolute: true
		raw:      '/' + parts.join('/')
	}
}

pub fn (mut n Node) get_node(path NodePath) ?INode {
	key := path.raw
	if key in n.path_cache {
		return n.path_cache[key]
	}
	result := n.app.get_node(INode(n), path)
	n.path_cache[key] = result
	return result
}

pub fn (node &Node) get_path_to(target &INode) NodePath {
	// Find lowest common ancestor, then build relative path
	src_parts := node.get_path().parts
	tgt_parts := target.get_path().parts

	// Find where they diverge
	mut common := 0
	for common < src_parts.len && common < tgt_parts.len {
		if src_parts[common] != tgt_parts[common] {
			break
		}
		common++
	}

	// Steps up from src to common ancestor
	ups := src_parts.len - common

	mut parts := []string{}
	for _ in 0 .. ups {
		parts << '..'
	}

	// Steps down from common ancestor to target
	parts << tgt_parts[common..]

	return NodePath{
		parts:    parts
		absolute: false
		raw:      parts.join('/')
	}
}

// --- signals ---

pub fn (mut n Node) connect(signal string, handler SignalHandler) {
	n.signals.connect(signal, handler)
}

pub fn (mut n Node) disconnect_all(signal string) {
	n.signals.disconnect_all(signal)
}

pub fn (mut n Node) emit_signal(signal string, args ...SignalArg) {
	n.signals.emit(signal, &n, args, n.app.wren_vm, n.app.wren_signal_call_handles)
}

// --- notifications ---

@[direct_array_access]
pub fn emit_notification(mut node INode, notification Notification) {
	match notification {
		.draw {
			if node.process_flags.has(.draw) {
				notify(mut node, .push_mat)
				notify(mut node, .draw)

				for mut child in node.get_children() {
					emit_notification(mut child, .draw)
				}
				notify(mut node, .pop_mat)
			}
		}
		.update {
			notify(mut node, notification)

			if node.process_flags.has(.transform) {
				if p := node.parent {
					if p.dirty {
						node.dirty = true
					}
				}

				// snapshot before rebuild_local_matrix clears node.dirty
				was_dirty := node.dirty || node.transform.dirty

				if node.dirty {
					node.rebuild_local_matrix()
				}

				if p := node.parent {
					node.global_matrix = rm.matrix_multiply(node.local_matrix, p.global_matrix)
				} else {
					node.global_matrix = node.local_matrix
				}

				if was_dirty {
					node.transform = core.decompose_matrix(node.global_matrix)
					node.transform.dirty = false
				}
			}

			for mut child in node.get_children() {
				emit_notification(mut child, notification)
			}

			node.dirty = false
		}
		else {
			for mut child in node.get_children() {
				emit_notification(mut child, notification)
			}
			notify(mut node, notification)
		}
	}
}

pub fn notify(mut node INode, notification Notification) {
	match notification {
		.push_mat {
			node.push_mat_internal()
		}
		.draw {
			node.draw_internal()
			node.draw()

			if node.wren_owned {
				if handle := node.wren_handle {
					if mut vm := node.app.wren_vm {
						if draw_h := node.app.wren_draw_handle {
							vm.ensure_slots(1)
							vm.set_slot_handle(0, handle)
							vm.call(draw_h)
						}
					}
				}
			}
		}
		.pop_mat {
			node.pop_mat_internal()
		}
		.init {
			node.init_internal()
			node.init()
		}
		.ready {
			node.ready_internal()
			node.ready()
			node_wren_attach(mut node)
		}
		.exit_tree {
			node.exit_tree_internal()
			node.exit_tree()
		}
		.update {
			node.update_internal(node.app.state.dt())
			node.update(node.app.state.dt())

			if node.wren_owned {
				if handle := node.wren_handle {
					if mut vm := node.app.wren_vm {
						if update_h := node.app.wren_update_handle {
							vm.ensure_slots(2)
							vm.set_slot_handle(0, handle)
							vm.set_slot_double(1, node.app.state.dt())
							vm.call(update_h)
						}
					}
				}
			}
		}
		else {}
	}
}
