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
#include "overdrive.h"

void overdrive_tone_supple(OVERDRIVE *p_ovdrv, s32 *group_smps)
{
	if(!p_ovdrv->played) return;
	s32 a = group_smps[p_ovdrv->group];
	if(a >  p_ovdrv->cut) a =  p_ovdrv->cut;
	if(a < -p_ovdrv->cut) a = -p_ovdrv->cut;
	group_smps[p_ovdrv->group] = a * p_ovdrv->amp; /* TODO: float calc -> int calc */
}

/* -------------------------------------------------------------------------- */

static float _OVERDRIVE_CUT_MAX      = 99.9f;
static float _OVERDRIVE_CUT_MIN      = 50.0f;
static float _OVERDRIVE_AMP_MAX      =  8.0f;
static float _OVERDRIVE_AMP_MIN      =  0.1f;

static size_t _OVERDRIVESIZE = 16;

struct _OVERDRIVESTRUCT
{
	u16   xxx  ; //  0:2
	u16   group; //  2:2
	float cut  ; //  4:4
	float amp  ; //  8:4
	u32   yyy  ; // 12:4 -> 16byte
};

bool overdrive_read(OVERDRIVE *p_ovdrv, DESCRIPTOR *p_desc)
{
	u32 size;
	struct _OVERDRIVESTRUCT o;

	if(!desc_u32_r(p_desc, &size   )) return false;
	if(!desc_u16_r(p_desc, &o.xxx  )) return false;
	if(!desc_u16_r(p_desc, &o.group)) return false;
	if(!desc_f32_r(p_desc, &o.cut  )) return false;
	if(!desc_f32_r(p_desc, &o.amp  )) return false;
	if(!desc_u32_r(p_desc, &o.yyy  )) return false;

	/* check */
	if(size != _OVERDRIVESIZE) return false;
	if(o.xxx) return false;
	if(o.yyy) return false;
	if(o.cut > _OVERDRIVE_CUT_MAX || o.cut < _OVERDRIVE_CUT_MIN) return false;
	if(o.amp > _OVERDRIVE_AMP_MAX || o.amp < _OVERDRIVE_AMP_MIN) return false;
	if(o.group > GROUP_MAX) return false;

	p_ovdrv->amp = o.amp;
	p_ovdrv->cut = (INT16_MAX * (100.0f - o.cut) / 100.0f);
	p_ovdrv->group = o.group;

	return true;
}
