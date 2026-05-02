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

#include "master.h"

/* -------------------------------------------------------------------------- */

u32 master_get_last_clock(MASTER *p_m)
{
	return p_m->meas_last * p_m->beat_clock * p_m->beat_num;
}

u32 master_get_play_meas(MASTER *p_m)
{
	if(p_m->meas_last) return p_m->meas_last;
	else               return p_m->meas_num;
}

void master_adjust_meas_num(MASTER *p_m, u32 clock)
{
	u32 m_num;
	u32 b_num;

	b_num = (clock + p_m->beat_clock - 1) / p_m->beat_clock;
	m_num = (b_num + p_m->beat_num   - 1) / p_m->beat_num;

	if(p_m->meas_num    <= m_num        ) p_m->meas_num    = m_num;
	if(p_m->meas_repeat >= p_m->meas_num) p_m->meas_repeat = 0;
	if(p_m->meas_last   >  p_m->meas_num) p_m->meas_last   = p_m->meas_num;
}

/* -------------------------------------------------------------------------- */

size_t _MASTERSTRUCTSIZE = 15;

struct _MASTERSTRUCT {
	u16   beat_clock;   //  0:2
	u8    beat_num;     //  2:1
	float beat_tempo;   //  3:4
	u32   clock_repeat; //  7:4
	u32   clock_last;   // 11:4 -> 15byte
};

bool master_read(MASTER *p_master, DESCRIPTOR *p_desc)
{
	u32 size = 0;
	struct _MASTERSTRUCT m = {0};

	if(!desc_u32_r(p_desc, &size)) return false;

	if(!desc_u16_r(p_desc, &m.beat_clock  )) return false;
	if(!desc_u8_r (p_desc, &m.beat_num    )) return false;
	if(!desc_f32_r(p_desc, &m.beat_tempo  )) return false;
	if(!desc_u32_r(p_desc, &m.clock_repeat)) return false;
	if(!desc_u32_r(p_desc, &m.clock_last  )) return false;

	/* value check */
	if(size != _MASTERSTRUCTSIZE) return false;

	p_master->beat_clock   = m.beat_clock;
	p_master->beat_num     = m.beat_num;
	p_master->beat_tempo   = m.beat_tempo;

	p_master->meas_repeat  = m.clock_repeat / (m.beat_num * m.beat_clock);
	p_master->meas_last    = m.clock_last   / (m.beat_num * m.beat_clock);

	return true;
}

u32 master_read_event_num(DESCRIPTOR *p_desc)
{
	u32 size = 0;

	if(!desc_u32_r(p_desc, &size)) return 0;
	if(size != _MASTERSTRUCTSIZE) return 0;
	if(!desc_seek(p_desc, _MASTERSTRUCTSIZE, SEEK_CUR)) return 0;

	return 5;
}
