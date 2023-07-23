module util

import mv.thirdparty.gles2 as gl
// import log

[direct_array_access]
pub fn load_shader(src string, shader_type gl.Flag) gl.GLuint {
	// println('loading shader: \n' + src)
	mut shader := gl.GLuint(0)
	mut compiled := 0

	shader = gl.create_shader(shader_type)
	if shader == 0 {
		return shader
	}

	gl.shader_source(shader, 1, &src.str, src.len)
	gl.compile_shader(shader)
	gl.get_shaderiv(shader, .compile_status, &compiled)

	if compiled == 0 {
		mut info_len := 0
		gl.get_shaderiv(shader, .info_log_length, &info_len)
		print('shader compilation error \n')

		if info_len > 1 {
			mut info_log := []&u8{cap:500}

			gl.get_shader_info_log(shader, -1, &info_len, info_log.data)
			println('log: ${info_log}')
		}
		gl.delete_shader(shader)
		return u32(0)
	}

	// println('seems to be fine, shader id: ' + shader.str() + '\n')
	return shader
}

pub fn link_shader_program(vertex gl.GLuint, fragment gl.GLuint) gl.GLuint {
	mut program := gl.GLuint(0)
	mut success := 0

	program = gl.create_program()
	gl.attach_shader(program, vertex)
	gl.attach_shader(program, fragment)
	gl.link_program(program)

	gl.get_programiv(program, .link_status, &success)
	if success != 1 {
		mut info_log := []&u8{cap:32}
		mut log_len := 0

		gl.get_programiv(program, .info_log_length, &log_len)
		if log_len >= 1 {
			gl.get_program_info_log(program, log_len, &log_len, info_log.data)
		}
		println('couldn\'t link program! \n ${info_log.str()}')

		gl.detach_shader(program, vertex)
		gl.detach_shader(program, fragment)
		gl.delete_program(program)
		return u32(0)
	}

	return program
}
