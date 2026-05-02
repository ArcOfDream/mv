/* -----------------------------------------------------------------------------
 *  libmpxtn by stkchp
 * -----------------------------------------------------------------------------
 *
 * The MIT License
 *
 * Copyright (c) 2017 stkchp
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * -------------------------------------------------------------------------- */
#include "descriptor.h"

#include "error.h"

s32 desc_set_memory(DESCRIPTOR *p_desc, const void *p_mem, size_t size)
{
	if(!p_desc) return MPXTN_EINVDESC;
	if(!p_mem)  return MPXTN_EINVMEM;

	/* size check */
	if(size == 0) return MPXTN_EINVMEM;
	if(size > FILESIZE_MAX) return MPXTN_ETOOBIG;

	/* set param */
	p_desc->size = size;
	p_desc->curr = 0;

	p_desc->p_mem = p_mem;
	p_desc->p_file = NULL;

	return MPXTN_NOERR;
}

s32 desc_set_file(DESCRIPTOR *p_desc, FILE *p_file)
{
	size_t size = 0;
	char buf[1024];

	if(!p_desc) return MPXTN_EINVDESC;
	if(!p_file) return MPXTN_EINVFILE;

	if(fseek(p_file, 0, SEEK_SET) != 0) return MPXTN_EINVFILE;

	/* check filesize > FILESIZE_MAX */
	for(size = 0; size <= FILESIZE_MAX;) {
		size_t r = fread(buf, 1, 1024, p_file);
		size += r;
		if(r != 1024) break;
	}

	if(fseek(p_file, 0, SEEK_SET) != 0) return MPXTN_EINVFILE;

	/* size check */
	if(size > FILESIZE_MAX) return MPXTN_ETOOBIG;

	/* set param */
	p_desc->size = size;
	p_desc->curr = 0;

	p_desc->p_file = p_file;
	p_desc->p_mem = NULL;

	return MPXTN_NOERR;
}

bool desc_seek(DESCRIPTOR *p_desc, s32 offset, int origin)
{
	if(!p_desc) return false;
	if(!p_desc->p_file && !p_desc->p_mem) return false;

	if(p_desc->p_file) {
		if(fseek(p_desc->p_file, offset, origin) != 0) return false;
	} else {
		switch(origin)
		{
		case SEEK_SET:
			if(offset < 0) return false;
			if(offset >= (s32)p_desc->size) return false;
			p_desc->curr = (size_t)offset;
			break;
		case SEEK_CUR:
			if(((s32)p_desc->curr + offset) < 0) return false;
			if(((s32)p_desc->curr + offset) >= (s32)p_desc->size) return false;
			p_desc->curr = (size_t)((s32)p_desc->curr + offset);
			break;
		case SEEK_END:
			if(offset > 0) return false;
			if((s32)p_desc->size + offset < 0) return false;
			if((s32)p_desc->size + offset >= (s32)p_desc->size) return false;
			p_desc->curr = (size_t)((s32)p_desc->size + offset);
			break;
		default:
			return false;
		}
	}
	return true;
}

bool desc_dat_r(DESCRIPTOR *p_desc, void *p_v, size_t size)
{
	if(!p_desc) return false;
	if(!p_desc->p_file && !p_desc->p_mem) return false;

	if(p_desc->p_file) {
		size_t r = fread(p_v, 1, size, p_desc->p_file);
		if(r != size) return false;
	} else {
		if(p_desc->curr + size > p_desc->size) return false;
		memcpy(p_v, (const u8*)p_desc->p_mem + p_desc->curr, size);
		p_desc->curr += size;
	}

	return true;
}


bool desc_u8_r(DESCRIPTOR *p_desc, u8  *p_v)
{
	return desc_dat_r(p_desc, p_v, 1);
}

bool desc_u16_r(DESCRIPTOR *p_desc, u16 *p_v)
{
	u8  s[2] = {0};
	u16 d;

	if(!desc_dat_r(p_desc, s, 2)) return false;

	/* read as little endian */
	d  = ((u16)s[0]);
	d |= ((u16)s[1] << 8);
	*p_v = d;

	return true;
}

bool desc_u32_r(DESCRIPTOR *p_desc, u32 *p_v)
{
	u8  s[4] = {0};
	u32 d;

	if(!desc_dat_r(p_desc, s, 4)) return false;

	/* read as little endian */
	d  = ((u32)s[0]);
	d |= ((u32)s[1] <<  8);
	d |= ((u32)s[2] << 16);
	d |= ((u32)s[3] << 24);
	*p_v = d;

	return true;
}

bool desc_u64_r(DESCRIPTOR *p_desc, u64 *p_v)
{
	u8  s[8] = {0};
	u64 d;

	if(!desc_dat_r(p_desc, s, 8)) return false;

	/* read as little endian */
	d  = ((u64)s[0]);
	d |= ((u64)s[1] <<  8);
	d |= ((u64)s[2] << 16);
	d |= ((u64)s[3] << 24);
	d |= ((u64)s[4] << 32);
	d |= ((u64)s[5] << 40);
	d |= ((u64)s[6] << 48);
	d |= ((u64)s[7] << 54);
	*p_v = d;

	return true;
}

bool desc_s8_r (DESCRIPTOR *p_desc, s8  *p_v)
{
	return desc_u8_r(p_desc, (u8*)p_v);
}

bool desc_s16_r(DESCRIPTOR *p_desc, s16 *p_v)
{
	return desc_u16_r(p_desc, (u16*)p_v);
}

bool desc_s32_r(DESCRIPTOR *p_desc, s32 *p_v)
{
	return desc_u32_r(p_desc, (u32*)p_v);
}

bool desc_s64_r(DESCRIPTOR *p_desc, s64 *p_v)
{
	return desc_u64_r(p_desc, (u64*)p_v);
}

bool desc_f32_r(DESCRIPTOR *p_desc, f32 *p_v)
{
	return desc_u32_r(p_desc, (u32*)p_v);
}

bool desc_f64_r(DESCRIPTOR *p_desc, f64 *p_v)
{
	return desc_u64_r(p_desc, (u64*)p_v);
}

bool desc_u32_vr(DESCRIPTOR *p_desc, u32 *p_v)
{
	size_t i = 0;
	u8 a[5] = {0};
	u8 b[5] = {0};

	for(i = 0; i < 5; ++i)
	{
		if(!desc_u8_r(p_desc, &a[i])) return false;
		if(!(a[i] & 0x80)) break;
	}

	switch(i)
	{
	case 0:
		b[0]  =  (a[0] & 0x7f) >> 0;
		break;
	case 1:
		b[0]  = ((a[0] & 0x7f) >> 0);
		b[0] |=                       (a[1] << 7);
		b[1]  =  (a[1] & 0x7f) >> 1;
		break;
	case 2:
		b[0]  = ((a[0] & 0x7f) >> 0);
		b[0] |=                       (a[1] << 7);
		b[1]  = ((a[1] & 0x7f) >> 1);
		b[1] |=                       (a[2] << 6);
		b[2]  =  (a[2] & 0x7f) >> 2;
		break;
	case 3:
		b[0]  = ((a[0] & 0x7f) >> 0);
		b[0] |=                       (a[1] << 7);
		b[1]  = ((a[1] & 0x7f) >> 1);
		b[1] |=                       (a[2] << 6);
		b[2]  = ((a[2] & 0x7f) >> 2);
		b[2] |=                       (a[3] << 5);
		b[3]  =  (a[3] & 0x7f) >> 3;
		break;
	case 4:
		b[0]  = ((a[0] & 0x7f) >> 0);
		b[0] |=                       (a[1] << 7);
		b[1]  = ((a[1] & 0x7f) >> 1);
		b[1] |=                       (a[2] << 6);
		b[2]  = ((a[2] & 0x7f) >> 2);
		b[2] |=                       (a[3] << 5);
		b[3]  = ((a[3] & 0x7f) >> 3);
		b[3] |=                       (a[4] << 4);
		b[4]  =  (a[4] & 0x7f) >> 4;
		break;
	case 5:
		return false;
	}

	*p_v  =       b[0];
	*p_v |= ((u32)b[1] <<  8);
	*p_v |= ((u32)b[2] << 16);
	*p_v |= ((u32)b[3] << 24);

	return true;
}

bool desc_s32_vr(DESCRIPTOR *p_desc, s32 *p_v)
{
	return desc_u32_vr(p_desc, (u32*)p_v);
}
bool desc_f32_vr(DESCRIPTOR *p_desc, f32 *p_v)
{
	return desc_u32_vr(p_desc, (u32*)p_v);
}

