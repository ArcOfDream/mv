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
#include "woice.h"

#include "ogg.h"
#include "pcm.h"
#include "ptn.h"
#include "ptv.h"
#include "oscillator.h"

/* -------------------------------------------------------------------------- */

static bool _woice_alloc(WOICE *p_woice, u32 size)
{
	bool ret = false;

	woice_free(p_woice);

	if(size > WOICEINSTANCE_MAX) return false;

	p_woice->insts = calloc(size, sizeof(WOICEINSTANCE));
	if(!p_woice->insts) goto End;

	p_woice->size = size;

	ret = true;
End:
	if(!ret) woice_free(p_woice);

	return ret;
}

void woice_free(WOICE *p_woice)
{
	if(!p_woice) return;

	if(p_woice->insts) {
		for(u32 i = 0; i < p_woice->size; ++i) {
			WOICEINSTANCE *p_wi = &p_woice->insts[i];
			free(p_wi->smps);
			free(p_wi->envs);
		}
	}
	free(p_woice->insts);

	/* cleanup */
	p_woice->insts = NULL;
	p_woice->size = 0;
}

/* -------------------------------------------------------------------------- */

static void _read_voiceflag(WOICEINSTANCE *p_wi, u32 flags)
{
	if(flags & VOICEFLAG_WAVELOOP) p_wi->waveloop = true;
	else                           p_wi->waveloop = false;
	if(flags & VOICEFLAG_SMOOTH)   p_wi->smooth   = true;
	else                           p_wi->smooth   = false;
	if(flags & VOICEFLAG_BEATFIT)  p_wi->beatfit  = true;
	else                           p_wi->beatfit  = false;
}

/* -------------------------------------------------------------------------- */

static const u32 _MATERIAL_PCMSIZE = 24;

struct _MATERIALSTRUCT_PCM
{
	u16 dc1        ; //  0:2 discon
	u16 basic_key  ; //  2:2
	u32 voice_flags; //  4:4
	u16 ch         ; //  8:2
	u16 bps        ; // 10:2
	u32 sps        ; // 12:4
	f32 tuning     ; // 16:4
	u32 size       ; // 20:4 -> 24byte
};

bool woice_read_matePCM(WOICE *p_woice, DESCRIPTOR *p_desc)
{
	struct _MATERIALSTRUCT_PCM m = {0};
	bool ret = false;
	void *p_buf = NULL;
	PCM  pcm = {0};
	u32  size;

	if(!desc_u32_r(p_desc, &size         )) goto End;
	if(!desc_u16_r(p_desc, &m.dc1        )) goto End;
	if(!desc_u16_r(p_desc, &m.basic_key  )) goto End;
	if(!desc_u32_r(p_desc, &m.voice_flags)) goto End;
	if(!desc_u16_r(p_desc, &m.ch         )) goto End;
	if(!desc_u16_r(p_desc, &m.bps        )) goto End;
	if(!desc_u32_r(p_desc, &m.sps        )) goto End;
	if(!desc_f32_r(p_desc, &m.tuning     )) goto End;
	if(!desc_u32_r(p_desc, &m.size       )) goto End;

	if(m.voice_flags & VOICEFLAG_UNCOVERED) goto End;

	if(!_woice_alloc(p_woice, 1)) goto End;

	{
		WOICEINSTANCE *p_wi = &p_woice->insts[0];

		p_woice->type = WOICE_PCM;

		p_wi->basic_key = m.basic_key;
		p_wi->tuning    = (f64)m.tuning;

		_read_voiceflag(p_wi, m.voice_flags);

		/* read data */
		p_buf = calloc(m.size, 1);
		if(!p_buf) goto End;

		if(!desc_dat_r(p_desc, p_buf, m.size)) goto End;

		/* convert */
		if(!pcm_mem_read(&pcm, p_buf, m.size, m.ch, m.bps, m.sps)) goto End;

		/* move sample data */
		p_wi->smp_num = pcm.smp_num;
		p_wi->smps = pcm.smps;
		pcm.smps = NULL;
	}

	ret = true;
End:
	pcm_free(&pcm);
	free(p_buf);

	if(!ret) woice_free(p_woice);

	return ret;
}

/* -------------------------------------------------------------------------- */

static const u32 _MATERIAL_PTNSIZE = 16;

struct _MATERIALSTRUCT_PTN
{
	u16 dc1;         //  0:2 discon
	u16 basic_key;   //  2:2
	u32 voice_flags; //  4:4
	f32 tuning;      //  8:4
	s32 rrr;         // 12:4 -> 16byte
};

bool woice_read_matePTN(WOICE *p_woice, DESCRIPTOR *p_desc)
{

	struct _MATERIALSTRUCT_PTN m = {0};
	bool ret = false;
	PTN ptn = {0};
	u32 size;

	if(!desc_u32_r(p_desc, &size         )) goto End;
	if(!desc_u16_r(p_desc, &m.dc1        )) goto End;
	if(!desc_u16_r(p_desc, &m.basic_key  )) goto End;
	if(!desc_u32_r(p_desc, &m.voice_flags)) goto End;
	if(!desc_f32_r(p_desc, &m.tuning     )) goto End;
	if(!desc_s32_r(p_desc, &m.rrr        )) goto End;

	/* TODO: check size... */

	if(m.rrr < 0 || m.rrr > 1) goto End;

	if(!_woice_alloc(p_woice, 1)) goto End;

	{
		WOICEINSTANCE *p_wi = &p_woice->insts[0];

		p_woice->type = WOICE_PTN;

		p_wi->basic_key = m.basic_key;
		p_wi->tuning    = (f64)m.tuning;

		_read_voiceflag(p_wi, m.voice_flags);

		/* read data */
		if(!ptn_read(&ptn, p_desc)) goto End;

		/* sample */
		p_wi->smp_num = ptn.smp_num;
		p_wi->smps = ptn_build(&ptn);
		if(p_wi->smps == NULL) goto End;
	}

	ret = true;
End:
	ptn_free(&ptn);

	if(!ret) woice_free(p_woice);

	return ret;
}

/* -------------------------------------------------------------------------- */

static bool _sample_ptv(WOICEINSTANCE *p_wi, const PTVINSTANCE *p_pi)
{
	f64  work, smp;
	s32  pan_volume[2] = {64, 64};
	bool overtone;
	OSCILLATOR osc;

	/* sample */
	p_wi->smp_num =  400;
	u32 size = p_wi->smp_num * MPXTN_CH;
	p_wi->smps = calloc(size, sizeof(s16));
	if(!p_wi->smps) return false;

	/* copy */
	p_wi->basic_key   = p_pi->basic_key;
	p_wi->tuning      = (f64)p_pi->tuning;

	_read_voiceflag(p_wi, p_pi->voice_flags);

	/* pan */
	if(p_pi->pan > 64) pan_volume[0] = 128 - p_pi->pan;
	if(p_pi->pan < 64) pan_volume[1] =       p_pi->pan;

	/* osci */
	osc.volume     = p_pi->volume;
	osc.smp_num    = p_wi->smp_num;
	osc.point_num  = p_pi->wav.size;
	osc.point_reso = p_pi->wav.reso;
	osc.points     = p_pi->wav.points;

	if(p_pi->type == PTV_Overtone) overtone = true;
	else                           overtone = false;

	for(u32 s = 0; s < p_wi->smp_num; ++s) {

		if(overtone) smp = oscillator_get_sample_overtone(&osc, s);
		else         smp = oscillator_get_sample_coodinate(&osc, s);

		for(u32 c = 0; c < MPXTN_CH; ++c)
		{
			work = smp * pan_volume[c] / 64;
			if(work >  1.0) work =  1.0;
			if(work < -1.0) work = -1.0;

			u32 idx = s * 2 + c;
			p_wi->smps[idx] = (s16)(work * INT16_MAX);
		}
	}

	return true;
}

static bool _envelope_ptv(WOICEINSTANCE *p_wi, const PTVINSTANCE *p_pi)
{

	bool ret = false;
	u32 e = 0;
	s32 size = 0;
	POINT *points = NULL;

	const PTVENVELOPE *p_env = &p_pi->env;

	if(p_env->head_num)
	{
		/* calc size */
		for(e = 0; e < p_env->head_num; ++e) size += p_env->points[e].x;
		u32 env_size = (u32)((f64)size * MPXTN_SPS / p_env->fps);
		if(env_size == 0) env_size = 1;

		/* alloc */
		p_wi->envs = calloc(env_size, 1);
		if(!p_wi->envs) goto End;
		p_wi->env_num = env_size;

		points = calloc(p_env->head_num, sizeof(POINT));
		if(!points) goto End;

		// convert points.
		s32 offset   = 0;
		u32 head_num = 0;
		for(e = 0; e < p_env->head_num; ++e) {

			if( !e || p_env->points[e].x || p_env->points[e].y ) {

				offset += (s32)((f64)p_env->points[e].x * MPXTN_SPS / p_env->fps);
				points[e].x = offset;
				points[e].y = p_env->points[e].y;
				head_num++;
			}
		}

		/* save env */
		POINT start;

		e = start.x = start.y = 0;

		for(u32 s = 0; s < p_wi->env_num; ++s) {

			while(e < head_num && s >= (u32)points[e].x ) {

				start.x = points[e].x;
				start.y = points[e].y;
				e++;
			}

			if(e < head_num) {

				p_wi->envs[s] = (u8)(start.y + (points[e].y - start.y) *
							       ((s32)s - start.x) /
							       (points[e].x - start.x));
			} else {

				p_wi->envs[s] = (u8)start.y;
			}
		}
	}

	if(p_env->tail_num) {
		p_wi->env_release = (s32)((f64)p_env->points[p_env->head_num].x * MPXTN_SPS / p_env->fps);
	} else {
		p_wi->env_release = 0;
	}

	ret = true;
End:
	free(points);

	return ret;
}

/* -------------------------------------------------------------------------- */

static const u32 _MATERIAL_PTVSIZE = 12;

struct _MATERIALSTRUCT_PTV
{
	u16 dc1;  // 0:2 discon
	u16 rrr;  // 2:2
	f32 dc2;  // 4:4 discon
	u32 size; // 8:4 -> 12byte
};

bool woice_read_matePTV(WOICE *p_woice, DESCRIPTOR *p_desc)
{
	bool ret = false;
	PTV ptv = {0};
	u32 size = 0;
	struct _MATERIALSTRUCT_PTV m = {0};

	if(!desc_u32_r(p_desc, &size  )) goto End;
	if(!desc_u16_r(p_desc, &m.dc1 )) goto End;
	if(!desc_u16_r(p_desc, &m.rrr )) goto End;
	if(!desc_f32_r(p_desc, &m.dc2 )) goto End;
	if(!desc_u32_r(p_desc, &m.size)) goto End;

	/* size check */
	if(size != m.size + _MATERIAL_PTVSIZE) goto End;

	if(m.rrr) goto End;

	/* read ptv */
	if(!ptv_read(&ptv, p_desc)) goto End;

	/* woice alloc */
	if(!_woice_alloc(p_woice, ptv.size)) goto End;

	for(u32 i = 0; i < p_woice->size; ++i) {
		/* sample */
		if(!_sample_ptv  (&p_woice->insts[i], &ptv.insts[i])) goto End;
		/* envelope */
		if(!_envelope_ptv(&p_woice->insts[i], &ptv.insts[i])) goto End;
	}

	ret = true;
End:
	ptv_free(&ptv);

	if(!ret) woice_free(p_woice);

	return ret;
}

/* -------------------------------------------------------------------------- */

#ifdef MPXTN_OGGVORBIS

static const u32 _MATERIAL_OGGSIZE = 12;

struct _MATERIALSTRUCT_OGG
{
	u16 xxx;         // 0:2 discon
	u16 basic_key;   // 2:2
	u32 voice_flags; // 4:4
	f32 tuning;      // 8:4 -> 12byte
};

bool woice_read_mateOGGV(WOICE *p_woice, DESCRIPTOR *p_desc)
{
	bool ret = false;
	OGG ogg = {0};
	PCM pcm = {0};
	u32 size;
	struct _MATERIALSTRUCT_OGG m = {0};

	if(!desc_u32_r(p_desc, &size         )) goto End;
	if(!desc_u16_r(p_desc, &m.xxx        )) goto End;
	if(!desc_u16_r(p_desc, &m.basic_key  )) goto End;
	if(!desc_u32_r(p_desc, &m.voice_flags)) goto End;
	if(!desc_f32_r(p_desc, &m.tuning     )) goto End;

	if(m.voice_flags & VOICEFLAG_UNCOVERED) goto End;

	if(!_woice_alloc(p_woice, 1)) goto End;

	{
		WOICEINSTANCE *p_wi = &p_woice->insts[0];

		p_woice->type = WOICE_OGGV;

		p_wi->basic_key = m.basic_key;
		p_wi->tuning    = (f64)m.tuning;

		_read_voiceflag(p_wi, m.voice_flags);

		/* read data */
		if(!ogg_read(&ogg, p_desc)) goto End;

		/* convert */
		if(!pcm_mem_read(&pcm, ogg.p_data, ogg.size, ogg.ch, 16, ogg.sps)) goto End;

		/* move sample data */
		p_wi->smp_num = pcm.smp_num;
		p_wi->smps = pcm.smps;
		pcm.smps = NULL;
	}

	ret = true;
End:
	ogg_free(&ogg);
	pcm_free(&pcm);

	if(!ret) woice_free(p_woice);

	return ret;
}

#endif
