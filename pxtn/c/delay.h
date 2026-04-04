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
#ifndef MPXTNLIB_DELAY_H
#define MPXTNLIB_DELAY_H

#include "common.h"

enum DELAYUNIT
{
	DELAYUNIT_Beat,   // 0
	DELAYUNIT_Meas,   // 1
	DELAYUNIT_Second  // 2
};

typedef struct {
	u16 unit;
	u16 group;
	s32 rate;
	f32 freq;
	u32 smp_num;
	u32 offset;
	s32 *p_buf;
} DELAY;

void delay_free(DELAY *p_delay);
bool delay_read(DELAY *p_delay, DESCRIPTOR *p_desc);

bool delay_tone_ready(DELAY *p_delay, u32 beat_num, float beat_tempo);
void delay_tone_supple(DELAY *p_delay, s32 *group_smps, u32 ch);
void delay_tone_increment(DELAY *p_delay);
void delay_tone_clear(DELAY *p_delay);
void delay_tone_release(DELAY *p_delay);

#endif
