module math

/*
OpenGL compatible 4x4 matrix in column major order
 *
 * m[0] m[4] m[8]  m[12]
 * m[1] m[5] m[9]  m[13]
 * m[2] m[6] m[10] m[14]
 * m[3] m[7] m[11] m[15]
*/
pub struct Mat44 {
pub mut:
	data [16]f32
}

pub fn (m Mat44) str() string {
	return '${m.data[0]} ${m.data[4]} ${m.data[8]} ${m.data[12]}\n' +
		'${m.data[1]} ${m.data[5]} ${m.data[9]} ${m.data[13]}\n' +
		'${m.data[2]} ${m.data[6]} ${m.data[10]} ${m.data[14]}\n' +
		'${m.data[3]} ${m.data[7]} ${m.data[11]} ${m.data[15]}\n'
}

pub fn (m Mat44) * (other Mat44) Mat44 {
	return m.mult(other)
}

pub fn (m Mat44) mult_vec2(v Vec2) Vec2 {
	return Vec2{
		x: m.data[0] * v.x + m.data[4] * v.y
		y: m.data[1] * v.x + m.data[5] * v.y
	}
}

pub fn (m Mat44) mult_vec3(v Vec3) Vec3 {
	return Vec3{
		x: m.data[0] * v.x + m.data[4] * v.y + m.data[8] * v.z
		y: m.data[1] * v.x + m.data[5] * v.y + m.data[9] * v.z
		z: m.data[2] * v.x + m.data[6] * v.y + m.data[10] * v.z
	}
}

pub fn (m Mat44) mult_vec4(v Vec4) Vec4 {
	return Vec4{
		x: m.data[0] * v.x + m.data[4] * v.y + m.data[8] * v.z + m.data[12] * v.w
		y: m.data[1] * v.x + m.data[5] * v.y + m.data[9] * v.z + m.data[13] * v.w
		z: m.data[2] * v.x + m.data[6] * v.y + m.data[10] * v.z + m.data[14] * v.w
		w: m.data[3] * v.x + m.data[7] * v.y + m.data[11] * v.z + m.data[15] * v.w
	}
}

pub fn Mat44.zero() Mat44 {
	mut result := Mat44{}
	unsafe { C.memset(&result, 0, sizeof(Mat44)) }
	return result
}

pub fn Mat44.identity() Mat44 {
	mut result := Mat44.zero()
	result.data[0] = 1.0
	result.data[5] = 1.0
	result.data[10] = 1.0
	result.data[15] = 1.0
	return result
}

pub fn (m Mat44) get_col(index int) Vec4 {
	match index {
		0 { return Vec4{m.data[0], m.data[1], m.data[2], m.data[3]} }
		1 { return Vec4{m.data[4], m.data[5], m.data[6], m.data[7]} }
		2 { return Vec4{m.data[8], m.data[9], m.data[10], m.data[11]} }
		3 { return Vec4{m.data[12], m.data[13], m.data[14], m.data[15]} }
		else { panic('index out of bounds: ${index}') }
	}
}

pub fn (m Mat44) get_row(index int) Vec4 {
	match index {
		0 { return Vec4{m.data[0], m.data[4], m.data[8], m.data[12]} }
		1 { return Vec4{m.data[1], m.data[5], m.data[9], m.data[13]} }
		2 { return Vec4{m.data[2], m.data[6], m.data[10], m.data[14]} }
		3 { return Vec4{m.data[3], m.data[7], m.data[11], m.data[15]} }
		else { panic('index out of bounds: ${index}') }
	}
}

pub fn (m Mat44) get(row int, column int) f32 {
	return m.data[row * 4 + column]
}

pub fn (mut m Mat44) set(row int, column int, val f32) {
	m.data[row * 4 + column] = val
}

pub fn mat44_translate(offset Vec3) Mat44 {
	mut result := Mat44.identity()
	result.data[12] = offset.x
	result.data[13] = offset.y
	result.data[14] = offset.z
	return result
}

pub fn ma44_scale(sx f32, sy f32, sz f32) Mat44 {
	mut result := Mat44.identity()
	result.data[0] = sx
	result.data[5] = sy
	result.data[10] = sz
	return result
}

pub fn mat44_rotate(angle f32, unnormalized_axis Vec3) Mat44 {
	c := cos(angle)
	s := sin(angle)

	axis := unnormalized_axis.normalize()
	temp := axis.scale(1.0 - c)

	mut result := Mat44.identity()
	result.set(0, 0, c + temp.x * axis.x)
	result.set(0, 1, 0.0 + temp.x * axis.y + s * axis.z)
	result.set(0, 2, 0.0 + temp.x * axis.z - s * axis.y)

	result.set(1, 0, 0.0 + temp.y * axis.x - s * axis.z)
	result.set(1, 1, c + temp.y * axis.y)
	result.set(1, 2, 0.0 + temp.y * axis.z + s * axis.x)

	result.set(2, 0, 0.0 + temp.z * axis.x + s * axis.y)
	result.set(2, 1, 0.0 + temp.z * axis.y - s * axis.x)
	result.set(2, 2, c + temp.z * axis.z)

	return result
}

pub fn Mat44.ortho(left f32, right f32, bottom f32, top f32) Mat44 {
	return Mat44.ortho2d(left, right, bottom, top, -1.0, 1.0)
}

pub fn Mat44.ortho_off_center(width int, height int) Mat44 {
	half_w := int(f32(width) / 2)
	half_h := int(f32(height) / 2)
	return Mat44.ortho2d(-half_w, half_w, half_h, -half_h, -1.0, 1.0)
}

pub fn Mat44.ortho2d(left f32, right f32, bottom f32, top f32, z_near f32, z_far f32) Mat44 {
	mut result := Mat44.identity()

	result.data[0] = 2.0 / (right - left)
	result.data[5] = 2.0 / (top - bottom)
	result.data[10] = -2.0 / (z_far - z_near)
	result.data[12] = -(right + left) / (right - left)
	result.data[13] = -(top + bottom) / (top - bottom)
	result.data[14] = -(z_far + z_near) / (z_far - z_near)

	return result
}

pub fn Mat44.perspective(fovy f32, aspect f32, z_near f32, z_far f32) Mat44 {
	tan_half_fovy := tan(fovy / 2.0)

	mut result := Mat44.zero()

	result.data[0] = 1.0 / (aspect * tan_half_fovy)
	result.data[5] = 1.0 / tan_half_fovy
	result.data[10] = -(z_far + z_near) / (z_far - z_near)
	result.data[11] = -1.0
	result.data[14] = -(2.0 * z_far * z_near) / (z_far - z_near)

	return result
}

pub fn Mat44.look_at(eye Vec3, center Vec3, up Vec3) Mat44 {
	f := (center - eye).normalize()
	s := f.cross(up).normalize()
	u := s.cross(f)

	mut result := Mat44.identity()

	result.data[0] = s.x
	result.data[4] = s.y
	result.data[8] = s.z
	result.data[1] = u.x
	result.data[5] = u.y
	result.data[9] = u.z
	result.data[2] = -f.x
	result.data[6] = -f.y
	result.data[10] = -f.z
	result.data[12] = -s.dot(eye)
	result.data[13] = -u.dot(eye)
	result.data[14] = f.dot(eye)

	return result
}

// swap two elements within a Mat44
fn (mut m Mat44) swap(i0 int, i1 int) {
	tmp := m.data[i0]
	m.data[i0] = m.data[i1]
	m.data[i1] = tmp
}

pub fn (m Mat44) transpose() Mat44 {
	mut result := Mat44{}
	result.swap(1, 4)
	result.swap(2, 8)
	result.swap(6, 9)
	result.swap(3, 12)
	result.swap(7, 13)
	result.swap(11, 14)
	return result
}

pub fn (m Mat44) mult(other Mat44) Mat44 {
	mut result := Mat44{}

	lr0 := m.get_row(0)
	lr1 := m.get_row(1)
	lr2 := m.get_row(2)
	lr3 := m.get_row(3)

	mut t := other.get_col(0)
	result.data[0] = lr0.dot(t)
	result.data[1] = lr1.dot(t)
	result.data[2] = lr2.dot(t)
	result.data[3] = lr3.dot(t)

	t = other.get_col(1)
	result.data[4] = lr0.dot(t)
	result.data[5] = lr1.dot(t)
	result.data[6] = lr2.dot(t)
	result.data[7] = lr3.dot(t)

	t = other.get_col(2)
	result.data[8] = lr0.dot(t)
	result.data[9] = lr1.dot(t)
	result.data[10] = lr2.dot(t)
	result.data[11] = lr3.dot(t)

	t = other.get_col(3)
	result.data[12] = lr0.dot(t)
	result.data[13] = lr1.dot(t)
	result.data[14] = lr2.dot(t)
	result.data[15] = lr3.dot(t)

	return result
}

pub fn (m Mat44) transform(v Vec4) Vec4 {
	mut result := Vec4{}
	result.x = m.get_row(0).dot(v)
	result.y = m.get_row(1).dot(v)
	result.z = m.get_row(2).dot(v)
	result.w = m.get_row(3).dot(v)
	return result
}

pub fn (m Mat44) transform_v3(v Vec3) Vec3 {
	tmp := Vec4{v.x, v.y, v.z, 1.0}
	r := m.transform(tmp)
	return r.xyz()
}

pub fn (m Mat44) to_mat33() Mat33 {
	mut result := Mat33{}

	result.data[0] = m.data[0]
	result.data[1] = m.data[1]
	result.data[2] = m.data[2]

	result.data[3] = m.data[4]
	result.data[4] = m.data[5]
	result.data[5] = m.data[6]

	result.data[6] = m.data[8]
	result.data[7] = m.data[9]
	result.data[8] = m.data[10]

	return result
}
