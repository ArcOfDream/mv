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
#ifndef MPXTNLIB_WOICE_H
#define MPXTNLIB_WOICE_H

#include "common.h"

#include "descriptor.h"

typedef enum {
	WOICE_NONE,
	WOICE_PCM,
	WOICE_PTV,
	WOICE_PTN,
	WOICE_OGGV,
} WOICETYPE;

typedef struct {
	s16 *smps;
	u32 smp_num;
	s32 basic_key;
	f64 tuning;
	u8  *envs;       /* used by PTV */
	u32 env_num;     /* used by PTV */
	s32 env_release; /* used by PTV */

	bool waveloop;
	bool smooth;
	bool beatfit;
} WOICEINSTANCE;

typedef struct {
	WOICEINSTANCE *insts;
	u32           size;
	WOICETYPE     type;
} WOICE;

bool woice_read_matePCM(WOICE *p_woice, DESCRIPTOR *p_desc);
bool woice_read_matePTN(WOICE *p_woice, DESCRIPTOR *p_desc);
bool woice_read_matePTV(WOICE *p_woice, DESCRIPTOR *p_desc);

#ifdef MPXTN_OGGVORBIS
bool woice_read_mateOGGV(WOICE *p_woice, DESCRIPTOR *p_desc);
#endif

void woice_free(WOICE *p_woice);

#endif
