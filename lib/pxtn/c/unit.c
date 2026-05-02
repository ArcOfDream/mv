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
#include "unit.h"


void unit_tone_init(UNIT *p_u)
{
	memset(p_u, 0, sizeof(UNIT));

	/* set non zero value */
	p_u->groupno  = EVENTDEFAULT_GROUPNO;
	p_u->velocity = EVENTDEFAULT_VELOCITY;
	p_u->volume   = EVENTDEFAULT_VOLUME;
	p_u->tuning   = EVENTDEFAULT_TUNING;

	p_u->pan_vols[0] = PAN_VOLUME_MAX;
	p_u->pan_vols[1] = PAN_VOLUME_MAX;

	p_u->operated = true;
	p_u->played = true;
}

void unit_tone_clear(UNIT *p_u)
{
	memset(&p_u->uts, 0, sizeof(p_u->uts));
}

void unit_tone_reset_and_2prm(UNIT *p_u, u32 voice_idx, s32 clock, f64 offset_freq)
{
	UNITTONE *p_ut = &p_u->uts[voice_idx];

	p_ut->life_count        = 0;
	p_ut->on_count          = 0;
	p_ut->smp_pos           = 0;
	p_ut->smooth_volume     = 0;
	p_ut->env_release_clock = clock;
	p_ut->offset_freq       = offset_freq;
}

void unit_set_woice(UNIT *p_u, const WOICE *p_woice)
{
	p_u->p_woice    = p_woice;
	p_u->key_now    = EVENTDEFAULT_KEY;
	p_u->key_margin = 0;
	p_u->key_start  = EVENTDEFAULT_KEY;
}

void unit_tone_zerolives(UNIT *p_u)
{
	for(u32 i = 0; i < WOICEINSTANCE_MAX; ++i) {
		p_u->uts[i].life_count = 0;
	}
}

void unit_tone_keyon(UNIT *p_u)
{
	p_u->key_now    = p_u->key_start + p_u->key_margin;
	p_u->key_start  = p_u->key_now;
	p_u->key_margin = 0;
}

void unit_tone_key(UNIT *p_u, s32 key)
{
	p_u->key_start  = p_u->key_now;
	p_u->key_margin = key - p_u->key_start;
	p_u->pm_smp_pos = 0;
}

void unit_tone_pan_volume(UNIT *p_u, s32 pan)
{
	p_u->pan_vols[0] = PAN_VOLUME_MAX;
	p_u->pan_vols[1] = PAN_VOLUME_MAX;

	if(pan >= PAN_VOLUME_MAX) p_u->pan_vols[0] = PAN_MAX - pan;
	else                      p_u->pan_vols[1] =           pan;
}

void unit_tone_pan_time(UNIT *p_u, s32 pan)
{
	p_u->pan_times[0] = 0;
	p_u->pan_times[1] = 0;

	if(pan >= 64) {
		p_u->pan_times[0] = (u32)pan - 64;
		if(p_u->pan_times[0] > 63) p_u->pan_times[0] = 63;
	} else {
		p_u->pan_times[1] = 64 - (u32)pan;
		if(p_u->pan_times[1] > 63) p_u->pan_times[1] = 63;
	}
}

void unit_tone_velocity(UNIT *p_u, s32 val)
{
	if(val < 0           ) val = 0;
	if(val > VELOCITY_MAX) val = VELOCITY_MAX;

	p_u->velocity = val;
}

void unit_tone_volume(UNIT *p_u, s32 val)
{
	if(val < 0         ) val = 0;
	if(val > VOLUME_MAX) val = VOLUME_MAX;

	p_u->volume = val;
}

void unit_tone_portament(UNIT *p_u, s32 val)
{
	if(val < 0) val = 0;
	p_u->pm_smp_num = val;
}
void unit_tone_groupno(UNIT *p_u, s32 val)
{
	p_u->groupno = val % GROUP_MAX;
}

void unit_tone_tuning(UNIT *p_u, f32 val)
{
	p_u->tuning = (f64)val;
}

void unit_tone_envelope(UNIT *p_u)
{
	if(!p_u->p_woice) return;

	for(u32 i = 0; i < p_u->p_woice->size; ++i) {

		const WOICEINSTANCE *p_wi = &p_u->p_woice->insts[i];
		UNITTONE *p_ut = &p_u->uts[i];

		if(p_ut->life_count > 0 && p_wi->env_num) {

			if(p_ut->on_count > 0) {

				if(p_ut->env_pos < (s32)p_wi->env_num) {

					p_ut->env_volume = p_wi->envs[p_ut->env_pos];
					p_ut->env_pos++;
				}

			} else {

				p_ut->env_volume = p_ut->env_start - p_ut->env_start * p_ut->env_pos / p_wi->env_release;
				p_ut->env_pos++;
			}
		}
	}
}

void unit_tone_sample(UNIT *p_u, u32 time_pan_index, s32 smooth_smp)
{

	u32 pos;
	s32 work;
	s32 time_pan_buf;

	if(!p_u->played) {
		p_u->pan_time_bufs[0][time_pan_index] = 0;
		p_u->pan_time_bufs[1][time_pan_index] = 0;
		return;
	}

	for(u32 ch = 0; ch < MPXTN_CH; ++ch) {

		time_pan_buf = 0;

		for(u32 v = 0; v < p_u->p_woice->size; ++v) {

			const WOICEINSTANCE *p_wi = &p_u->p_woice->insts[v];
			UNITTONE *p_ut = &p_u->uts[v];

			work = 0;

			if(p_ut->life_count > 0) {

				pos = (u32)(p_ut->smp_pos) * 2 + ch;
				work += p_wi->smps[pos];

				work = work * p_u->velocity     / VELOCITY_MAX;
				work = work * p_u->volume       / VOLUME_MAX;
				work = work * p_u->pan_vols[ch] / PAN_VOLUME_MAX;

				if(p_wi->env_num) work = work * p_ut->env_volume / VOLUME_MAX;

				/* smooth tail */
				if(p_wi->smooth && p_ut->life_count < smooth_smp) {
					work = work * p_ut->life_count / smooth_smp;
				}
			}

			time_pan_buf += work;
		}

		p_u->pan_time_bufs[ch][time_pan_index] = time_pan_buf;
	}
}

void unit_tone_supple(const UNIT *p_u, s32 *group_smps, u32 ch, u32 time_pan_index)
{
	u32 idx = (time_pan_index - p_u->pan_times[ch]) & ((u32)BUFSIZE_TIMEPAN - 1);
	group_smps[p_u->groupno] += p_u->pan_time_bufs[ch][idx];
}

s32 unit_tone_increment_key(UNIT *p_u)
{
	// portamento..
	if(p_u->pm_smp_num && p_u->key_margin) {

		if( p_u->pm_smp_pos < p_u->pm_smp_num) {

			p_u->pm_smp_pos++;
			p_u->key_now = p_u->key_start + p_u->key_margin * p_u->pm_smp_pos / p_u->pm_smp_num;

		} else {

			p_u->key_now    = p_u->key_start + p_u->key_margin;
			p_u->key_start  = p_u->key_now;
			p_u->key_margin = 0;

		}

	} else {
		p_u->key_now = p_u->key_start + p_u->key_margin;
	}

	return p_u->key_now;
}

void unit_tone_increment_sample(UNIT *p_u, f64 freq)
{
	for(u32 i = 0; i < p_u->p_woice->size; ++i) {

		const WOICEINSTANCE *p_wi = &p_u->p_woice->insts[i];
		UNITTONE *p_ut = &p_u->uts[i];

		if(p_ut->life_count > 0) p_ut->life_count--;
		if(p_ut->life_count > 0) {

			p_ut->on_count--;

			p_ut->smp_pos += p_ut->offset_freq * p_u->tuning * freq;

			if(p_ut->smp_pos >= p_wi->smp_num) {

				if(p_wi->waveloop) {

					if(p_ut->smp_pos >= p_wi->smp_num) p_ut->smp_pos -= p_wi->smp_num;
					if(p_ut->smp_pos >= p_wi->smp_num) p_ut->smp_pos  = 0;

				} else {
					p_ut->life_count = 0;
				}
			}

			// OFF
			if(p_ut->on_count == 0 && p_wi->env_num) {

				p_ut->env_start = p_ut->env_volume;
				p_ut->env_pos   = 0;

			}
		}
	}
}

