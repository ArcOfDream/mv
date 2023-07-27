module gles2

// GLES2 bindings, initially generated with v translate, and manually tweaked.

// $if !windows {
// 	$if $pkgconfig('glesv2') {
// 		#pkgconfig glesv2
// 	}
// }
#flag "-I@VMODROOT/include"
#flag linux "-lGLESv2"
#flag windows "-lopengl32"
#include <GLES2/gl2.h>

type GLbyte = i8
type GLclampf = f32
type GLfixed = int
type GLshort = i16
type GLushort = u16

// type GLvoid = ?
type GLint64 = i64
type GLuint64 = u64
type GLenum = u32
type GLuint = u32
type GLchar = char
type GLfloat = f32
type GLsizeiptr = int
type GLintptr = i64
type GLbitfield = u32
type GLint = int
type GLboolean = u8
type GLsizei = int
type GLubyte = u8

pub enum Flag as u32 {
	// GL_OES_vertex_array_object
	// vertex_array_binding = C.GL_VERTEX_ARRAY_BINDING_OES
	// core
	depth_buffer_bit = C.GL_DEPTH_BUFFER_BIT
	stencil_buffer_bit = C.GL_STENCIL_BUFFER_BIT
	color_buffer_bit = C.GL_COLOR_BUFFER_BIT
	gl_false = C.GL_FALSE
	gl_true = C.GL_TRUE
	points = C.GL_POINTS
	lines = C.GL_LINES
	line_loop = C.GL_LINE_LOOP // 	gl_line_loop =
	line_strip = C.GL_LINE_STRIP // 	gl_line_strip =
	triangles = C.GL_TRIANGLES // 	gl_triangles =
	triangle_strip = C.GL_TRIANGLE_STRIP // 	gl_triangle_strip =
	triangle_fan = C.GL_TRIANGLE_FAN // 	gl_triangle_fan =
	zero = C.GL_ZERO // 	gl_zero = 0
	one = C.GL_ONE // 	gl_one = 1
	src_color = C.GL_SRC_COLOR // 	gl_src_color =
	one_minus_src_color = C.GL_ONE_MINUS_SRC_COLOR
	src_alpha = C.GL_SRC_ALPHA
	one_minus_src_alpha = C.GL_ONE_MINUS_SRC_ALPHA
	dst_alpha = C.GL_DST_ALPHA
	one_minus_dst_alpha = C.GL_ONE_MINUS_DST_ALPHA
	dst_color = C.GL_DST_COLOR
	one_minus_dst_color = C.GL_ONE_MINUS_DST_COLOR
	src_alpha_saturate = C.GL_SRC_ALPHA_SATURATE
	func_add = C.GL_FUNC_ADD
	blend_equation = C.GL_BLEND_EQUATION
	blend_equation_rgb = C.GL_BLEND_EQUATION_RGB
	blend_equation_alpha = C.GL_BLEND_EQUATION_ALPHA
	func_subtract = C.GL_FUNC_SUBTRACT
	func_reverse_subtract = C.GL_FUNC_REVERSE_SUBTRACT
	blend_dst_rgb = C.GL_BLEND_DST_RGB
	blend_src_rgb = C.GL_BLEND_SRC_RGB
	blend_dst_alpha = C.GL_BLEND_DST_ALPHA
	blend_src_alpha = C.GL_BLEND_SRC_ALPHA
	constant_color = C.GL_CONSTANT_COLOR
	one_minus_constant_color = C.GL_ONE_MINUS_CONSTANT_COLOR
	constant_alpha = C.GL_CONSTANT_ALPHA
	one_minus_constant_alpha = C.GL_ONE_MINUS_CONSTANT_ALPHA
	blend_color = C.GL_BLEND_COLOR
	array_buffer = C.GL_ARRAY_BUFFER
	element_array_buffer = C.GL_ELEMENT_ARRAY_BUFFER
	array_buffer_binding = C.GL_ARRAY_BUFFER_BINDING
	element_array_buffer_binding = C.GL_ELEMENT_ARRAY_BUFFER_BINDING
	stream_draw = C.GL_STREAM_DRAW
	static_draw = C.GL_STATIC_DRAW
	dynamic_draw = C.GL_DYNAMIC_DRAW
	buffer_size = C.GL_BUFFER_SIZE
	buffer_usage = C.GL_BUFFER_USAGE
	current_vertex_attrib = C.GL_CURRENT_VERTEX_ATTRIB
	front = C.GL_FRONT
	back = C.GL_BACK
	front_and_back = C.GL_FRONT_AND_BACK
	texture_2d = C.GL_TEXTURE_2D
	cull_face = C.GL_CULL_FACE
	blend = C.GL_BLEND
	dither = C.GL_DITHER
	stencil_test = C.GL_STENCIL_TEST
	depth_test = C.GL_DEPTH_TEST
	scissor_test = C.GL_SCISSOR_TEST
	polygon_offset_fill = C.GL_POLYGON_OFFSET_FILL
	sample_alpha_to_coverage = C.GL_SAMPLE_ALPHA_TO_COVERAGE
	sample_coverage = C.GL_SAMPLE_COVERAGE
	no_error = C.GL_NO_ERROR
	invalid_enum = C.GL_INVALID_ENUM
	invalid_value = C.GL_INVALID_VALUE
	invalid_operation = C.GL_INVALID_OPERATION
	out_of_memory = C.GL_OUT_OF_MEMORY
	cw = C.GL_CW
	ccw = C.GL_CCW
	line_width = C.GL_LINE_WIDTH
	aliased_point_size_range = C.GL_ALIASED_POINT_SIZE_RANGE
	aliased_line_width_range = C.GL_ALIASED_LINE_WIDTH_RANGE
	cull_face_mode = C.GL_CULL_FACE_MODE
	front_face = C.GL_FRONT_FACE
	depth_range = C.GL_DEPTH_RANGE
	depth_writemask = C.GL_DEPTH_WRITEMASK
	depth_clear_value = C.GL_DEPTH_CLEAR_VALUE
	depth_func = C.GL_DEPTH_FUNC
	stencil_clear_value = C.GL_STENCIL_CLEAR_VALUE
	stencil_func = C.GL_STENCIL_FUNC
	stencil_fail = C.GL_STENCIL_FAIL
	stencil_pass_depth_fail = C.GL_STENCIL_PASS_DEPTH_FAIL
	stencil_pass_depth_pass = C.GL_STENCIL_PASS_DEPTH_PASS
	stencil_ref = C.GL_STENCIL_REF
	stencil_value_mask = C.GL_STENCIL_VALUE_MASK
	stencil_writemask = C.GL_STENCIL_WRITEMASK
	stencil_back_func = C.GL_STENCIL_BACK_FUNC
	stencil_back_fail = C.GL_STENCIL_BACK_FAIL
	stencil_back_pass_depth_fail = C.GL_STENCIL_BACK_PASS_DEPTH_FAIL
	stencil_back_pass_depth_pass = C.GL_STENCIL_BACK_PASS_DEPTH_PASS
	stencil_back_ref = C.GL_STENCIL_BACK_REF
	stencil_back_value_mask = C.GL_STENCIL_BACK_VALUE_MASK
	stencil_back_writemask = C.GL_STENCIL_BACK_WRITEMASK
	viewport = C.GL_VIEWPORT
	scissor_box = C.GL_SCISSOR_BOX
	color_clear_value = C.GL_COLOR_CLEAR_VALUE
	color_writemask = C.GL_COLOR_WRITEMASK
	unpack_alignment = C.GL_UNPACK_ALIGNMENT
	pack_alignment = C.GL_PACK_ALIGNMENT
	max_texture_size = C.GL_MAX_TEXTURE_SIZE
	max_viewport_dims = C.GL_MAX_VIEWPORT_DIMS
	subpixel_bits = C.GL_SUBPIXEL_BITS
	red_bits = C.GL_RED_BITS
	green_bits = C.GL_GREEN_BITS
	blue_bits = C.GL_BLUE_BITS
	alpha_bits = C.GL_ALPHA_BITS
	depth_bits = C.GL_DEPTH_BITS
	stencil_bits = C.GL_STENCIL_BITS
	polygon_offset_units = C.GL_POLYGON_OFFSET_UNITS
	polygon_offset_factor = C.GL_POLYGON_OFFSET_FACTOR
	texture_binding_2d = C.GL_TEXTURE_BINDING_2D
	sample_buffers = C.GL_SAMPLE_BUFFERS
	samples = C.GL_SAMPLES
	sample_coverage_value = C.GL_SAMPLE_COVERAGE_VALUE
	sample_coverage_invert = C.GL_SAMPLE_COVERAGE_INVERT
	num_compressed_texture_formats = C.GL_NUM_COMPRESSED_TEXTURE_FORMATS
	compressed_texture_formats = C.GL_COMPRESSED_TEXTURE_FORMATS
	dont_care = C.GL_DONT_CARE
	fastest = C.GL_FASTEST
	nicest = C.GL_NICEST
	generate_mipmap_hint = C.GL_GENERATE_MIPMAP_HINT
	gl_byte = C.GL_BYTE
	gl_unsigned_byte = C.GL_UNSIGNED_BYTE
	gl_short = C.GL_SHORT
	gl_unsigned_short = C.GL_UNSIGNED_SHORT
	gl_int = C.GL_INT
	gl_unsigned_int = C.GL_UNSIGNED_INT
	gl_float = C.GL_FLOAT
	fixed = C.GL_FIXED
	depth_component = C.GL_DEPTH_COMPONENT
	alpha = C.GL_ALPHA
	rgb = C.GL_RGB
	rgba = C.GL_RGBA
	luminance = C.GL_LUMINANCE
	luminance_alpha = C.GL_LUMINANCE_ALPHA
	ushort_4_4_4_4 = C.GL_UNSIGNED_SHORT_4_4_4_4
	ushort_5_5_5_1 = C.GL_UNSIGNED_SHORT_5_5_5_1
	ushort_5_6_5 = C.GL_UNSIGNED_SHORT_5_6_5
	fragment_shader = C.GL_FRAGMENT_SHADER
	vertex_shader = C.GL_VERTEX_SHADER
	max_vertex_attribs = C.GL_MAX_VERTEX_ATTRIBS
	max_vertex_uniform_vectors = C.GL_MAX_VERTEX_UNIFORM_VECTORS
	max_varying_vectors = C.GL_MAX_VARYING_VECTORS
	max_vombined_texture_image_units = C.GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS
	max_vertex_texture_image_units = C.GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS
	max_texture_image_units = C.GL_MAX_TEXTURE_IMAGE_UNITS
	max_fragment_uniform_vectors = C.GL_MAX_FRAGMENT_UNIFORM_VECTORS
	shader_type = C.GL_SHADER_TYPE
	delete_status = C.GL_DELETE_STATUS
	link_status = C.GL_LINK_STATUS
	validate_status = C.GL_VALIDATE_STATUS
	attached_shaders = C.GL_ATTACHED_SHADERS
	active_uniforms = C.GL_ACTIVE_UNIFORMS
	active_uniform_max_length = C.GL_ACTIVE_UNIFORM_MAX_LENGTH
	active_attributes = C.GL_ACTIVE_ATTRIBUTES
	actuve_attribute_max_length = C.GL_ACTIVE_ATTRIBUTE_MAX_LENGTH
	shading_language_version = C.GL_SHADING_LANGUAGE_VERSION
	current_program = C.GL_CURRENT_PROGRAM
	never = C.GL_NEVER
	less = C.GL_LESS
	equal = C.GL_EQUAL
	lequal = C.GL_LEQUAL
	greater = C.GL_GREATER
	not_equal = C.GL_NOTEQUAL
	gequal = C.GL_GEQUAL
	always = C.GL_ALWAYS
	keep = C.GL_KEEP
	replace = C.GL_REPLACE
	incr = C.GL_INCR
	decr = C.GL_DECR
	invert = C.GL_INVERT
	incr_swap = C.GL_INCR_WRAP
	decr_swap = C.GL_DECR_WRAP
	vendor = C.GL_VENDOR
	renderer = C.GL_RENDERER
	version = C.GL_VERSION
	extensions = C.GL_EXTENSIONS
	nearest = C.GL_NEAREST
	linear = C.GL_LINEAR
	nearest_mipmap_nearest = C.GL_NEAREST_MIPMAP_NEAREST
	linear_mipmap_nearest = C.GL_LINEAR_MIPMAP_NEAREST
	nearest_mipmap_linear = C.GL_NEAREST_MIPMAP_LINEAR
	linear_mipmap_linear = C.GL_LINEAR_MIPMAP_LINEAR
	texture_mag_filter = C.GL_TEXTURE_MAG_FILTER
	texture_min_filter = C.GL_TEXTURE_MIN_FILTER
	texture_wrap_s = C.GL_TEXTURE_WRAP_S
	texture_wrap_t = C.GL_TEXTURE_WRAP_T
	texture = C.GL_TEXTURE
	texture_cube_map = C.GL_TEXTURE_CUBE_MAP
	texture_binding_cube_map = C.GL_TEXTURE_BINDING_CUBE_MAP
	texture_cubemap_positive_x = C.GL_TEXTURE_CUBE_MAP_POSITIVE_X
	texture_cubemap_negative_x = C.GL_TEXTURE_CUBE_MAP_NEGATIVE_X
	texture_cubemap_positive_y = C.GL_TEXTURE_CUBE_MAP_POSITIVE_Y
	texture_cubemap_negative_y = C.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
	texture_cubemap_positive_z = C.GL_TEXTURE_CUBE_MAP_POSITIVE_Z
	texture_cubemap_negative_z = C.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
	max_cubemap_texture_size = C.GL_MAX_CUBE_MAP_TEXTURE_SIZE
	texture0 = C.GL_TEXTURE0
	texture1 = C.GL_TEXTURE1
	texture2 = C.GL_TEXTURE2
	texture3 = C.GL_TEXTURE3
	texture4 = C.GL_TEXTURE4
	texture5 = C.GL_TEXTURE5
	texture6 = C.GL_TEXTURE6
	texture7 = C.GL_TEXTURE7
	texture8 = C.GL_TEXTURE8
	texture9 = C.GL_TEXTURE9
	texture10 = C.GL_TEXTURE10
	texture11 = C.GL_TEXTURE11
	texture12 = C.GL_TEXTURE12
	texture13 = C.GL_TEXTURE13
	texture14 = C.GL_TEXTURE14
	texture15 = C.GL_TEXTURE15
	texture16 = C.GL_TEXTURE16
	texture17 = C.GL_TEXTURE17
	texture18 = C.GL_TEXTURE18
	texture19 = C.GL_TEXTURE19
	texture20 = C.GL_TEXTURE20
	texture21 = C.GL_TEXTURE21
	texture22 = C.GL_TEXTURE22
	texture23 = C.GL_TEXTURE23
	texture24 = C.GL_TEXTURE24
	texture25 = C.GL_TEXTURE25
	texture26 = C.GL_TEXTURE26
	texture27 = C.GL_TEXTURE27
	texture28 = C.GL_TEXTURE28
	texture29 = C.GL_TEXTURE29
	texture30 = C.GL_TEXTURE30
	texture31 = C.GL_TEXTURE31
	active_texture = C.GL_ACTIVE_TEXTURE
	repeat = C.GL_REPEAT
	clamp_to_edge = C.GL_CLAMP_TO_EDGE
	mirrored_repeat = C.GL_MIRRORED_REPEAT
	float_vec2 = C.GL_FLOAT_VEC2
	float_vec3 = C.GL_FLOAT_VEC3
	float_vec4 = C.GL_FLOAT_VEC4
	int_vec2 = C.GL_INT_VEC2
	int_vec3 = C.GL_INT_VEC3
	int_vec4 = C.GL_INT_VEC4
	gl_bool = C.GL_BOOL
	bool_vec2 = C.GL_BOOL_VEC2
	bool_vec3 = C.GL_BOOL_VEC3
	bool_vec4 = C.GL_BOOL_VEC4
	float_mat2 = C.GL_FLOAT_MAT2
	float_mat3 = C.GL_FLOAT_MAT3
	float_mat4 = C.GL_FLOAT_MAT4
	sampler2d = C.GL_SAMPLER_2D
	sampler_cube = C.GL_SAMPLER_CUBE
	vertex_attrib_array_enabled = C.GL_VERTEX_ATTRIB_ARRAY_ENABLED
	vertex_attrib_array_size = C.GL_VERTEX_ATTRIB_ARRAY_SIZE
	vertex_attrib_array_stride = C.GL_VERTEX_ATTRIB_ARRAY_STRIDE
	vertex_attrib_array_type = C.GL_VERTEX_ATTRIB_ARRAY_TYPE
	vertex_attrib_array_normalized = C.GL_VERTEX_ATTRIB_ARRAY_NORMALIZED
	vertex_attrib_array_pointer = C.GL_VERTEX_ATTRIB_ARRAY_POINTER
	vertex_attrib_array_buffer_binding = C.GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING
	impl_color_read_type = C.GL_IMPLEMENTATION_COLOR_READ_TYPE
	impl_color_read_format = C.GL_IMPLEMENTATION_COLOR_READ_FORMAT
	compile_status = C.GL_COMPILE_STATUS
	info_log_length = C.GL_INFO_LOG_LENGTH
	shader_source_length = C.GL_SHADER_SOURCE_LENGTH
	shader_compiler = C.GL_SHADER_COMPILER
	shader_binary_formats = C.GL_SHADER_BINARY_FORMATS
	num_shader_binary_formats = C.GL_NUM_SHADER_BINARY_FORMATS
	low_float = C.GL_LOW_FLOAT
	medium_float = C.GL_MEDIUM_FLOAT
	high_float = C.GL_HIGH_FLOAT
	low_int = C.GL_LOW_INT
	medium_int = C.GL_MEDIUM_INT
	high_int = C.GL_HIGH_INT
	framebuffer = C.GL_FRAMEBUFFER
	renderbuffer = C.GL_RENDERBUFFER
	rgba4 = C.GL_RGBA4
	rgb5_a1 = C.GL_RGB5_A1
	rgb565 = C.GL_RGB565
	depth_component_16 = C.GL_DEPTH_COMPONENT16
	stencil_index_8 = C.GL_STENCIL_INDEX8
	renderbuffer_width = C.GL_RENDERBUFFER_WIDTH
	renderbuffer_height = C.GL_RENDERBUFFER_HEIGHT
	renderbuffer_internal_format = C.GL_RENDERBUFFER_INTERNAL_FORMAT
	renderbuffer_red_size = C.GL_RENDERBUFFER_RED_SIZE
	renderbuffer_green_size = C.GL_RENDERBUFFER_GREEN_SIZE
	renderbuffer_blue_size = C.GL_RENDERBUFFER_BLUE_SIZE
	renderbuffer_alpha_size = C.GL_RENDERBUFFER_ALPHA_SIZE
	renderbuffer_depth_size = C.GL_RENDERBUFFER_DEPTH_SIZE
	renderbuffer_stencil_size = C.GL_RENDERBUFFER_STENCIL_SIZE
	framebuffer_attachment_object_type = C.GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE
	framebuffer_attachment_object_name = C.GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME
	framebuffer_attachment_texture_level = C.GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL
	framebuffer_attachment_texture_cubemap_face = C.GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE
	color_attachment0 = C.GL_COLOR_ATTACHMENT0
	depth_attachment = C.GL_DEPTH_ATTACHMENT
	stencil_attachment = C.GL_STENCIL_ATTACHMENT
	gl_none = C.GL_NONE
	framebuffer_complete = C.GL_FRAMEBUFFER_COMPLETE
	framebuffer_incomplete_attachment = C.GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT
	framebuffer_incomplete_missing_attachment = C.GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT
	incomplete_dimensions = C.GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS
	framebuffer_unsupported = C.GL_FRAMEBUFFER_UNSUPPORTED
	framebuffer_binding = C.GL_FRAMEBUFFER_BINDING
	renderbuffer_binding = C.GL_RENDERBUFFER_BINDING
	max_renderbufer_size = C.GL_MAX_RENDERBUFFER_SIZE
	invalid_framebuffer_operation = C.GL_INVALID_FRAMEBUFFER_OPERATION
}

fn C.glActiveTexture(texture Flag)

pub fn active_texture(texture Flag) {
	C.glActiveTexture(texture)
}

fn C.glAttachShader(program GLuint, shader GLuint)

pub fn attach_shader(program GLuint, shader GLuint) {
	C.glAttachShader(program, shader)
}

fn C.glBindAttribLocation(program GLuint, index GLuint, name &GLchar)

pub fn bind_attrib_location(program GLuint, index GLuint, name &GLchar) {
	C.glBindAttribLocation(program, index, name)
}

fn C.glBindBuffer(target Flag, buffer GLuint)

pub fn bind_buffer(target Flag, buffer GLuint) {
	C.glBindBuffer(target, buffer)
}

fn C.glBindFramebuffer(target Flag, framebuffer GLuint)

pub fn bind_framebuffer(target Flag, framebuffer GLuint) {
	C.glBindFramebuffer(target, framebuffer)
}

fn C.glBindRenderbuffer(target Flag, renderbuffer GLuint)

pub fn bind_renderbuffer(target Flag, renderbuffer GLuint) {
	C.glBindRenderbuffer(target, renderbuffer)
}

fn C.glBindTexture(target Flag, texture GLuint)

pub fn bind_texture(target Flag, texture GLuint) {
	C.glBindTexture(target, texture)
}

fn C.glBlendColor(red GLfloat, green GLfloat, blue GLfloat, alpha GLfloat)

pub fn blend_color(red GLfloat, green GLfloat, blue GLfloat, alpha GLfloat) {
	C.glBlendColor(red, green, blue, alpha)
}

fn C.glBlendEquation(mode Flag)

pub fn blend_equation(mode Flag) {
	C.glBlendEquation(mode)
}

fn C.glBlendEquationSeparate(modergb Flag, modealpha Flag)

pub fn blend_equation_separate(modergb Flag, modealpha Flag) {
	C.glBlendEquationSeparate(modergb, modealpha)
}

fn C.glBlendFunc(sfactor Flag, dfactor Flag)

pub fn blend_func(sfactor Flag, dfactor Flag) {
	C.glBlendFunc(sfactor, dfactor)
}

fn C.glBlendFuncSeparate(sfactorrgb Flag, dfactorrgb Flag, sfactoralpha Flag, dfactoralpha Flag)

pub fn blend_func_separate(sfactorrgb Flag, dfactorrgb Flag, sfactoralpha Flag, dfactoralpha Flag) {
	C.glBlendFuncSeparate(sfactorrgb, dfactorrgb, sfactoralpha, dfactoralpha)
}

fn C.glBufferData(target Flag, size GLsizeiptr, data voidptr, usage Flag)

pub fn buffer_data(target Flag, size GLsizeiptr, data voidptr, usage Flag) {
	C.glBufferData(target, size, data, usage)
}

fn C.glBufferSubData(target Flag, offset GLintptr, size GLsizeiptr, data voidptr)

pub fn buffer_subdata(target Flag, offset GLintptr, size GLsizeiptr, data voidptr) {
	C.glBufferSubData(target, offset, size, data)
}

fn C.glCheckFramebufferStatus(target Flag) Flag

pub fn check_framebuffer_status(target Flag) Flag {
	return C.glCheckFramebufferStatus(target)
}

fn C.glClear(mask GLbitfield)

pub fn clear(mask GLbitfield) {
	C.glClear(mask)
}

fn C.glClearColor(red GLfloat, green GLfloat, blue GLfloat, alpha GLfloat)

pub fn clear_color(red GLfloat, green GLfloat, blue GLfloat, alpha GLfloat) {
	C.glClearColor(red, green, blue, alpha)
}

fn C.glClearDepthf(d GLfloat)

pub fn clear_depthf(d GLfloat) {
	C.glClearDepthf(d)
}

fn C.glClearStencil(s GLint)

pub fn clear_stencil(s GLint) {
	C.glClearStencil(s)
}

fn C.glColorMask(red GLboolean, green GLboolean, blue GLboolean, alpha GLboolean)

pub fn color_mask(red GLboolean, green GLboolean, blue GLboolean, alpha GLboolean) {
	C.glColorMask(red, green, blue, alpha)
}

fn C.glCompileShader(shader GLuint)

pub fn compile_shader(shader GLuint) {
	C.glCompileShader(shader)
}

fn C.glCompressedTexImage2D(target Flag, level GLint, internalformat Flag, width GLsizei, height GLsizei, border GLint, imagesize GLsizei, data voidptr)

pub fn compressed_teximage2d(target Flag, level GLint, internalformat Flag, width GLsizei, height GLsizei, border GLint, imagesize GLsizei, data voidptr) {
	C.glCompressedTexImage2D(target, level, internalformat, width, height, border, imagesize,
		data)
}

fn C.glCompressedTexSubImage2D(target Flag, level GLint, xoffset GLint, yoffset GLint, width GLsizei, height GLsizei, format Flag, imagesize GLsizei, data voidptr)

pub fn compressed_texsubimage2d(target Flag, level GLint, xoffset GLint, yoffset GLint, width GLsizei, height GLsizei, format Flag, imagesize GLsizei, data voidptr) {
	C.glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format,
		imagesize, data)
}

fn C.glCopyTexImage2D(target Flag, level GLint, internalformat Flag, x GLint, y GLint, width GLsizei, height GLsizei, border GLint)

pub fn copy_teximage2d(target Flag, level GLint, internalformat Flag, x GLint, y GLint, width GLsizei, height GLsizei, border GLint) {
	C.glCopyTexImage2D(target, level, internalformat, x, y, width, height, border)
}

fn C.glCopyTexSubImage2D(target Flag, level GLint, xoffset GLint, yoffset GLint, x GLint, y GLint, width GLsizei, height GLsizei)

pub fn copy_texsubimage2d(target Flag, level GLint, xoffset GLint, yoffset GLint, x GLint, y GLint, width GLsizei, height GLsizei) {
	C.glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height)
}

fn C.glCreateProgram() GLuint

pub fn create_program() GLuint {
	return C.glCreateProgram()
}

fn C.glCreateShader(type_ Flag) GLuint

pub fn create_shader(type_ Flag) GLuint {
	return C.glCreateShader(type_)
}

fn C.glCullFace(mode Flag)

pub fn cull_face(mode Flag) {
	C.glCullFace(mode)
}

fn C.glDeleteBuffers(n GLsizei, buffers &GLuint)

pub fn delete_buffers(n GLsizei, buffers &GLuint) {
	C.glDeleteBuffers(n, buffers)
}

fn C.glDeleteFramebuffers(n GLsizei, framebuffers &GLuint)

pub fn delete_framebuffers(n GLsizei, framebuffers &GLuint) {
	C.glDeleteFramebuffers(n, framebuffers)
}

fn C.glDeleteProgram(program GLuint)

pub fn delete_program(program GLuint) {
	C.glDeleteProgram(program)
}

fn C.glDeleteRenderbuffers(n GLsizei, renderbuffers &GLuint)

pub fn delete_render_buffers(n GLsizei, renderbuffers &GLuint) {
	C.glDeleteRenderbuffers(n, renderbuffers)
}

fn C.glDeleteShader(shader GLuint)

pub fn delete_shader(shader GLuint) {
	C.glDeleteShader(shader)
}

fn C.glDeleteTextures(n GLsizei, textures &GLuint)

pub fn delete_textures(n GLsizei, textures &GLuint) {
	C.glDeleteTextures(n, textures)
}

fn C.glDepthFunc(func Flag)

pub fn depth_func(func Flag) {
	C.glDepthFunc(func)
}

fn C.glDepthMask(flag GLboolean)

pub fn depth_mask(flag GLboolean) {
	C.glDepthMask(flag)
}

fn C.glDepthRangef(n GLfloat, f GLfloat)

pub fn depth_rangef(n GLfloat, f GLfloat) {
	C.glDepthRangef(n, f)
}

fn C.glDetachShader(program GLuint, shader GLuint)

pub fn detach_shader(program GLuint, shader GLuint) {
	C.glDetachShader(program, shader)
}

fn C.glDisable(cap Flag)

pub fn disable(cap Flag) {
	C.glDisable(cap)
}

fn C.glDisableVertexAttribArray(index GLuint)

pub fn disable_vertex_attrib_array(index GLuint) {
	C.glDisableVertexAttribArray(index)
}

fn C.glDrawArrays(mode Flag, first GLint, count GLsizei)

pub fn draw_arrays(mode Flag, first GLint, count GLsizei) {
	C.glDrawArrays(mode, first, count)
}

fn C.glDrawElements(mode Flag, count GLsizei, type_ Flag, indices voidptr)

pub fn draw_elements(mode Flag, count GLsizei, type_ Flag, indices voidptr) {
	C.glDrawElements(mode, count, type_, indices)
}

fn C.glEnable(cap Flag)

pub fn enable(cap Flag) {
	C.glEnable(cap)
}

fn C.glEnableVertexAttribArray(index GLuint)

pub fn enable_vertex_attrib_array(index GLuint) {
	C.glEnableVertexAttribArray(index)
}

fn C.glFinish()

pub fn finish() {
	C.glFinish()
}

fn C.glFlush()

pub fn flush() {
	C.glFlush()
}

fn C.glFramebufferRenderbuffer(target Flag, attachment Flag, renderbuffertarget Flag, renderbuffer GLuint)

pub fn framebuffer_renderbuffer(target Flag, attachment Flag, renderbuffertarget Flag, renderbuffer GLuint) {
	C.glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer)
}

fn C.glFramebufferTexture2D(target Flag, attachment Flag, textarget Flag, texture GLuint, level GLint)

pub fn framebuffer_texture2d(target Flag, attachment Flag, textarget Flag, texture GLuint, level GLint) {
	C.glFramebufferTexture2D(target, attachment, textarget, texture, level)
}

fn C.glFrontFace(mode Flag)

pub fn front_face(mode Flag) {
	C.glFrontFace(mode)
}

fn C.glGenBuffers(n GLsizei, buffers &GLuint)

pub fn gen_buffers(n GLsizei, buffers &GLuint) {
	C.glGenBuffers(n, buffers)
}

fn C.glGenerateMipmap(target Flag)

pub fn generate_mipmap(target Flag) {
	C.glGenerateMipmap(target)
}

fn C.glGenFramebuffers(n GLsizei, framebuffers &GLuint)

pub fn gen_framebuffers(n GLsizei, framebuffers &GLuint) {
	C.glGenFramebuffers(n, framebuffers)
}

fn C.glGenRenderbuffers(n GLsizei, renderbuffers &GLuint)

pub fn gen_renderbuffers(n GLsizei, renderbuffers &GLuint) {
	C.glGenRenderbuffers(n, renderbuffers)
}

fn C.glGenTextures(n GLsizei, textures &GLuint)

pub fn gen_textures(n GLsizei, textures &GLuint) {
	C.glGenTextures(n, textures)
}

fn C.glGetActiveAttrib(program GLuint, index GLuint, bufsize GLsizei, length &GLsizei, size &GLint, type_ &Flag, name &GLchar)

pub fn get_active_attrib(program GLuint, index GLuint, bufsize GLsizei, length &GLsizei, size &GLint, type_ &Flag, name &GLchar) {
	C.glGetActiveAttrib(program, index, bufsize, length, size, type_, name)
}

fn C.glGetActiveUniform(program GLuint, index GLuint, bufsize GLsizei, length &GLsizei, size &GLint, type_ &Flag, name &GLchar)

pub fn get_active_uniform(program GLuint, index GLuint, bufsize GLsizei, length &GLsizei, size &GLint, type_ &Flag, name &GLchar) {
	C.glGetActiveUniform(program, index, bufsize, length, size, type_, name)
}

fn C.glGetAttachedShaders(program GLuint, maxcount GLsizei, count &GLsizei, shaders &GLuint)

pub fn get_attached_shaders(program GLuint, maxcount GLsizei, count &GLsizei, shaders &GLuint) {
	C.glGetAttachedShaders(program, maxcount, count, shaders)
}

fn C.glGetAttribLocation(program GLuint, name &GLchar) GLint

pub fn get_attrib_location(program GLuint, name &GLchar) GLint {
	return C.glGetAttribLocation(program, name)
}

fn C.glGetBooleanv(pname Flag, data &GLboolean)

pub fn get_booleanv(pname Flag, data &GLboolean) {
	C.glGetBooleanv(pname, data)
}

fn C.glGetBufferParameteriv(target Flag, pname Flag, params &GLint)

pub fn get_buffer_parameteriv(target Flag, pname Flag, params &GLint) {
	C.glGetBufferParameteriv(target, pname, params)
}

fn C.glGetError() Flag

pub fn get_error() Flag {
	return C.glGetError()
}

fn C.glGetFloatv(pname Flag, data &GLfloat)

pub fn get_floatv(pname Flag, data &GLfloat) {
	C.glGetFloatv(pname, data)
}

fn C.glGetFramebufferAttachmentParameteriv(target Flag, attachment Flag, pname Flag, params &GLint)

pub fn get_framebuffer_attachment_parameteriv(target Flag, attachment Flag, pname Flag, params &GLint) {
	C.glGetFramebufferAttachmentParameteriv(target, attachment, pname, params)
}

fn C.glGetIntegerv(pname Flag, data &GLint)

pub fn get_integerv(pname Flag, data &GLint) {
	C.glGetIntegerv(pname, data)
}

fn C.glGetProgramiv(program GLuint, pname Flag, params &GLint)

pub fn get_programiv(program GLuint, pname Flag, params &GLint) {
	C.glGetProgramiv(program, pname, params)
}

fn C.glGetProgramInfoLog(program GLuint, bufsize GLsizei, length &GLsizei, infolog &GLchar)

pub fn get_program_info_log(program GLuint, bufsize GLsizei, length &GLsizei, infolog &GLchar) {
	C.glGetProgramInfoLog(program, bufsize, length, infolog)
}

fn C.glGetRenderbufferParameteriv(target Flag, pname Flag, params &GLint)

pub fn get_renderbuffer_parameteriv(target Flag, pname Flag, params &GLint) {
	C.glGetRenderbufferParameteriv(target, pname, params)
}

fn C.glGetShaderiv(shader GLuint, pname Flag, params &GLint)

pub fn get_shaderiv(shader GLuint, pname Flag, params &GLint) {
	C.glGetShaderiv(shader, pname, params)
}

fn C.glGetShaderInfoLog(shader GLuint, bufsize GLsizei, length &GLsizei, infolog &GLchar)

pub fn get_shader_info_log(shader GLuint, bufsize GLsizei, length &GLsizei, infolog &char) {
	C.glGetShaderInfoLog(shader, bufsize, length, infolog)
}

fn C.glGetShaderPrecisionFormat(shadertype Flag, precisiontype Flag, range &GLint, precision &GLint)

pub fn get_shader_precision_format(shadertype Flag, precisiontype Flag, range &GLint, precision &GLint) {
	C.glGetShaderPrecisionFormat(shadertype, precisiontype, range, precision)
}

fn C.glGetShaderSource(shader GLuint, bufsize GLsizei, length &GLsizei, source &GLchar)

pub fn get_shader_source(shader GLuint, bufsize GLsizei, length &GLsizei, source &GLchar) {
	C.glGetShaderSource(shader, bufsize, length, source)
}

fn C.glGetString(name Flag) &GLubyte

pub fn get_string(name Flag) &GLubyte {
	return C.glGetString(name)
}

fn C.glGetTexParameterfv(target Flag, pname Flag, params &GLfloat)

pub fn get_tex_parameterfv(target Flag, pname Flag, params &GLfloat) {
	C.glGetTexParameterfv(target, pname, params)
}

fn C.glGetTexParameteriv(target Flag, pname Flag, params &GLint)

pub fn get_tex_parameteriv(target Flag, pname Flag, params &GLint) {
	C.glGetTexParameteriv(target, pname, params)
}

fn C.glGetUniformfv(program GLuint, location GLint, params &GLfloat)

pub fn get_uniformfv(program GLuint, location GLint, params &GLfloat) {
	C.glGetUniformfv(program, location, params)
}

fn C.glGetUniformiv(program GLuint, location GLint, params &GLint)

pub fn get_uniformiv(program GLuint, location GLint, params &GLint) {
	C.glGetUniformiv(program, location, params)
}

fn C.glGetUniformLocation(program GLuint, name &GLchar) GLint

pub fn get_uniform_location(program GLuint, name &GLchar) GLint {
	return C.glGetUniformLocation(program, name)
}

fn C.glGetVertexAttribfv(index GLuint, pname Flag, params &GLfloat)

pub fn get_vertex_attribfv(index GLuint, pname Flag, params &GLfloat) {
	C.glGetVertexAttribfv(index, pname, params)
}

fn C.glGetVertexAttribiv(index GLuint, pname Flag, params &GLint)

pub fn get_vertex_attribiv(index GLuint, pname Flag, params &GLint) {
	C.glGetVertexAttribiv(index, pname, params)
}

fn C.glGetVertexAttribPointerv(index GLuint, pname Flag, pointer &voidptr)

pub fn get_vertex_attrib_pointerv(index GLuint, pname Flag, pointer &voidptr) {
	C.glGetVertexAttribPointerv(index, pname, pointer)
}

fn C.glHint(target Flag, mode Flag)

pub fn hint(target Flag, mode Flag) {
	C.glHint(target, mode)
}

fn C.glIsBuffer(buffer GLuint) GLboolean

pub fn is_buffer(buffer GLuint) GLboolean {
	return C.glIsBuffer(buffer)
}

fn C.glIsEnabled(cap Flag) GLboolean

pub fn is_enabled(cap Flag) GLboolean {
	return C.glIsEnabled(cap)
}

fn C.glIsFramebuffer(framebuffer GLuint) GLboolean

pub fn is_framebuffer(framebuffer GLuint) GLboolean {
	return C.glIsFramebuffer(framebuffer)
}

fn C.glIsProgram(program GLuint) GLboolean

pub fn is_program(program GLuint) GLboolean {
	return C.glIsProgram(program)
}

fn C.glIsRenderbuffer(renderbuffer GLuint) GLboolean

pub fn is_renderbuffer(renderbuffer GLuint) GLboolean {
	return C.glIsRenderbuffer(renderbuffer)
}

fn C.glIsShader(shader GLuint) GLboolean

pub fn is_shader(shader GLuint) GLboolean {
	return C.glIsShader(shader)
}

fn C.glIsTexture(texture GLuint) GLboolean

pub fn is_texture(texture GLuint) GLboolean {
	return C.glIsTexture(texture)
}

fn C.glLineWidth(width GLfloat)

pub fn line_width(width GLfloat) {
	C.glLineWidth(width)
}

fn C.glLinkProgram(program GLuint)

pub fn link_program(program GLuint) {
	C.glLinkProgram(program)
}

fn C.glPixelStorei(pname Flag, param GLint)

pub fn pixel_storei(pname Flag, param GLint) {
	C.glPixelStorei(pname, param)
}

fn C.glPolygonOffset(factor GLfloat, units GLfloat)

pub fn polygon_offset(factor GLfloat, units GLfloat) {
	C.glPolygonOffset(factor, units)
}

fn C.glReadPixels(x GLint, y GLint, width GLsizei, height GLsizei, format Flag, type_ Flag, pixels voidptr)

pub fn read_pixels(x GLint, y GLint, width GLsizei, height GLsizei, format Flag, type_ Flag, pixels voidptr) {
	C.glReadPixels(x, y, width, height, format, type_, pixels)
}

fn C.glReleaseShaderCompiler()

pub fn release_shader_compiler() {
	C.glReleaseShaderCompiler()
}

fn C.glRenderbufferStorage(target Flag, internalformat Flag, width GLsizei, height GLsizei)

pub fn renderbuffer_storage(target Flag, internalformat Flag, width GLsizei, height GLsizei) {
	C.glRenderbufferStorage(target, internalformat, width, height)
}

fn C.glSampleCoverage(value GLfloat, invert GLboolean)

pub fn sample_coverage(value GLfloat, invert GLboolean) {
	C.glSampleCoverage(value, invert)
}

fn C.glScissor(x GLint, y GLint, width GLsizei, height GLsizei)

pub fn scissor(x GLint, y GLint, width GLsizei, height GLsizei) {
	C.glScissor(x, y, width, height)
}

fn C.glShaderBinary(count GLsizei, shaders &GLuint, binaryformat Flag, binary voidptr, length GLsizei)

pub fn shader_binary(count GLsizei, shaders &GLuint, binaryformat Flag, binary voidptr, length GLsizei) {
	C.glShaderBinary(count, shaders, binaryformat, binary, length)
}

fn C.glShaderSource(shader GLuint, count GLsizei, string_ &&GLchar, length &GLint)

// TODO: Make glshadersource() a function not requiring a length to pass
pub fn shader_source(shader GLuint, count GLsizei, string_ &&GLchar, length GLint) {
	C.glShaderSource(shader, count, string_, &length)
}

fn C.glStencilFunc(func Flag, ref GLint, mask GLuint)

pub fn stencil_func(func Flag, ref GLint, mask GLuint) {
	C.glStencilFunc(func, ref, mask)
}

fn C.glStencilFuncSeparate(face Flag, func Flag, ref GLint, mask GLuint)

pub fn stencil_func_separate(face Flag, func Flag, ref GLint, mask GLuint) {
	C.glStencilFuncSeparate(face, func, ref, mask)
}

fn C.glStencilMask(mask GLuint)

pub fn stencil_mask(mask GLuint) {
	C.glStencilMask(mask)
}

fn C.glStencilMaskSeparate(face Flag, mask GLuint)

pub fn stencil_mask_separate(face Flag, mask GLuint) {
	C.glStencilMaskSeparate(face, mask)
}

fn C.glStencilOp(fail Flag, zfail Flag, zpass Flag)

pub fn stencil_op(fail Flag, zfail Flag, zpass Flag) {
	C.glStencilOp(fail, zfail, zpass)
}

fn C.glStencilOpSeparate(face Flag, sfail Flag, dpfail Flag, dppass Flag)

pub fn stencil_op_separate(face Flag, sfail Flag, dpfail Flag, dppass Flag) {
	C.glStencilOpSeparate(face, sfail, dpfail, dppass)
}

fn C.glTexImage2D(target Flag, level GLint, internalformat GLint, width GLsizei, height GLsizei, border GLint, format Flag, type_ Flag, pixels voidptr)

pub fn tex_image2d(target Flag, level GLint, internalformat GLint, width GLsizei, height GLsizei, border GLint, format Flag, type_ Flag, pixels voidptr) {
	C.glTexImage2D(target, level, internalformat, width, height, border, format, type_,
		pixels)
}

fn C.glTexParameterf(target Flag, pname Flag, param GLfloat)

pub fn tex_parameterf(target Flag, pname Flag, param GLfloat) {
	C.glTexParameterf(target, pname, param)
}

fn C.glTexParameterfv(target Flag, pname Flag, params &GLfloat)

pub fn tex_parameterfv(target Flag, pname Flag, params &GLfloat) {
	C.glTexParameterfv(target, pname, params)
}

fn C.glTexParameteri(target Flag, pname Flag, param GLint)

pub fn tex_parameteri(target Flag, pname Flag, param GLint) {
	C.glTexParameteri(target, pname, param)
}

fn C.glTexParameteriv(target Flag, pname Flag, params &GLint)

pub fn tex_parameteriv(target Flag, pname Flag, params &GLint) {
	C.glTexParameteriv(target, pname, params)
}

fn C.glTexSubImage2D(target Flag, level GLint, xoffset GLint, yoffset GLint, width GLsizei, height GLsizei, format Flag, type_ Flag, pixels voidptr)

pub fn tex_subimage2d(target Flag, level GLint, xoffset GLint, yoffset GLint, width GLsizei, height GLsizei, format Flag, type_ Flag, pixels voidptr) {
	C.glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type_, pixels)
}

fn C.glUniform1f(location GLint, v0 GLfloat)

pub fn uniform1f(location GLint, v0 GLfloat) {
	C.glUniform1f(location, v0)
}

fn C.glUniform1fv(location GLint, count GLsizei, value &GLfloat)

pub fn uniform1fv(location GLint, count GLsizei, value &GLfloat) {
	C.glUniform1fv(location, count, value)
}

fn C.glUniform1i(location GLint, v0 GLint)

pub fn uniform1i(location GLint, v0 GLint) {
	C.glUniform1i(location, v0)
}

fn C.glUniform1iv(location GLint, count GLsizei, value voidptr)

pub fn uniform1iv(location GLint, count GLsizei, value voidptr) {
	C.glUniform1iv(location, count, value)
}

fn C.glUniform2f(location GLint, v0 GLfloat, v1 GLfloat)

pub fn uniform2f(location GLint, v0 GLfloat, v1 GLfloat) {
	C.glUniform2f(location, v0, v1)
}

fn C.glUniform2fv(location GLint, count GLsizei, value &GLfloat)

pub fn uniform2fv(location GLint, count GLsizei, value &GLfloat) {
	C.glUniform2fv(location, count, value)
}

fn C.glUniform2i(location GLint, v0 GLint, v1 GLint)

pub fn uniform2i(location GLint, v0 GLint, v1 GLint) {
	C.glUniform2i(location, v0, v1)
}

fn C.glUniform2iv(location GLint, count GLsizei, value &GLint)

pub fn uniform2iv(location GLint, count GLsizei, value &GLint) {
	C.glUniform2iv(location, count, value)
}

fn C.glUniform3f(location GLint, v0 GLfloat, v1 GLfloat, v2 GLfloat)

pub fn uniform3f(location GLint, v0 GLfloat, v1 GLfloat, v2 GLfloat) {
	C.glUniform3f(location, v0, v1, v2)
}

fn C.glUniform3fv(location GLint, count GLsizei, value &GLfloat)

pub fn uniform3fv(location GLint, count GLsizei, value &GLfloat) {
	C.glUniform3fv(location, count, value)
}

fn C.glUniform3i(location GLint, v0 GLint, v1 GLint, v2 GLint)

pub fn uniform3i(location GLint, v0 GLint, v1 GLint, v2 GLint) {
	C.glUniform3i(location, v0, v1, v2)
}

fn C.glUniform3iv(location GLint, count GLsizei, value &GLint)

pub fn uniform3iv(location GLint, count GLsizei, value &GLint) {
	C.glUniform3iv(location, count, value)
}

fn C.glUniform4f(location GLint, v0 GLfloat, v1 GLfloat, v2 GLfloat, v3 GLfloat)

pub fn uniform4f(location GLint, v0 GLfloat, v1 GLfloat, v2 GLfloat, v3 GLfloat) {
	C.glUniform4f(location, v0, v1, v2, v3)
}

fn C.glUniform4fv(location GLint, count GLsizei, value &GLfloat)

pub fn uniform4fv(location GLint, count GLsizei, value &GLfloat) {
	C.glUniform4fv(location, count, value)
}

fn C.glUniform4i(location GLint, v0 GLint, v1 GLint, v2 GLint, v3 GLint)

pub fn uniform4i(location GLint, v0 GLint, v1 GLint, v2 GLint, v3 GLint) {
	C.glUniform4i(location, v0, v1, v2, v3)
}

fn C.glUniform4iv(location GLint, count GLsizei, value &GLint)

pub fn uniform4iv(location GLint, count GLsizei, value &GLint) {
	C.glUniform4iv(location, count, value)
}

fn C.glUniformMatrix2fv(location GLint, count GLsizei, transpose GLboolean, value &GLfloat)

pub fn uniformmatrix2fv(location GLint, count GLsizei, transpose GLboolean, value &GLfloat) {
	C.glUniformMatrix2fv(location, count, transpose, value)
}

fn C.glUniformMatrix3fv(location GLint, count GLsizei, transpose GLboolean, value &GLfloat)

pub fn uniformmatrix3fv(location GLint, count GLsizei, transpose GLboolean, value &GLfloat) {
	C.glUniformMatrix3fv(location, count, transpose, value)
}

fn C.glUniformMatrix4fv(location GLint, count GLsizei, transpose GLboolean, value &GLfloat)

pub fn uniformmatrix4fv(location GLint, count GLsizei, transpose GLboolean, value &GLfloat) {
	C.glUniformMatrix4fv(location, count, transpose, value)
}

fn C.glUseProgram(program GLuint)

pub fn use_program(program GLuint) {
	C.glUseProgram(program)
}

fn C.glValidateProgram(program GLuint)

pub fn validate_program(program GLuint) {
	C.glValidateProgram(program)
}

fn C.glVertexAttrib1f(index GLuint, x GLfloat)

pub fn vertex_attrib1f(index GLuint, x GLfloat) {
	C.glVertexAttrib1f(index, x)
}

fn C.glVertexAttrib1fv(index GLuint, v &GLfloat)

pub fn vertex_attrib1fv(index GLuint, v &GLfloat) {
	C.glVertexAttrib1fv(index, v)
}

fn C.glVertexAttrib2f(index GLuint, x GLfloat, y GLfloat)

pub fn vertex_attrib2f(index GLuint, x GLfloat, y GLfloat) {
	C.glVertexAttrib2f(index, x, y)
}

fn C.glVertexAttrib2fv(index GLuint, v &GLfloat)

pub fn vertex_attrib2fv(index GLuint, v &GLfloat) {
	C.glVertexAttrib2fv(index, v)
}

fn C.glVertexAttrib3f(index GLuint, x GLfloat, y GLfloat, z GLfloat)

pub fn vertex_attrib3f(index GLuint, x GLfloat, y GLfloat, z GLfloat) {
	C.glVertexAttrib3f(index, x, y, z)
}

fn C.glVertexAttrib3fv(index GLuint, v &GLfloat)

pub fn vertex_attrib3fv(index GLuint, v &GLfloat) {
	C.glVertexAttrib3fv(index, v)
}

fn C.glVertexAttrib4f(index GLuint, x GLfloat, y GLfloat, z GLfloat, w GLfloat)

pub fn vertex_attrib4f(index GLuint, x GLfloat, y GLfloat, z GLfloat, w GLfloat) {
	C.glVertexAttrib4f(index, x, y, z, w)
}

fn C.glVertexAttrib4fv(index GLuint, v &GLfloat)

pub fn vertex_attrib4fv(index GLuint, v &GLfloat) {
	C.glVertexAttrib4fv(index, v)
}

fn C.glVertexAttribPointer(index GLuint, size GLint, type_ Flag, normalized GLboolean, stride GLsizei, pointer voidptr)

pub fn vertex_attrib_pointer(index GLuint, size GLint, type_ Flag, normalized GLboolean, stride GLsizei, pointer voidptr) {
	C.glVertexAttribPointer(index, size, type_, normalized, stride, pointer)
}

fn C.glViewport(x GLint, y GLint, width GLsizei, height GLsizei)

pub fn viewport(x GLint, y GLint, width GLsizei, height GLsizei) {
	C.glViewport(x, y, width, height)
}

// GL EXTENSIONS
// GL_OES_vertex_array_object

// fn C.glBindVertexArrayOES(array GLuint)
// pub fn bind_vertex_array_oes(array GLuint) {
// 	C.glBindVertexArrayOES(array)
// }
//
// fn C.glDeleteVertexArraysOES(n GLsizei, arrays &GLuint)
// pub fn delete_vertex_arrays_oes(n GLsizei, arrays &GLuint) {
// 	C.glDeleteVertexArraysOES(n, arrays)
// }
//
// fn C.glGenVertexArraysOES(n GLsizei, arrays &GLuint)
// pub fn gen_vertex_arrays_oes(n GLsizei, arrays &GLuint) {
// 	C.glGenVertexArraysOES(n, arrays)
// }
//
// fn C.glIsVertexArrayOES(array GLuint) GLboolean
// pub fn is_vertex_array_oes(array GLuint) GLboolean {
// 	return C.glIsVertexArrayOES(array)
// }
