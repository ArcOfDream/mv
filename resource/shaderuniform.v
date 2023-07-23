module resource

pub struct ShaderUniform {
pub:
	name     string
	@type    UniformType
	location int
}

pub enum UniformType {
	int
	float
	vec2
	vec3
	vec4
	mat3
	mat4
}
