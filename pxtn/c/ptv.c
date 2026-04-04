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

#include "ptv.h"

static const char _code[] = "PTVOICE-";
static const u32  _ver    =  20060111; // support no-envelope


/* -------------------------------------------------------------------------- */

static bool _ptv_alloc(PTV *p_ptv, u32 size) {

	bool ret = false;

	p_ptv->insts = calloc(size, sizeof(PTVINSTANCE));
	if(!p_ptv->insts) goto End;
	p_ptv->size = size;

	for(u32 i = 0; i < p_ptv->size; ++i) {

		/* set non-zero default value */
		PTVINSTANCE *pi = &p_ptv->insts[i];
		pi->basic_key   = EVENTDEFAULT_BASICKEY;
		pi->volume      = 128;
		pi->pan         = 64;
		pi->tuning      = 1.0f;
		pi->voice_flags = VOICEFLAG_SMOOTH;
		pi->data_flags  = PTV_DATAFLAG_WAVE;
		pi->wav.points  = NULL;
		pi->env.points  = NULL;
	}

	ret = true;
End:
	if(!ret) ptv_free(p_ptv);

	return ret;
}

void ptv_free(PTV *p_ptv) {

	if(!p_ptv) return;
	if(!p_ptv->insts) return;

	for(u32 i = 0; i < p_ptv->size; ++i) {
		PTVINSTANCE *pi = &p_ptv->insts[i];
		free(pi->wav.points);
		free(pi->env.points);
	}

	free(p_ptv->insts);
	p_ptv->size = 0;
	p_ptv->insts = NULL;
}

/* -------------------------------------------------------------------------- */

static bool _read_wave(PTVINSTANCE *p_pi, DESCRIPTOR *p_desc)
{
	s8 sc;
	u8 uc;
	u32 type;

	if(!desc_u32_vr(p_desc, &type)) return false;

	p_pi->type = type;

	switch(p_pi->type) {

	case PTV_Coodinate:

		if(!desc_u32_vr(p_desc, &p_pi->wav.size)) return false;
		if(!desc_u32_vr(p_desc, &p_pi->wav.reso)) return false;

		/* alloc */
		p_pi->wav.points = calloc(p_pi->wav.size, sizeof(POINT));
		if(!p_pi->wav.points) return false;

		for(u32 i = 0; i < p_pi->wav.size; ++i) {

			POINT *p = &p_pi->wav.points[i];

			if(!desc_u8_r(p_desc, &uc)) return false; p->x = uc;
			if(!desc_s8_r(p_desc, &sc)) return false; p->y = sc;
		}
		break;

	case PTV_Overtone:

		if(!desc_u32_vr(p_desc, &p_pi->wav.size)) return false;

		/* alloc */
		p_pi->wav.points = calloc(p_pi->wav.size, sizeof(POINT));
		if(!p_pi->wav.points) return false;

		for(u32 i = 0; i < p_pi->wav.size; ++i) {

			POINT *p = &p_pi->wav.points[i];

			if(!desc_s32_vr(p_desc, &p->x)) return false;
			if(!desc_s32_vr(p_desc, &p->y)) return false;
		}
		break;

	case PTV_Sampling: return false; // un-support
#if 0
	{
		u32 ch;
		u32 bps;
		u32 sps;
		u32 smp_head;
		u32 smp_body;
		u32 smp_tail;
		u32 size;
		u8 *smps = NULL;

		if(!desc_u32_vr(p_desc, &ch      )) return false;
		if(!desc_u32_vr(p_desc, &bps     )) return false;
		if(!desc_u32_vr(p_desc, &sps     )) return false;
		if(!desc_u32_vr(p_desc, &smp_head)) return false;
		if(!desc_u32_vr(p_desc, &smp_body)) return false;
		if(!desc_u32_vr(p_desc, &smp_tail)) return false;

		size = (smp_head + smp_body + smp_tail) * ch * bps / 8;
		smps = calloc(size, sizeof(u8));
		if(!smps) return false;
		if(!desc_dat_r(p_desc, smps, size)) {
			free(smps);
			return false;
		}
		break;
	}
#endif
	default: return false; // un-support
	}

	return true;
}

static bool _read_envelope(PTVINSTANCE *p_pi, DESCRIPTOR *p_desc)
{
	u32 size;

	if(!desc_u32_vr(p_desc, &p_pi->env.fps     )) return false;
	if(!desc_u32_vr(p_desc, &p_pi->env.head_num)) return false;
	if(!desc_u32_vr(p_desc, &p_pi->env.body_num)) return false;
	if(!desc_u32_vr(p_desc, &p_pi->env.tail_num)) return false;

	/* check */
	if(p_pi->env.body_num) return false;
	if(p_pi->env.tail_num != 1) return false;

	/* alloc */
	size = p_pi->env.head_num + p_pi->env.body_num + p_pi->env.tail_num;
	p_pi->env.points = calloc(size, sizeof(POINT));
	if(!p_pi->env.points) return false;

	for(u32 i = 0; i < size; ++i)
	{
		POINT *p = &p_pi->env.points[i];

		if(!desc_s32_vr(p_desc, &p->x)) return false;
		if(!desc_s32_vr(p_desc, &p->y)) return false;
	}

	return true;
}

bool ptv_read(PTV *p_ptv, DESCRIPTOR *p_desc)
{
	bool ret   = false;
	u32  work  = 0;
	u32  total = 0;
	u32  ver   = 0;

	char code[8] = {0};

	/* check code */
	if(!desc_dat_r(p_desc, code, 8)) goto End;
	if( memcmp(code, _code, 8)) goto End;

	/* check version */
	if(!desc_u32_r(p_desc, &ver)) goto End;
	if(ver > _ver) goto End;

	/* read total size */
	if(!desc_u32_r(p_desc, &total)) goto End;

	/* skip non-use value */
	if(!desc_u32_vr(p_desc, &work)) goto End;
	if(!desc_u32_vr(p_desc, &work)) goto End;
	if(!desc_u32_vr(p_desc, &work)) goto End;

	/* read size & alloc */
	if(!desc_u32_vr(p_desc, &p_ptv->size)) goto End;
	if(p_ptv->size > WOICEINSTANCE_MAX) goto End;
	if(!_ptv_alloc(p_ptv, p_ptv->size)) goto End;

	for(u32 i = 0; i < p_ptv->size; ++i)
	{
		PTVINSTANCE *p_pi = &p_ptv->insts[i];

		if(!desc_s32_vr(p_desc, &p_pi->basic_key  )) goto End;
		if(!desc_u32_vr(p_desc, &p_pi->volume     )) goto End;
		if(!desc_s32_vr(p_desc, &p_pi->pan        )) goto End;
		if(!desc_f32_vr(p_desc, &p_pi->tuning     )) goto End;
		if(!desc_u32_vr(p_desc, &p_pi->voice_flags)) goto End;
		if(!desc_u32_vr(p_desc, &p_pi->data_flags )) goto End;

		/* unknown flag set... */
		if(p_pi->voice_flags & VOICEFLAG_UNCOVERED) goto End;
		if(p_pi->data_flags  & PTV_DATAFLAG_UNCOVERED ) goto End;

		/* read wave/envelope */
		if(p_pi->data_flags & PTV_DATAFLAG_WAVE    ){ if(!_read_wave    (p_pi, p_desc)) goto End; }
		if(p_pi->data_flags & PTV_DATAFLAG_ENVELOPE){ if(!_read_envelope(p_pi, p_desc)) goto End; }
	}

	ret = true;
End:
	if(!ret) ptv_free(p_ptv);
	return ret;
}

