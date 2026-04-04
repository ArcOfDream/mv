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
#include "oscillator.h"

const static f64 _pi = 3.1415926535897932;

f64 oscillator_get_sample_overtone(OSCILLATOR *p_osci, s32 idx)
{
	f64 work = 0;
	f64 sss = 0;

	for(s32 i = 0; i < p_osci->point_num; ++i) {
		const POINT *p = &p_osci->points[i];
		sss = 2.0 * _pi * p->x * idx / p_osci->smp_num;
		work += sin(sss) * p->y / p->x / 128.0;
	}

	work = work * p_osci->volume / 128.0;
	return work;

}

f64 oscillator_get_sample_coodinate(OSCILLATOR *p_osci, s32 idx)
{
	s32 i;
	s32 x1, y1, x2, y2;
	s32 w, h;
	s32 c;
	f64 work;

	i = p_osci->point_reso * idx / p_osci->smp_num;

	// find target 2 ponits
	for(c = 0; c < p_osci->point_num; ++c) {
		if(p_osci->points[c].x > i) break;
	}

	/* end */
	if(c == p_osci->point_num)
	{
		x1 = p_osci->points[c - 1].x;
		y1 = p_osci->points[c - 1].y;
		x2 = p_osci->point_reso;
		y2 = p_osci->points[0].y;
	}
	else
	{
		if(c){
			x1 = p_osci->points[c - 1].x;
			y1 = p_osci->points[c - 1].y;
			x2 = p_osci->points[c].x;
			y2 = p_osci->points[c].y;
		} else {
			x1 = p_osci->points[0].x;
			y1 = p_osci->points[0].y;
			x2 = p_osci->points[0].x;
			y2 = p_osci->points[0].y;
		}
	}

	w = x2 - x1;
	i =  i - x1;
	h = y2 - y1;

	if(i) work = y1 + (f64)h * i / w;
	else  work = y1;

	return work * p_osci->volume / 128.0 / 128.0;
}

