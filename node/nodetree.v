module node

pub struct NodeTree {
pub mut:
	root ?Node
}

pub fn (mut t NodeTree) set_root(root ?Node) {
	t.root = root
}

// pub fn (t NodeTree) print_tree() {
// 	if r := t.root {
// 		r.print_tree(0)
// 	}
// }
