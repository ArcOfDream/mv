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
#include "common.h"

#include "descriptor.h"

#include "delay.h"

void delay_free(DELAY *p_delay)
{
	delay_tone_release(p_delay);
}

void delay_tone_release(DELAY *p_delay)
{
	if(!p_delay) return;
	if(!p_delay->p_buf) return;

	/* release memory */
	free(p_delay->p_buf);
	p_delay->p_buf   = NULL;
	p_delay->smp_num = 0;
	return;
}

bool delay_tone_ready(DELAY *p_delay, u32 beat_num, float beat_tempo)
{
	delay_tone_release(p_delay);

	if(!p_delay) return false;
	if(p_delay->freq <= 0) return true;
	if(p_delay->rate <= 0) return true;

	p_delay->offset = 0;
	switch(p_delay->unit)
	{
	case DELAYUNIT_Beat:
		p_delay->smp_num = MPXTN_SPS * 60 / beat_tempo / p_delay->freq;
		break;
	case DELAYUNIT_Meas:
		p_delay->smp_num = MPXTN_SPS * 60 * beat_num / beat_tempo / p_delay->freq;
		break;
	case DELAYUNIT_Second:
		p_delay->smp_num = MPXTN_SPS / p_delay->freq;
		break;
	default:
		return false;
	}

	p_delay->p_buf = calloc(p_delay->smp_num * MPXTN_CH, sizeof(s32));

	return true;
}

void delay_tone_supple(DELAY *p_delay, s32 *group_smps, u32 ch)
{
	if(!p_delay->smp_num) return;

	s32 a = p_delay->p_buf[p_delay->offset * 2 + ch] * p_delay->rate / 100;
	group_smps[p_delay->group] += a;
	p_delay->p_buf[p_delay->offset * 2 + ch] = group_smps[p_delay->group];
}

void delay_tone_increment(DELAY *p_delay)
{
	if(!p_delay->smp_num) return;
	if(++p_delay->offset >= p_delay->smp_num) p_delay->offset = 0;
}

void delay_tone_clear(DELAY *p_delay)
{
	if(!p_delay->smp_num) return;
	memset(p_delay->p_buf, 0, p_delay->smp_num * MPXTN_CH * sizeof(s32));
}

/* -------------------------------------------------------------------------- */

static size_t _DELAYSIZE = 12;

struct _DELAYSTRUCT
{
	u16 unit;  //  0:2
	u16 group; //  2:2
	f32 rate;  //  4:4
	f32 freq;  //  8:4 -> 12byte
};

bool delay_read(DELAY *p_delay, DESCRIPTOR *p_desc)
{
	u32 size;
	struct _DELAYSTRUCT d;

	/* read and check size */
	if(!desc_u32_r(p_desc, &size   )) return false;
	if(!desc_u16_r(p_desc, &d.unit )) return false;
	if(!desc_u16_r(p_desc, &d.group)) return false;
	if(!desc_f32_r(p_desc, &d.rate )) return false;
	if(!desc_f32_r(p_desc, &d.freq )) return false;

	/* pre check */
	if(size != _DELAYSIZE) return false;
	if(d.unit > 2) return false;
	if(d.group >= GROUP_MAX) return false;

	p_delay->unit  = d.unit;
	p_delay->freq  = d.freq;
	p_delay->rate  = (s32)d.rate;
	p_delay->group = d.group;

	return true;
}
