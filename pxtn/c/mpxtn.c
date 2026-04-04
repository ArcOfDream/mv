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
#include "mpxtn.h"

#include "common.h"

#include "descriptor.h"
#include "freq.h"
#include "service.h"

struct _MPXTN {
	bool end_vomit;
	bool loop;

	u32 beat_num;
	u32 beat_clock;
	f64 beat_tempo;

	u32 meas_repeat;
	u32 meas_end;

	f64 smp_per_clk;

	u32 smp_repeat;
	u32 smp_end;
	u32 smp_count;
	s32 smp_smooth;

	u32 time_pan_idx;
	s32 top;

	s32 clock;

	const EVERECORD *p_eve;

	SERVICE srv;

	s16 smp_data[2];
	s32 group_smps[GROUP_MAX];
};

/* -------------------------------------------------------------------------- */

static bool _prepare(MPXTN *mp);
static bool _reset_voice_on(MPXTN *mp, UNIT *p_u, s32 idx);
static bool _init_unit_tone(MPXTN *mp);

/* -------------------------------------------------------------------------- */

static bool _prepare(MPXTN *mp)
{
	if(!mp) return false;
	if(!mp->srv.valid) return false;

	mp->end_vomit = false;
	mp->loop = false;

	/* save freq used value */
	mp->beat_num   = mp->srv.master.beat_num;
	mp->beat_clock = mp->srv.master.beat_clock;
	mp->beat_tempo = (f64)mp->srv.master.beat_tempo;

	mp->meas_repeat = mp->srv.master.meas_repeat;
	mp->meas_end    = master_get_play_meas(&mp->srv.master);

	u32 clk_per_meas   = mp->beat_clock * mp->beat_num;
	u32 clk_per_minute = (u32)(mp->beat_tempo * mp->beat_clock);

	u32 clk_repeat = mp->meas_repeat * clk_per_meas;
	u32 clk_end    = mp->meas_end    * clk_per_meas;

	mp->smp_per_clk = 60.0 * MPXTN_SPS / clk_per_minute;

	mp->smp_repeat = (u32)(clk_repeat * mp->smp_per_clk);
	mp->smp_end    = (u32)(clk_end    * mp->smp_per_clk);

	mp->time_pan_idx = 0;

	mp->smp_count  = 0;
	mp->smp_smooth = MPXTN_SPS / 250; /* 4ms */

	mp->p_eve = evelist_get_records(&mp->srv.evels);
	mp->top = INT16_MAX;

	/* ready tones */
	for(u32 i = 0; i < mp->srv.delay_num; ++i) {
		delay_tone_ready(&mp->srv.delays[i], mp->beat_num, mp->beat_tempo);
	}


	if(!_init_unit_tone(mp)) return false;

	return true;
}

/* -------------------------------------------------------------------------- */

static MPXTN *_common_read(DESCRIPTOR *p_desc, int *err)
{
	MPXTN *mp;
	mpxtn_err_t ret = MPXTN_NOERR;

	mp = calloc(1, sizeof(MPXTN));
	if(!mp) {
		ret = MPXTN_ENOMEM;
		goto End;
	}

	ret = service_read(&mp->srv, p_desc);
	if(ret != MPXTN_NOERR) goto End;

	if(!_prepare(mp)) {
		ret = MPXTN_EPREPARE;
		goto End;
	}

End:
	if(ret != MPXTN_NOERR) {
		mpxtn_close(mp);
		return NULL;
	}

	if(err) *err = ret;
	return mp;
}

MPXTN_API MPXTN *mpxtn_fread(FILE *fp, int *err)
{
	s32 ret = MPXTN_NOERR;
	DESCRIPTOR desc;

	ret = desc_set_file(&desc, fp);

	if(ret != MPXTN_NOERR) {
		if(err) *err = ret;
		return NULL;
	}

	return _common_read(&desc, err);
}

MPXTN_API MPXTN *mpxtn_mread(const void *p, size_t size, int *err)
{
	s32 ret = MPXTN_NOERR;
	DESCRIPTOR desc;

	ret = desc_set_memory(&desc, p, size);

	if(ret != MPXTN_NOERR) {
		if(err) *err = ret;
		return NULL;
	}

	return _common_read(&desc, err);
}

/* -------------------------------------------------------------------------- */

MPXTN_API void mpxtn_close(MPXTN *mp)
{
	if(!mp) return;
	service_free(&mp->srv);
	free(mp);
}

/* -------------------------------------------------------------------------- */

static bool _reset_voice_on(MPXTN *mp, UNIT *p_u, s32 idx)
{
	if(idx < 0) return false;
	if((u32)idx >= mp->srv.woice_num) return false;

	WOICE *p_w = &mp->srv.woices[idx];
	unit_set_woice(p_u, p_w);

	for(u32 i = 0; i < p_w->size; ++i) {

		const WOICEINSTANCE *p_wi = &p_w->insts[i];

		f64 ofs_freq = 0;

		if(p_wi->beatfit) {
			ofs_freq = p_wi->smp_num * mp->beat_tempo / (MPXTN_SPS * 60 * p_wi->tuning);
		} else {
			ofs_freq = freq_get(EVENTDEFAULT_BASICKEY - p_wi->basic_key) * p_wi->tuning;
		}

		unit_tone_reset_and_2prm(p_u, i, (s32)(p_wi->env_release / mp->smp_per_clk), ofs_freq);
	}

	return true;
}


static bool _init_unit_tone(MPXTN *mp)
{
	if(!mp) return false;
	if(!mp->srv.valid) return false;

	for(u32 i = 0; i < mp->srv.unit_num; ++i) {
		UNIT *p_u = &mp->srv.units[i];
		unit_tone_init(p_u);
		if(!_reset_voice_on(mp, p_u, 0)) return false;
	}

	return true;
}

inline static void _proc_event_on(MPXTN *mp, UNIT *p_u, const EVERECORD *p_eve)
{

	UNITTONE*            p_ut;
	const WOICE*         p_w;
	const WOICEINSTANCE* p_wi;

	s32 on_count = (s32)((p_eve->clock + p_eve->value - mp->clock) * mp->smp_per_clk);

	if(on_count <= 0){ unit_tone_zerolives(p_u); return; }

	unit_tone_keyon(p_u);

	if((p_w = p_u->p_woice) == NULL) return;

	for(u32 v = 0; v < p_w->size; v++) {

		p_ut = &p_u->uts[v];
		p_wi = &p_w->insts[v];

		if(p_wi->env_release) {

			/* release */
			s32 max_life_count1 = on_count + p_wi->env_release;
			s32 max_life_count2;

			s32 c = (s32)(p_eve->value + p_eve->clock + p_ut->env_release_clock);

			EVERECORD* next = NULL;
			for(EVERECORD* p = p_eve->next; p; p = p->next)
			{
				if(p->clock > c) break;
				if(p->unit_no == p_eve->unit_no && p->kind == EVENTKIND_ON){ next = p; break; }
			}
			if(!next) max_life_count2 = (s32)(mp->smp_end) - (s32)(mp->clock * mp->smp_per_clk);
			else      max_life_count2 = (s32)((next->clock - mp->clock) * mp->smp_per_clk);

			if(max_life_count1 < max_life_count2) p_ut->life_count = max_life_count1;
			else                                  p_ut->life_count = max_life_count2;

		} else {

			/* no release */
			p_ut->life_count = (s32)((p_eve->clock + p_eve->value - mp->clock) * mp->smp_per_clk);
		}

		if( p_ut->life_count > 0 ) {

			p_ut->on_count = on_count;
			p_ut->smp_pos  = 0;
			p_ut->env_pos  = 0;
			if(p_wi->env_num) p_ut->env_volume = p_ut->env_start =   0; // envelope
			else              p_ut->env_volume = p_ut->env_start = 128; // no-envelope

		}
	}
}

inline static void _proc_event(MPXTN *mp, const EVERECORD *p_eve)
{
	UNIT *p_u = &mp->srv.units[p_eve->unit_no];

	switch(p_eve->kind) {
	case EVENTKIND_ON        : _proc_event_on  (mp, p_u, p_eve);        break;
	case EVENTKIND_KEY       : unit_tone_key       (p_u, p_eve->value); break;
	case EVENTKIND_PAN_VOLUME: unit_tone_pan_volume(p_u, p_eve->value); break;
	case EVENTKIND_PAN_TIME  : unit_tone_pan_time  (p_u, p_eve->value); break;
	case EVENTKIND_VELOCITY  : unit_tone_velocity  (p_u, p_eve->value); break;
	case EVENTKIND_VOLUME    : unit_tone_volume    (p_u, p_eve->value); break;
	case EVENTKIND_PORTAMENT : unit_tone_portament (p_u, (s32)(p_eve->value * mp->smp_per_clk)); break;
	case EVENTKIND_BEATCLOCK : break;
	case EVENTKIND_BEATTEMPO : break;
	case EVENTKIND_BEATNUM   : break;
	case EVENTKIND_REPEAT    : break;
	case EVENTKIND_LAST      : break;
	case EVENTKIND_VOICENO   : _reset_voice_on(mp, p_u, p_eve->value); break;
	case EVENTKIND_GROUPNO   : unit_tone_groupno  (p_u, p_eve->value); break;
	case EVENTKIND_TUNING    : unit_tone_tuning   (p_u, *(const float*)(&p_eve->value)); break;
	}

}

static bool _PXTONE_SAMPLE(MPXTN *mp)
{
	u32 i;
	u32 ch;
	s32 work;

	/* get current clock */
	mp->clock = (s32)(mp->smp_count / mp->smp_per_clk);

	/* envelope.. */
	for(i = 0; i < mp->srv.unit_num; ++i) {
		unit_tone_envelope(&mp->srv.units[i]);
	}

	/* proc events within target sample clock */
	while(mp->p_eve && mp->p_eve->clock <= mp->clock) {
		_proc_event(mp, mp->p_eve);
		mp->p_eve = mp->p_eve->next;
	}

	/* sampling */
	for(i = 0; i < mp->srv.unit_num; ++i) {
		unit_tone_sample(&mp->srv.units[i], mp->time_pan_idx, mp->smp_smooth);
	}

	for(ch = 0; ch < MPXTN_CH; ++ch) {

		/* clear */
		work = 0;
		for(i = 0; i < GROUP_MAX; ++i) mp->group_smps[i] = 0;

		for(i = 0; i < mp->srv.unit_num; ++i) {
			unit_tone_supple(&mp->srv.units[i], mp->group_smps, ch, mp->time_pan_idx);
		}

		/* effect */
		for(i = 0; i < mp->srv.ovdrv_num; ++i) {
			overdrive_tone_supple(&mp->srv.ovdrvs[i], mp->group_smps);
		}

		for(i = 0; i < mp->srv.delay_num; ++i) {
			delay_tone_supple(&mp->srv.delays[i], mp->group_smps, ch);
		}

		/* collect */
		for(i = 0; i < GROUP_MAX; ++i) work += mp->group_smps[i];

		if(work >   mp->top) work =   mp->top;
		if(work < - mp->top) work = - mp->top;

		/* to buffer */
		mp->smp_data[ch] = (s16)work;
	}

	/* increment */
	mp->smp_count++;
	mp->time_pan_idx = (mp->time_pan_idx + 1) & (BUFSIZE_TIMEPAN - 1);

	/* Units */
	for(i = 0; i < mp->srv.unit_num; ++i) {
		UNIT *p_u = &mp->srv.units[i];
		s32 key = unit_tone_increment_key(p_u);
		unit_tone_increment_sample(p_u, freq_get2(key));
	}

	/* Delays */
	for(i = 0; i < mp->srv.delay_num; ++i) {
		delay_tone_increment(&mp->srv.delays[i]);
	}

	/* TODO: fade in/out */

	/* end of samples */
	if(mp->smp_count >= mp->smp_end)
	{
		if(!mp->loop) return false;

		/* prepare from repeat point */
		mp->smp_count = mp->smp_repeat;
		mp->p_eve     = evelist_get_records(&mp->srv.evels);
		if(!_init_unit_tone(mp)) return false;
	}

	return true;
}


MPXTN_API size_t mpxtn_vomit(void* buffer, size_t count, MPXTN* mp)
{
	size_t i = 0;
	size_t vomited = 0;
	s16 *dst = (s16*)buffer;

	if(!buffer)        return 0;
	if(!count)         return 0;
	if(!mp)            return 0;
	if(!mp->srv.valid) return 0;
	if(mp->end_vomit)  return 0;

	while(i < count && !mp->end_vomit) {
		if(!_PXTONE_SAMPLE(mp)) {
			mp->end_vomit = true;
			*(dst++) = mp->smp_data[0];
			*(dst++) = mp->smp_data[1];
			i++;
			break;
		}
		*(dst++) = mp->smp_data[0];
		*(dst++) = mp->smp_data[1];
		i++;
	}
	vomited = i;

	while(i < count) {
		*(dst++) = 0;
		*(dst++) = 0;
		i++;
	}

	return vomited;
}

MPXTN_API bool mpxtn_reset(MPXTN *mp)
{
	if(!mp) return false;
	if(!mp->srv.valid) return false;

	mp->end_vomit = false;
	mp->loop = false;

	mp->time_pan_idx = 0;

	mp->smp_count  = 0;

	mp->p_eve = evelist_get_records(&mp->srv.evels);

	/* clear tones */
	for(u32 i = 0; i < mp->srv.delay_num; ++i) {
		delay_tone_clear(&mp->srv.delays[i]);
	}
	for(u32 i = 0; i < mp->srv.unit_num; ++i) {
		unit_tone_clear(&mp->srv.units[i]);
	}

	if(!_init_unit_tone(mp)) return false;

	return true;
}

MPXTN_API bool mpxtn_seek(MPXTN *mp, size_t _smp_num)
{

	if(!mp) return false;
	if(!mp->srv.valid) return false;
	if(_smp_num > UINT32_MAX) return false;

	u32 smp_num = (u32)_smp_num;

	if(smp_num > mp->smp_end) return false;

	if(smp_num == mp->smp_end) {
		mp->end_vomit = true;
		return true;
	}

	if(smp_num >= mp->smp_count) {
		/* seek forward */
		mp->smp_count = smp_num;
	} else {
		/* seek backward */
		mp->end_vomit = false;

		mp->time_pan_idx = 0;

		mp->smp_count  = smp_num;

		mp->p_eve = evelist_get_records(&mp->srv.evels);

		/* clear tones */
		for(u32 i = 0; i < mp->srv.delay_num; ++i) {
			delay_tone_clear(&mp->srv.delays[i]);
		}
		for(u32 i = 0; i < mp->srv.unit_num; ++i) {
			unit_tone_clear(&mp->srv.units[i]);
		}

		if(!_init_unit_tone(mp)) return false;

		mp->clock = (s32)(mp->smp_count / mp->smp_per_clk);

		/* proc events within target sample clock */
		while(mp->p_eve && mp->p_eve->clock <= mp->clock) {
			_proc_event(mp, mp->p_eve);
			mp->p_eve = mp->p_eve->next;
		}
	}

	return true;
}

MPXTN_API size_t mpxtn_get_total_samples(const MPXTN *mp)
{
	if(!mp) return 0;
	if(!mp->srv.valid) return 0;

	return mp->smp_end;
}

MPXTN_API size_t mpxtn_get_current_sample(const MPXTN *mp)
{
	if(!mp) return 0;
	if(!mp->srv.valid) return 0;

	return mp->smp_count;
}

MPXTN_API size_t mpxtn_get_repeat_sample(const MPXTN *mp)
{
	if(!mp) return 0;
	if(!mp->srv.valid) return 0;

	return mp->smp_repeat;
}

MPXTN_API bool mpxtn_get_loop(const MPXTN *mp)
{
	if(!mp) return 0;
	if(!mp->srv.valid) return 0;

	return mp->loop;
}

MPXTN_API void mpxtn_set_loop(MPXTN *mp, bool loop)
{
	if(!mp) return;
	if(!mp->srv.valid) return;

	mp->loop = loop;
}
