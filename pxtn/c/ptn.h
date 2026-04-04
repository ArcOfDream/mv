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
#ifndef MPXTNLIB_PTN_H
#define MPXTNLIB_PTN_H

#include "common.h"

#include "descriptor.h"

typedef enum {
	WAVETYPE_None,
	WAVETYPE_Sine,
	WAVETYPE_Saw,
	WAVETYPE_Rect,
	WAVETYPE_Random,
	WAVETYPE_Saw2,
	WAVETYPE_Rect2,

	WAVETYPE_Tri,
	WAVETYPE_Random2,
	WAVETYPE_Rect3,
	WAVETYPE_Rect4,
	WAVETYPE_Rect8,
	WAVETYPE_Rect16,
	WAVETYPE_Saw3,
	WAVETYPE_Saw4,
	WAVETYPE_Saw6,
	WAVETYPE_Saw8,

	WAVETYPE_num
} WAVETYPE;

typedef struct {
	WAVETYPE type;
	f32      freq;
	f32      volume;
	f32      offset;
	bool     reverse;
} NOISEDESIGN_OSCILLATOR;

typedef struct {
	bool   enable;
	u32    env_num;
	POINT *envs;
	s8     pan;
	NOISEDESIGN_OSCILLATOR main;
	NOISEDESIGN_OSCILLATOR freq;
	NOISEDESIGN_OSCILLATOR volu;
} NOISEDESIGN_UNIT;

typedef struct {
	const u32 size;
	const s16 *data;
} PTN_TABLE;

typedef struct {
	u32 smp_num;
	u8  size;
	NOISEDESIGN_UNIT *units;
} PTN;

void  ptn_free(PTN *p_ptn);
bool  ptn_read(PTN *p_ptn, DESCRIPTOR *p_desc);
s16  *ptn_build(PTN *p_ptn);

#endif
