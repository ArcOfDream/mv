module main

struct Vec2 {
pub mut:
	x f32
	y f32
}

struct Keyframe[T] {
pub:
	time  f32
	value T
}

pub interface ITrack {
mut:
	sample(f32)
	reset()
}

struct Track[T] {
pub:
	setter_cb fn (T) @[required]
	keyframes []Keyframe[T]
}

fn (t Track[T]) sample(_ f32) {}
fn (t Track[T]) reset() {}

struct AnimationPlayer {
pub mut:
	tracks []ITrack // at least one concrete instantiation
}

interface INode {
mut:
	parent   ?&INode
	children []&INode
}

struct Node implements INode {
mut:
	parent   ?&INode
	children []&INode
}

pub fn (mut n Node) create_and_add_child[T](name string) &T {
	mut node := &T{}
	n.children << node
	return node
}

fn (mut n Node) set_pos(val Vec2) {}

fn (n &Node) find_child(child &INode) int {
	return n.children.index(child)
}

struct Sprite {
	Node
}

struct TestNode {
	Sprite
mut:
	anim_player AnimationPlayer
}

fn (mut n TestNode) ready() {
	n.anim_player.tracks << Track{ 
		fn [mut n] (v Vec2) { n.set_pos(v) }, [
		Keyframe{0.0, Vec2{1,1}}
		]}
}

fn main() {
	mut n := &Node{}
	mut child := n.create_and_add_child[TestNode]('child')
	child.ready()
	println(n.find_child(child))
}
