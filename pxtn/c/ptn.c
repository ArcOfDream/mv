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

#include "ptn.h"

#include "freq.h"

static const char _code[] = "PTNOISE-";
static const u32  _ver    =  20120418; // 16 wave types.

#define KEY_TOP           0x3200   //  40 key

#define BASIC_FREQUENCY      100.0 // 100 Hz
#define BASIC_SMPS           441
#define BASIC_RANDSMPS     44100

#define EDITFLAG_ENVELOPE  0x00000004u
#define EDITFLAG_PAN       0x00000008u
#define EDITFLAG_OSC_MAIN  0x00000010u
#define EDITFLAG_OSC_FREQ  0x00000020u
#define EDITFLAG_OSC_VOLU  0x00000040u

#define EDITFLAG_UNCOVERED 0xffffff83u

extern PTN_TABLE ptn_tables[];

typedef enum
{
	_RANDOM_None = 0,
	_RANDOM_Saw     ,
	_RANDOM_Rect    ,
} _RANDOMTYPE;

typedef struct
{
	f64         increment ;
	f64         offset    ;
	f64         volume    ;
	const s16*  smps      ;
	bool        reverse   ;
	_RANDOMTYPE rnd_type  ;
	s32         rnd_start ;
	s32         rnd_margin;
	u32         rnd_index ;
} _OSCILLATOR;

typedef struct
{
	u32 smp;
	f64 mag;
} _POINT;

typedef struct
{
	bool enable;
	f64  pan[2];
	u32  env_index;
	f64  env_mag_start;
	f64  env_mag_margin;
	u32  env_count;
	u32  env_num;
	_POINT *envs;

	_OSCILLATOR main;
	_OSCILLATOR freq;
	_OSCILLATOR volu;
} _UNIT;

/* -------------------------------------------------------------------------- */

static void _units_free(_UNIT *units, u8 size)
{
	if(!units) return;

	for(u8 i = 0; i < size; ++i) {
		if(!units[i].envs) continue;
		free(units[i].envs);
		units[i].envs = NULL;
	}
}

void ptn_free(PTN *p_ptn)
{
	if(!p_ptn) return;

	if(!p_ptn->units) return;

	for(u32 i = 0; i < p_ptn->size; ++i) {
		free(p_ptn->units[i].envs);
	}
	free(p_ptn->units);

	/* clear value */
	p_ptn->smp_num = 0;
	p_ptn->size = 0;
	p_ptn->units = NULL;
}

/* -------------------------------------------------------------------------- */

static void _set_osc(_OSCILLATOR *p_dst, const NOISEDESIGN_OSCILLATOR *p_src)
{
	switch(p_src->type)
	{
	case WAVETYPE_Random : p_dst->rnd_type = _RANDOM_Saw ; break;
	case WAVETYPE_Random2: p_dst->rnd_type = _RANDOM_Rect; break;
	default              : p_dst->rnd_type = _RANDOM_None; break;
	}

	p_dst->increment = (f64)p_src->freq / BASIC_FREQUENCY;

	// offset
	if( p_dst->rnd_type != _RANDOM_None ) p_dst->offset = 0;
	else                                  p_dst->offset = (f64)BASIC_SMPS * p_src->offset / 100.0;

	p_dst->volume  = p_src->volume / 100.0;
	p_dst->smps    = ptn_tables[p_src->type].data;
	p_dst->reverse = p_src->reverse;

	p_dst->rnd_start = 0;
	p_dst->rnd_index = BASIC_RANDSMPS * (p_src->offset / 100.0);
	p_dst->rnd_margin = ptn_tables[WAVETYPE_Random].data[p_dst->rnd_index];
}

static void _inc_osc(_OSCILLATOR *p_o, f64 increment)
{
	p_o->offset += increment;
	if(p_o->offset > BASIC_SMPS)
	{
		p_o->offset -= BASIC_SMPS;
		if(p_o->offset >= BASIC_SMPS) p_o->offset = 0;

		if(p_o->rnd_type != _RANDOM_None)
		{
			const s16 *p = ptn_tables[WAVETYPE_Random].data;

			p_o->rnd_start  = p[p_o->rnd_index];
			p_o->rnd_index++;
			if( p_o->rnd_index >= BASIC_RANDSMPS ) p_o->rnd_index = 0;
			p_o->rnd_margin = p[p_o->rnd_index] - p_o->rnd_start;
		}
	}
}

/* -------------------------------------------------------------------------- */

static void _ptn_fix(PTN *p_ptn)
{
}

/* -------------------------------------------------------------------------- */
s16 *ptn_build(PTN *p_ptn)
{
	u32  offset   = 0;
	f64  work     = 0;
	f64  vol      = 0;
	f64  fre      = 0;
	f64  store    = 0;
	s32  byte4    = 0;
	s16 *p        = NULL;
	s16  *smps    = NULL;
	_UNIT *units  = NULL;

	if(!p_ptn) goto End;
	if(!p_ptn->size) goto End;
	if(!p_ptn->smp_num) goto End;

	/* alloc */
	units = calloc(p_ptn->size, sizeof(_UNIT));
	if(!units) goto End;
	smps = calloc(p_ptn->smp_num * MPXTN_CH, sizeof(s16));
	if(!smps) goto End;
	p = smps;

	_ptn_fix(p_ptn);

	/* DESIGNUNIT -> _UNIT */
	for(u8 i = 0; i < p_ptn->size; ++i)
	{
		_UNIT *p_u = &units[i];
		const NOISEDESIGN_UNIT *p_du = &p_ptn->units[i];

		p_u->enable = p_du->enable;

		if(p_du->pan == 0) {

			p_u->pan[0] = 1.0;
			p_u->pan[1] = 1.0;

		} else if(p_du->pan < 0) {

			p_u->pan[0] = 1.0;
			p_u->pan[1] = (100.0 + p_du->pan) / 100.0;

		} else {

			p_u->pan[1] = 1.0;
			p_u->pan[0] = (100.0 - p_du->pan) / 100.0;
		}

		/* envelope */
		p_u->envs = calloc(p_du->env_num, sizeof(_POINT));
		if(!p_u->envs) goto End;
		p_u->env_num = p_du->env_num;

		for(u32 e = 0; e < p_du->env_num; ++e) {

			p_u->envs[e].smp = (u32)MPXTN_SPS * (u32)p_du->envs[e].x / 1000;
			p_u->envs[e].mag = p_du->envs[e].y / 100.0;
		}

		p_u->env_index      = 0;
		p_u->env_mag_start  = 0;
		p_u->env_mag_margin = 0;
		p_u->env_count      = 0;
		while(p_u->env_index < p_u->env_num) {

			p_u->env_mag_margin = p_u->envs[p_u->env_index].mag - p_u->env_mag_start;
			if(p_u->envs[p_u->env_index].smp) break;
			p_u->env_mag_start = p_u->envs[p_u->env_index].mag;
			p_u->env_index++;
		}

		_set_osc(&p_u->main, &p_du->main);
		_set_osc(&p_u->freq, &p_du->freq);
		_set_osc(&p_u->volu, &p_du->volu);
	}

	for(u32 s = 0; s < p_ptn->smp_num; ++s) {

		for(u32 c = 0; c < MPXTN_CH; ++c) {

			store = 0;

			for(u8 i = 0; i < p_ptn->size; ++i) {

				const _UNIT *p_u = &units[i];

				if(!p_u->enable) continue;

				// main
				{
				const _OSCILLATOR *p_o = &p_u->main;
				switch(p_o->rnd_type)
				{
				case _RANDOM_None:
					offset = (u32)p_o->offset;
					work = p_o->smps[offset];
					break;
				case _RANDOM_Saw:
					if(p_o->offset >= 0) work = p_o->rnd_start + p_o->rnd_margin * p_o->offset / BASIC_SMPS;
					else                 work = 0;
					break;
				case _RANDOM_Rect:
					if( p_o->offset >= 0 ) work = p_o->rnd_start;
					else                 work = 0;
					break;
				}
				if(p_o->reverse) work *= -1;
				work *= p_o->volume;
				}

				// volu
				{
				const _OSCILLATOR *p_o = &p_u->volu;
				switch(p_o->rnd_type)
				{
				case _RANDOM_None:
					offset = (u32)p_o->offset;
					vol    = p_o->smps[offset];
					break;
				case _RANDOM_Saw:
					vol = p_o->rnd_start + p_o->rnd_margin * p_o->offset / BASIC_SMPS;
					break;
				case _RANDOM_Rect:
					vol = p_o->rnd_start;
					break;
				}
				if( p_o->reverse ) vol *= -1;
				vol *= p_o->volume;

				work = work * (vol + INT16_MAX) / (INT16_MAX * 2);
				work = work * p_u->pan[c];
				}
				// envelope
				if(p_u->env_index < p_u->env_num)
					work *= p_u->env_mag_start + (p_u->env_mag_margin * p_u->env_count / p_u->envs[p_u->env_index].smp);
				else
					work *= p_u->env_mag_start;
				store += work;
			}

			byte4 = (s32)store;
			if(byte4 >   INT16_MAX) byte4 =   INT16_MAX;
			if(byte4 < - INT16_MAX) byte4 = - INT16_MAX;

			*(p++) = (s16)byte4;
		}

		// increment
		for(u8 i = 0; i < p_ptn->size; ++i) {

			_UNIT *p_u = &units[i];

			if(!p_u->enable) continue;

			const _OSCILLATOR *p_o = &p_u->freq;

			switch(p_o->rnd_type)
			{
			case _RANDOM_None:
				offset = (u32)p_o->offset;
				fre    = (f64)KEY_TOP * p_o->smps[offset] / INT16_MAX;
				break;
			case _RANDOM_Saw:
				fre = p_o->rnd_start + p_o->rnd_margin * p_o->offset / BASIC_SMPS;
				break;
			case _RANDOM_Rect:
				fre = p_o->rnd_start;
				break;
			}

			if(p_o->reverse) fre *= -1;
			fre *= p_o->volume;

			_inc_osc(&p_u->main, p_u->main.increment * freq_get((u32)fre));
			_inc_osc(&p_u->freq, p_u->freq.increment);
			_inc_osc(&p_u->volu, p_u->volu.increment);

			// envelope
			if(p_u->env_index < p_u->env_num) {

				p_u->env_count++;

				if(p_u->env_count >= p_u->envs[p_u->env_index].smp) {

					p_u->env_count      = 0;
					p_u->env_mag_start  = p_u->envs[p_u->env_index].mag;
					p_u->env_mag_margin = 0;
					p_u->env_index++;

					while(p_u->env_index < p_u->env_num) {

						p_u->env_mag_margin = p_u->envs[p_u->env_index].mag - p_u->env_mag_start;
						if(p_u->envs[p_u->env_index].smp) break;
						p_u->env_mag_start  = p_u->envs[p_u->env_index].mag;
						p_u->env_index++;
					}
				}
			}
		}
	}
End:
	if(units) {
		_units_free(units, p_ptn->size);
		free(units);
	}

	return smps;
}

/* -------------------------------------------------------------------------- */
static bool _read_osc(NOISEDESIGN_OSCILLATOR *p_osc, DESCRIPTOR *p_desc)
{
	u32 work;

	if(!desc_u32_vr(p_desc, &work)) return false; p_osc->type    = (WAVETYPE)work;
	if(p_osc->type >= WAVETYPE_num) return false;
	if(!desc_u32_vr(p_desc, &work)) return false; p_osc->reverse = work ? true : false;
	if(!desc_u32_vr(p_desc, &work)) return false; p_osc->freq    = work / 10.0f;
	if(!desc_u32_vr(p_desc, &work)) return false; p_osc->volume  = work / 10.0f;
	if(!desc_u32_vr(p_desc, &work)) return false; p_osc->offset  = work / 10.0f;

	return true;
}

bool ptn_read(PTN *p_ptn, DESCRIPTOR *p_desc)
{
	bool ret   = false;
	u32  flags = 0;
	u32  ver   = 0;

	char code[8] = {0};

	ptn_free(p_ptn);

	/* check code */
	if(!desc_dat_r(p_desc, code, 8)) goto End;
	if(memcmp(code, _code, 8)) goto End;

	/* check version */
	if(!desc_u32_r(p_desc, &ver)) goto End;
	if(ver > _ver) goto End;

	if(!desc_u32_vr(p_desc, &p_ptn->smp_num)) goto End;
	if(!desc_u8_r(p_desc, &p_ptn->size     )) goto End;
	if(p_ptn->size > NOISEUNIT_MAX) goto End;

	/* allocate units */
	p_ptn->units = calloc(p_ptn->size, sizeof(NOISEDESIGN_UNIT));
	if(!p_ptn->units) goto End;

	for(u8 i = 0; i < p_ptn->size; ++i)
	{
		NOISEDESIGN_UNIT *nu = &p_ptn->units[i];
		nu->enable = true;

		if(!desc_u32_vr(p_desc, &flags)) goto End;

		if(flags & EDITFLAG_UNCOVERED) goto End;

		if(flags & EDITFLAG_ENVELOPE)
		{
			if(!desc_u32_vr(p_desc, &nu->env_num)) goto End;
			if(nu->env_num > NOISEENVELOPE_MAX) goto End;

			/* allocate envelope */
			nu->envs = calloc(nu->env_num, sizeof(POINT));
			if(!nu->envs) goto End;

			for(u32 e = 0; e < nu->env_num; ++e)
			{
				if(!desc_s32_vr(p_desc, &nu->envs[e].x)) goto End;
				if(!desc_s32_vr(p_desc, &nu->envs[e].y)) goto End;
			}
		}

		if(flags & EDITFLAG_PAN)
		{
			if(!desc_s8_r(p_desc, &nu->pan)) goto End;
		}

		if(flags & EDITFLAG_OSC_MAIN) { if(!_read_osc(&nu->main, p_desc)) goto End; }
		if(flags & EDITFLAG_OSC_FREQ) { if(!_read_osc(&nu->freq, p_desc)) goto End; }
		if(flags & EDITFLAG_OSC_VOLU) { if(!_read_osc(&nu->volu, p_desc)) goto End; }
	}

	ret = true;
End:
	if(!ret) ptn_free(p_ptn);

	return ret;
}


