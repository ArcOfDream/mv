module graphics

import mv.resource

pub struct Batch {
	vbo VertexBuffer
pub mut:
	// just_set_active bool = false
	shader_id      u32
	shader_ref     ?&resource.Shader
	active_texture u32
	vertex_count   u32
	max_vertices   u32
	vertices       []RenderVertex
}
