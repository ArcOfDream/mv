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
#ifndef MPXTNLIB_EVELIST_H
#define MPXTNLIB_EVELIST_H

#include "common.h"

enum EVENTKIND {
	EVENTKIND_NULL      ,//  0

	EVENTKIND_ON        ,//  1
	EVENTKIND_KEY       ,//  2
	EVENTKIND_PAN_VOLUME,//  3
	EVENTKIND_VELOCITY  ,//  4
	EVENTKIND_VOLUME    ,//  5
	EVENTKIND_PORTAMENT ,//  6
	EVENTKIND_BEATCLOCK ,//  7 no-use
	EVENTKIND_BEATTEMPO ,//  8 no-use
	EVENTKIND_BEATNUM   ,//  9 no-use
	EVENTKIND_REPEAT    ,// 10
	EVENTKIND_LAST      ,// 11 no-use
	EVENTKIND_VOICENO   ,// 12
	EVENTKIND_GROUPNO   ,// 13
	EVENTKIND_TUNING    ,// 14
	EVENTKIND_PAN_TIME  ,// 15

	EVENTKIND_NUM       ,// 16
};

typedef struct _EVERECORD {
	u8 kind;
	u8 unit_no;
	s32 value;
	s32 clock;
	struct _EVERECORD *prev;
	struct _EVERECORD *next;
} EVERECORD;

typedef struct {
	u32 size;
	u32 linear;
	EVERECORD *records;
	EVERECORD *start;
} EVELIST;


bool evelist_alloc(EVELIST *p_eve, u32 size);
void evelist_free(EVELIST *p_eve);

bool evelist_linear_start(EVELIST *p_eve);
void evelist_linear_add(EVELIST *p_eve, s32 clock, u8 unit_no, u8 kind, s32 value);
void evelist_linear_end(EVELIST *p_eve);

bool evelist_read(EVELIST *p_eve, DESCRIPTOR *p_desc);
u32  evelist_read_event_num(DESCRIPTOR *p_desc);

bool evelist_check_value(EVELIST *p_eve);
bool evelist_check_unitno(EVELIST *p_eve, u32 unit_num);
bool evelist_check_voiceno(EVELIST *p_eve, u32 woice_num);

s32 evelist_get_max_clock(EVELIST *p_eve);

EVERECORD *evelist_get_records(EVELIST *p_eve);

bool evelist_kind_istail(u8 kind);

#endif
