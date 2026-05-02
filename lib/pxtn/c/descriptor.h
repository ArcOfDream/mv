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
#ifndef MPXTNLIB_DESCRIPTOR_H
#define MPXTNLIB_DESCRIPTOR_H

#include "common.h"

typedef struct {
	size_t size;
	size_t curr;
	FILE  *p_file;
	const void *p_mem;
} DESCRIPTOR;

/* set for read memory/file */
s32 desc_set_memory(DESCRIPTOR *p_desc, const void *p_mem, size_t size);
s32 desc_set_file(DESCRIPTOR *p_desc, FILE *p_file);

/* seek */
bool desc_seek(DESCRIPTOR *p_desc, s32 offset, int origin);

/* normal read */
bool desc_dat_r(DESCRIPTOR *p_desc, void *p_v, size_t size);

bool desc_u8_r (DESCRIPTOR *p_desc, u8  *p_v);
bool desc_u16_r(DESCRIPTOR *p_desc, u16 *p_v);
bool desc_u32_r(DESCRIPTOR *p_desc, u32 *p_v);
bool desc_u64_r(DESCRIPTOR *p_desc, u64 *p_v);

bool desc_s8_r (DESCRIPTOR *p_desc, s8  *p_v);
bool desc_s16_r(DESCRIPTOR *p_desc, s16 *p_v);
bool desc_s32_r(DESCRIPTOR *p_desc, s32 *p_v);
bool desc_s64_r(DESCRIPTOR *p_desc, s64 *p_v);

bool desc_f32_r(DESCRIPTOR *p_desc, f32 *p_v);
bool desc_f64_r(DESCRIPTOR *p_desc, f64 *p_v);

/* variable read */
bool desc_u32_vr(DESCRIPTOR *p_desc, u32 *p_v);
bool desc_s32_vr(DESCRIPTOR *p_desc, s32 *p_v);
bool desc_f32_vr(DESCRIPTOR *p_desc, f32 *p_v);

#endif
