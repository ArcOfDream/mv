module resource

import mv.math

pub type Color = math.Vec4

pub enum ResourceType {
	image
	audio
	pxtone
	shader
	text
	json
	scene
	script
	archive
	other
	invalid
}

[heap]
pub interface Resource {
	resource_type ResourceType
mut:
	name string
}
