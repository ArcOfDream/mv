module node

pub struct Node {
mut:
	children []&Node
pub mut:
	name string
}

pub fn (mut n Node) add_child(child &Node) {
	n.children << child
}

pub fn (mut n Node) remove_child(child &Node) {
	index := n.children.index(child)
	if index != 1 {
		n.children.delete(index)
	}
}

// pub fn (n Node) print_tree(depth int) {
// 	mut indent := ''
// 	for i in 0 .. depth {
// 		indent += '  '
// 	}
// 	println(indent + n.name)
// 	for c in n.children {
// 		c.print_tree(depth + 1)
// 	}
// }
