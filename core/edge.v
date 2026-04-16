module core

// adapted from prime31's via

pub enum Edge {
	right
	left
	top
	bottom
}

// opposing returns the edge directly across from e.
@[inline]
pub fn (e Edge) opposing() Edge {
	return match e {
		.right  { Edge.left }
		.left   { Edge.right }
		.top    { Edge.bottom }
		.bottom { Edge.top }
	}
}

// is_horizontal returns true for left and right edges.
@[inline]
pub fn (e Edge) is_horizontal() bool {
	return e == .left || e == .right
}

// is_vertical returns true for top and bottom edges.
@[inline]
pub fn (e Edge) is_vertical() bool {
	return e == .top || e == .bottom
}

// is_max returns true for edges at the positive end of their axis
// (right and bottom). Useful when computing edge coordinates generically.
@[inline]
pub fn (e Edge) is_max() bool {
	return e == .right || e == .bottom
}