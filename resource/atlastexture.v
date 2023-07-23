module resource

import mv.math

pub struct AtlasTexture {
pub:
	resource_type ResourceType = .image
pub mut:
	name string

	atlas_id u32
	quad     math.Quad
	uvs      [4]math.Vec2
}
