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
#ifndef MPXTNLIB_UNIT_H
#define MPXTNLIB_UNIT_H

#include "common.h"

#include "woice.h"

typedef struct
{
	f64 smp_pos    ;
	f64 offset_freq;
	s32 life_count ;
	s32 on_count   ;
	u32 smp_count  ;
	s32 env_start  ;
	s32 env_pos    ;
	s32 env_volume ;
	s32 env_release_clock;
	s32 smooth_volume;
} UNITTONE;

typedef struct {
	bool operated;
	bool played;
	s32 key_now;
	s32 key_start;
	s32 key_margin;
	s32 pm_smp_pos; /* portamento sample position */
	s32 pm_smp_num;
	s32 pan_vols[MPXTN_CH];
	u32 pan_times[MPXTN_CH];
	s32 pan_time_bufs[MPXTN_CH][BUFSIZE_TIMEPAN];
	s32 volume;
	s32 velocity;
	u8  groupno;
	f64 tuning;
	const WOICE *p_woice;
	UNITTONE uts[WOICEINSTANCE_MAX];
} UNIT;

void unit_tone_init(UNIT *p_u);
void unit_tone_clear(UNIT *p_u);

void unit_tone_reset_and_2prm(UNIT *p_u, u32 voice_idx, s32 clock, f64 offset_freq);
void unit_tone_zerolives(UNIT *p_u);
void unit_tone_keyon(UNIT *p_u);
void unit_tone_key(UNIT *p_u, s32 key);

void unit_tone_pan_volume(UNIT *p_u, s32 pan);
void unit_tone_pan_time(UNIT *p_u, s32 pan);

void unit_tone_velocity(UNIT *p_u, s32 val);
void unit_tone_volume(UNIT *p_u, s32 val);
void unit_tone_portament(UNIT *p_u, s32 val);
void unit_tone_groupno(UNIT *p_u, s32 val);
void unit_tone_tuning(UNIT *p_u, f32 val);

void unit_tone_envelope(UNIT *p_u);

void unit_tone_sample(UNIT *p_u, u32 time_pan_index, s32 smooth_smp);

void unit_tone_supple(const UNIT *p_u, s32 *group_smps, u32 ch, u32 time_pan_index);

s32  unit_tone_increment_key(UNIT *p_u);
void unit_tone_increment_sample(UNIT *p_u, f64 freq);

void unit_set_woice(UNIT *p_u, const WOICE *p_w);

#endif
