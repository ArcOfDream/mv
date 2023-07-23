module graphics

import mv.math

// RenderVertex is a struct that defines information about one point of a polygon in the render.
pub struct RenderVertex {
pub mut:
	pos   math.Vec2
	color math.Vec4
	uv    math.Vec2
}
