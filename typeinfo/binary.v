module typeinfo

pub struct BinEncoder {
pub mut:
	buf []u8
}

pub fn BinEncoder.new() BinEncoder {
	return BinEncoder{
		buf: []u8{cap: 1024}
	}
}

pub fn (e &BinEncoder) bytes() []u8 {
	return e.buf
}

pub fn (mut e BinEncoder) write_u32(v u32) ! {
	e.buf << u8(v)
	e.buf << u8(v >> 8)
	e.buf << u8(v >> 16)
	e.buf << u8(v >> 24)
}

pub fn (mut e BinEncoder) write_raw(src voidptr, n int) ! {
	unsafe {
		bytes := &u8(src)
		for i in 0 .. n {
			e.buf << bytes[i]
		}
	}
}

// TODO: write_u16, write_u64, etc. as needed

pub struct BinDecoder {
pub mut:
	buf []u8
	pos int
}

pub fn BinDecoder.new(buf []u8) BinDecoder {
	return BinDecoder{
		buf: buf
	}
}

pub fn (mut d BinDecoder) read_u32() !u32 {
	if d.pos + 4 > d.buf.len {
		return error('BinDecoder: unexpected eof')
	}
	v := u32(d.buf[d.pos]) | (u32(d.buf[d.pos + 1]) << 8) | (u32(d.buf[d.pos + 2]) << 16) | (u32(d.buf[
		d.pos + 3]) << 24)
	d.pos += 4
	return v
}

pub fn (mut d BinDecoder) read_raw(dst voidptr, n int) ! {
	if d.pos + n > d.buf.len {
		return error('BinDecoder: unexpected eof')
	}
	unsafe {
		bytes := &u8(dst)
		for i in 0 .. n {
			bytes[i] = d.buf[d.pos + i]
		}
	}
	d.pos += n
}

pub fn (mut d BinDecoder) read_raw_bytes(n int) ![]u8 {
	if d.pos + n > d.buf.len {
		return error('BinDecoder: unexpected eof')
	}
	result := d.buf[d.pos..d.pos + n].clone()
	d.pos += n
	return result
}
