module engine

pub struct NodePath {
	parts    []string // pre-split: ["UI", "HealthBar", "Label"]
	absolute bool     // true if path starts from scene root
	raw      string   // original string for display/serialization
}

const path_self = '.'
const path_parent = '..'

pub fn parse_node_path(path string) ?NodePath {
	if path == '' {
		return none
	}
	mut absolute := false
	mut working := path
	if path.starts_with('/') {
		absolute = true
		working = path[1..]
	}
	parts := working.split('/').filter(it != '')
	for part in parts {
		if part == path_self || part == path_parent {
			continue
		}
		if !is_valid_node_name(part) {
			return none
		}
	}
	return NodePath{
		parts:    parts
		absolute: absolute
		raw:      path
	}
}

fn is_valid_node_name(s string) bool {
	if s.len == 0 {
		return false
	}
	for ch in s {
		if !ch.is_letter() && !ch.is_digit() && ch != `_` {
			return false
		}
	}
	return true
}
