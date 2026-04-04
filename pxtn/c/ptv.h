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
#ifndef MPXTNLIB_PTV_H
#define MPXTNLIB_PTV_H

#include "common.h"

#include "descriptor.h"

#define PTV_DATAFLAG_WAVE        0x00000001u
#define PTV_DATAFLAG_ENVELOPE    0x00000002u
#define PTV_DATAFLAG_UNCOVERED   0xfffffffcu

typedef enum {
	PTV_Coodinate,
	PTV_Overtone,
	PTV_Sampling
} PTVTYPE;

typedef struct {
	u32 size;
	u32 reso; // COORDINATERESOLUTION
	POINT *points;
} PTVWAVE;

typedef struct {
	u32 fps;
	u32 head_num;
	u32 body_num;
	u32 tail_num;
	POINT *points;
} PTVENVELOPE;

typedef struct {
	PTVTYPE type;
	s32 basic_key;
	u32 volume;
	s32 pan;
	f32 tuning;
	u32 voice_flags;
	u32 data_flags;
	PTVWAVE     wav;
	PTVENVELOPE env;
} PTVINSTANCE;

typedef struct {
	u32 size;
	PTVINSTANCE *insts;
} PTV;

void ptv_free(PTV *p_ptv);

bool ptv_read(PTV *p_ptv, DESCRIPTOR *p_desc);

#endif
