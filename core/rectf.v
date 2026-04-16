module core

import math

// adapted from prime31's via

// RectF is a float rectangle defined by a top-left origin and size.
// coordinates follow screen-space convention: x increases right, y increases down.
// use AABB from the physics module for collision shapes; RectF is for
// camera bounds, UI layout, sprite source regions, and general geometry.
pub struct RectF {
pub mut:
	x f32
	y f32
	w f32
	h f32
}

pub fn (r RectF) str() string {
	return 'RectF(${r.x}, ${r.y}, ${r.w}, ${r.h})'
}

@[inline]
pub fn (r RectF) right() f32 {
	return r.x + r.w
}

@[inline]
pub fn (r RectF) bottom() f32 {
	return r.y + r.h
}

@[inline]
pub fn (r RectF) center() Vec2 {
	return Vec2{r.x + r.w * 0.5, r.y + r.h * 0.5}
}

@[inline]
pub fn (r RectF) centerx() f32 {
	return r.x + r.w * 0.5
}

@[inline]
pub fn (r RectF) centery() f32 {
	return r.y + r.h * 0.5
}

// RectF.from_min_max constructs a RectF from explicit min/max coordinates.
// useful when converting from physics AABB{min, max} representation.
@[inline]
pub fn RectF.from_min_max(min_x f32, min_y f32, max_x f32, max_y f32) RectF {
	return RectF{min_x, min_y, max_x - min_x, max_y - min_y}
}

// edge_coord returns the coordinate of the given edge.
@[inline]
pub fn (r RectF) edge_coord(e Edge) f32 {
	return match e {
		.left   { r.x }
		.right  { r.right() }
		.top    { r.y }
		.bottom { r.bottom() }
	}
}

// overlaps returns true if this rect and other share any area.
// touching edges (zero-area overlap) return false.
@[inline]
pub fn (r RectF) overlaps(other RectF) bool {
	return r.x < other.right() && r.right() > other.x &&
	       r.y < other.bottom() && r.bottom() > other.y
}

// contains returns true if (px, py) lies within the rect.
// uses a half-open interval: [x, x+w) × [y, y+h).
@[inline]
pub fn (r RectF) contains(px f32, py f32) bool {
	return px >= r.x && px < r.right() && py >= r.y && py < r.bottom()
}

// contains_rect returns true if other lies entirely within this rect.
@[inline]
pub fn (r RectF) contains_rect(other RectF) bool {
	return other.x >= r.x && other.right() <= r.right() &&
	       other.y >= r.y && other.bottom() <= r.bottom()
}

// expand grows the rect directionally by (dx, dy).
// a positive dx extends the right edge; a negative dx extends the left edge.
// the total width increases by |dx| regardless of sign, and similarly for dy.
pub fn (r RectF) expand(dx f32, dy f32) RectF {
	return RectF{
		x: if dx >= 0 { r.x } else { r.x + dx }
		y: if dy >= 0 { r.y } else { r.y + dy }
		w: r.w + math.abs(dx)
		h: r.h + math.abs(dy)
	}
}

// grow returns a copy expanded outward on all sides by amount.
// a negative amount shrinks the rect.
@[inline]
pub fn (r RectF) grow(amount f32) RectF {
	return RectF{r.x - amount, r.y - amount, r.w + amount * 2, r.h + amount * 2}
}

// expand_edge extends a single edge outward by amount.
// the opposite edge is unchanged.
pub fn (r RectF) expand_edge(e Edge, amount f32) RectF {
	a := math.abs(amount)
	return match e {
		.left   { RectF{r.x - a, r.y, r.w + a, r.h} }
		.right  { RectF{r.x, r.y, r.w + a, r.h} }
		.top    { RectF{r.x, r.y - a, r.w, r.h + a} }
		.bottom { RectF{r.x, r.y, r.w, r.h + a} }
	}
}

// half_rect returns the half of the rect on the given edge's side.
pub fn (r RectF) half_rect(e Edge) RectF {
	return match e {
		.top    { RectF{r.x, r.y, r.w, r.h * 0.5} }
		.bottom { RectF{r.x, r.y + r.h * 0.5, r.w, r.h * 0.5} }
		.left   { RectF{r.x, r.y, r.w * 0.5, r.h} }
		.right  { RectF{r.x + r.w * 0.5, r.y, r.w * 0.5, r.h} }
	}
}

// union_rect returns the smallest rect that contains both r and other.
pub fn (r RectF) union_rect(other RectF) RectF {
	x := math.min(r.x, other.x)
	y := math.min(r.y, other.y)
	return RectF{
		x: x
		y: y
		w: math.max(r.right(), other.right()) - x
		h: math.max(r.bottom(), other.bottom()) - y
	}
}

// union_pt expands r to include the point (px, py), returning the resulting rect.
@[inline]
pub fn (r RectF) union_pt(px f32, py f32) RectF {
	return r.union_rect(RectF{px, py, 0, 0})
}

// intersection returns the overlapping region of r and other.
// returns none if the rects do not overlap.
pub fn (r RectF) intersection(other RectF) ?RectF {
	x := math.max(r.x, other.x)
	y := math.max(r.y, other.y)
	w := math.min(r.right(), other.right()) - x
	h := math.min(r.bottom(), other.bottom()) - y
	if w > 0 && h > 0 {
		return RectF{x, y, w, h}
	}
	return none
}

// minkowski_diff returns the Minkowski difference of r (mover) and other (obstacle).
// the result is the region in which r's top-left corner can sit while r overlaps other.
// used by sweep tests: if the origin lies inside the diff rect, the shapes overlap.
@[inline]
pub fn (r RectF) minkowski_diff(other RectF) RectF {
	return RectF{
		x: other.x - r.w
		y: other.y - r.h
		w: r.w + other.w
		h: r.h + other.h
	}
}