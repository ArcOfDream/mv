module math

/*
OpenGL compatible 3x3 matrix in column major order
 *
 * m[0] m[3] m[6]
 * m[1] m[4] m[7]
 * m[2] m[5] m[8]
*/
pub struct Mat33 {
pub mut:
	data [9]f32
}

pub fn (m Mat33) * (other Mat33) Mat33 {
	mut result := Mat33{}

	lr0 := m.get_row(0)
	lr1 := m.get_row(1)
	lr2 := m.get_row(2)

	mut t := other.get_col(0)
	result.data[0] = lr0.dot(t)
	result.data[1] = lr1.dot(t)
	result.data[2] = lr2.dot(t)

	t = other.get_col(1)
	result.data[3] = lr0.dot(t)
	result.data[4] = lr1.dot(t)
	result.data[5] = lr2.dot(t)

	t = other.get_col(2)
	result.data[6] = lr0.dot(t)
	result.data[7] = lr1.dot(t)
	result.data[8] = lr2.dot(t)

	return result
}

pub fn Mat33.zero() Mat33 {
	mut result := Mat33{}
	unsafe { C.memset(&result, 0, sizeof(Mat33)) }
	return result
}

pub fn Mat33.identity() Mat33 {
	mut result := Mat33.zero()
	result.data[0] = 1.0
	result.data[4] = 1.0
	result.data[8] = 1.0
	return result
}

pub fn (m Mat33) get_col(index int) Vec3 {
	match index {
		0 { return Vec3{m.data[0], m.data[1], m.data[2]} }
		1 { return Vec3{m.data[3], m.data[4], m.data[5]} }
		2 { return Vec3{m.data[6], m.data[7], m.data[8]} }
		else { panic('index out of bounds: ${index}') }
	}
}

pub fn (m Mat33) get_row(index int) Vec3 {
	match index {
		0 { return Vec3{m.data[0], m.data[3], m.data[6]} }
		1 { return Vec3{m.data[1], m.data[4], m.data[7]} }
		2 { return Vec3{m.data[2], m.data[5], m.data[8]} }
		else { panic('index out of bounds: ${index}') }
	}
}

pub fn (m Mat33) get(row int, column int) f32 {
	return m.data[row * 3 + column]
}

pub fn (mut m Mat33) set(row int, column int, val f32) {
	m.data[row * 3 + column] = val
}

// swap two elements within a Mat33
fn (mut m Mat33) swap(i0 int, i1 int) {
	tmp := m.data[i0]
	m.data[i0] = m.data[i1]
	m.data[i1] = tmp
}

pub fn (m Mat33) transpose() Mat33 {
	mut result := Mat33{}
	result.swap(1, 3)
	result.swap(2, 6)
	result.swap(5, 7)
	return result
}

pub fn (m Mat33) det() f32 {
	mat := m.data
	result :=
		mat[0] * (mat[4] * mat[8] - mat[7] * mat[5]) - mat[3] * (mat[1] * mat[8] - mat[7] * mat[2]) +
		mat[6] * (mat[1] * mat[5] - mat[4] * mat[2])
	return result
}

pub fn (m Mat33) transform(v Vec3) Vec3 {
	mut result := Vec3{}
	result.x = m.get_row(0).dot(v)
	result.y = m.get_row(1).dot(v)
	result.z = m.get_row(2).dot(v)
	return result
}

pub fn Mat33.rotate(angle f32, unnormalizedAxis Vec3) Mat33 {
	c := cos(angle)
	s := sin(angle)

	axis := unnormalizedAxis.normalize()
	temp := axis.scale(1.0 - c)

	mut result := Mat33.identity()
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

pub fn Mat33.scale(sx f32, sy f32, sz f32) Mat33 {
	mut result := Mat33.identity()
	result.data[0] = sx
	result.data[4] = sy
	result.data[8] = sz
	return result
}
