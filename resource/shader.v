module resource

import mv.thirdparty.gles2 as gl
import mv.math

// Shader Resource
// An abstraction over shader functions in a nice, V like package.
[heap]
pub struct Shader {
pub:
	resource_type ResourceType = .shader
pub mut:
	name string

	id       u32
	uniforms map[string]ShaderUniform
}

// TODO: Add functions for Mat3 and Mat2 if necessary

pub fn (mut s Shader) free() {
	gl.delete_shader(s.id)
}

pub fn (s Shader) use() {
	gl.use_program(s.id)
}

pub fn (mut s Shader) add_uniform(uniform_name string, uniform_type UniformType) {
	location := gl.get_uniform_location(s.id, uniform_name.str)
	// if location == -1 {
	// 	return none
	// }
	u := ShaderUniform{uniform_name, uniform_type, location}
	s.uniforms['name'] = u
}

pub fn (mut s Shader) update_uniforms() {
	for key, u in s.uniforms {
		name := key
		utype := u.@type
		location := gl.get_uniform_location(s.id, name.str)

		s.uniforms[key] = ShaderUniform{name, utype, location}
	}
}

pub fn (s Shader) set_bool(uniform ShaderUniform, value bool) {
	gl.uniform1i(uniform.location, int(value))
}

pub fn (s Shader) set_int(uniform ShaderUniform, value int) {
	gl.uniform1i(uniform.location, value)
}

pub fn (s Shader) set_float(uniform ShaderUniform, value f32) {
	gl.uniform1f(uniform.location, value)
}

pub fn (s Shader) set_vec2(uniform ShaderUniform, x f32, y f32) {
	gl.uniform2f(uniform.location, x, y)
}

pub fn (s Shader) set_vec2v(uniform ShaderUniform, vec math.Vec2) {
	gl.uniform2f(uniform.location, vec.x, vec.y)
}

pub fn (s Shader) set_vec3(uniform ShaderUniform, x f32, y f32, z f32) {
	gl.uniform3f(uniform.location, x, y, z)
}

pub fn (s Shader) set_vec3v(uniform ShaderUniform, vec math.Vec3) {
	gl.uniform3f(uniform.location, vec.x, vec.y, vec.z)
}

pub fn (s Shader) set_vec3c(uniform ShaderUniform, vec Color) {
	gl.uniform3f(uniform.location, vec.x, vec.y, vec.z)
}

pub fn (s Shader) set_vec4(uniform ShaderUniform, x f32, y f32, z f32, w f32) {
	gl.uniform4f(uniform.location, x, y, z, w)
}

pub fn (s Shader) set_vec4v(uniform ShaderUniform, vec math.Vec4) {
	gl.uniform4f(uniform.location, vec.x, vec.y, vec.z, vec.w)
}

pub fn (s Shader) set_vec4c(uniform ShaderUniform, vec Color) {
	gl.uniform4f(uniform.location, vec.x, vec.y, vec.z, vec.w)
}

pub fn (s Shader) set_mat3(uniform ShaderUniform, mat &math.Mat33) {
	gl.uniformmatrix3fv(uniform.location, 1, int(gl.Flag.gl_false), unsafe { &mat.data[0] })
}

pub fn (s Shader) set_mat4(uniform ShaderUniform, mat &math.Mat44) {
	gl.uniformmatrix4fv(uniform.location, 1, int(gl.Flag.gl_false), unsafe { &mat.data[0] })
}
