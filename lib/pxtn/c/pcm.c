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
#include "pcm.h"

/* -------------------------------------------------------------------------- */
bool pcm_alloc(PCM *p_pcm, u32 smp_num)
{
	if(!p_pcm) return false;
	if(!smp_num) return false;
	if(p_pcm->smps) return false;

	p_pcm->smps = calloc(smp_num * MPXTN_CH, sizeof(s16));
	return p_pcm->smps != NULL;
}

void pcm_free(PCM *p_pcm)
{
	if(!p_pcm) return;
	free(p_pcm->smps);

	p_pcm->smp_num = 0;
	p_pcm->smps = NULL;
}

/* -----------------------------------------------------------------------------
 * NOTE: if MPXTN_CH change to 1 from 2, this function not work correctly.
 */
static s16 *_adjust_ch_and_bps(const u8* p_buf, u32 size, u16 ch, u16 bps)
{
	s16* p_work = NULL;
	u32 smp_num = size / ch / (bps / 8);

	if(!p_buf) return NULL;

	p_work = calloc(smp_num * MPXTN_CH, sizeof(s16));
	if(!p_work) return NULL;

	if(ch == 1 && bps == 8) {
		for(u32 i = 0; i < smp_num; ++i) {
			s16 temp = p_buf[i];
			temp = (temp - 128) * 0x100;

			p_work[i * 2]     = temp;
			p_work[i * 2 + 1] = temp;
		}
	} else if(ch == 1 && bps == 16) {
		for(u32 i = 0; i < smp_num; ++i) {
			/* read as little endian */
			u16 temp;
			temp  =       p_buf[i * 2];
			temp |= ((u16)p_buf[i * 2 + 1] << 8);

			p_work[i * 2]     = *(s16*)&temp;
			p_work[i * 2 + 1] = *(s16*)&temp;
		}
	} else if(ch == 2 && bps == 8) {
		for(u32 i = 0; i < smp_num * 2; ++i) {
			s16 temp = p_buf[i];
			temp = (temp - 128) * 0x100;

			p_work[i] = temp;
		}
	} else if(ch == 2 && bps == 16) {
		for(u32 i = 0; i < smp_num * 2; ++i) {
			/* read as little endian */
			u16 temp;
			temp  =       p_buf[i * 2];
			temp |= ((u16)p_buf[i * 2 + 1] << 8);

			p_work[i] = *(s16*)&temp;
		}
	} else {
		/* nothing to do */
		free(p_work);
		return NULL;
	}

	return p_work;
}

static bool _adjust_sps(s16** p_buf, u32 sps, u32 *smp_num)
{
	if(!p_buf) return false;
	if(*smp_num == MPXTN_SPS) return true; /* nothing to do */

	s16* p_work = NULL;
	u32 new_smp_num = (u32)(((f64)*smp_num * MPXTN_SPS + sps - 1) / sps);
	p_work = calloc(new_smp_num * MPXTN_CH, sizeof(s16));
	if(!p_work) return false;

	f64 rate = (f64)sps / MPXTN_SPS;

	u32 *p_src = (u32*)*p_buf;
	u32 *p_dst = (u32*)p_work;
	for(u32 i = 0; i < new_smp_num; ++i) {
		u32 src_idx = (u32)(i * rate);
		p_dst[i] = p_src[src_idx];
	}

	/* replace buffer */
	free(*p_buf);
	*p_buf = p_work;
	*smp_num = new_smp_num;

	return true;
}

/* -------------------------------------------------------------------------- */
bool pcm_mem_read(PCM *p_pcm, const void *p, u32 size, u16 ch, u16 bps, u32 sps)
{
	if(!p_pcm) return false;
	if(!p) return false;

	/* check value */
	if(ch  != 1 && ch  !=  2) return false;
	if(bps != 8 && bps != 16) return false;
	if(sps == 0) return false;

	pcm_free(p_pcm);

	p_pcm->smp_num = size / ch / (bps / 8);

	p_pcm->smps = _adjust_ch_and_bps(p, size, ch, bps);
	if(!p_pcm->smps) return false;

	if(!_adjust_sps(&p_pcm->smps, sps, &p_pcm->smp_num)) {
		pcm_free(p_pcm);
		return false;
	}

	return true;
}

