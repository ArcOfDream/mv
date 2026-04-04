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
#include "error.h"

#include "service.h"

#define VERSIONSIZE 16
#define CODESIZE     8

/* version */
static const char _version_proj[] = "PTCOLLAGE-071119";
static const char _version_tune[] = "PTTUNE--20071119";

/* code */
static const char _code_num_UNIT[] = "num UNIT";
static const char _code_Master[]   = "MasterV5";
static const char _code_Event[]    = "Event V5";
static const char _code_matePCM[]  = "matePCM ";
static const char _code_matePTV[]  = "matePTV ";
static const char _code_matePTN[]  = "matePTN ";
static const char _code_mateOGGV[] = "mateOGGV";
static const char _code_effeDELA[] = "effeDELA";
static const char _code_effeOVER[] = "effeOVER";
static const char _code_textNAME[] = "textNAME";
static const char _code_textCOMM[] = "textCOMM";
static const char _code_assiUNIT[] = "assiUNIT";
static const char _code_assiWOIC[] = "assiWOIC";
static const char _code_pxtoneND[] = "pxtoneND";

enum _Tag
{
	_TAG_UNKNOWN,
	_TAG_num_UNIT,
	_TAG_Master,
	_TAG_Event,
	_TAG_materialPCM,
	_TAG_materialPTV,
	_TAG_materialPTN,
	_TAG_materialOGGV,
	_TAG_effectDELAY,
	_TAG_effectOVERDRIVE,
	_TAG_textNAME,
	_TAG_textCOMMENT,
	_TAG_assistUNIT,
	_TAG_assistWOICE,
	_TAG_pxtoneND
};

static enum _Tag _check_tag_code(const char *p_code)
{
	/* supported tag only */
	     if(!memcmp(p_code, _code_num_UNIT , CODESIZE)) return _TAG_num_UNIT;
	else if(!memcmp(p_code, _code_Master   , CODESIZE)) return _TAG_Master;
	else if(!memcmp(p_code, _code_Event    , CODESIZE)) return _TAG_Event;
	else if(!memcmp(p_code, _code_matePCM  , CODESIZE)) return _TAG_materialPCM;
	else if(!memcmp(p_code, _code_matePTV  , CODESIZE)) return _TAG_materialPTV;
	else if(!memcmp(p_code, _code_matePTN  , CODESIZE)) return _TAG_materialPTN;
	else if(!memcmp(p_code, _code_mateOGGV , CODESIZE)) return _TAG_materialOGGV;
	else if(!memcmp(p_code, _code_effeDELA , CODESIZE)) return _TAG_effectDELAY;
	else if(!memcmp(p_code, _code_effeOVER , CODESIZE)) return _TAG_effectOVERDRIVE;
	else if(!memcmp(p_code, _code_textNAME , CODESIZE)) return _TAG_textNAME;
	else if(!memcmp(p_code, _code_textCOMM , CODESIZE)) return _TAG_textCOMMENT;
	else if(!memcmp(p_code, _code_assiUNIT , CODESIZE)) return _TAG_assistUNIT;
	else if(!memcmp(p_code, _code_assiWOIC , CODESIZE)) return _TAG_assistWOICE;
	else if(!memcmp(p_code, _code_pxtoneND , CODESIZE)) return _TAG_pxtoneND;
	return _TAG_UNKNOWN;
}

/* -------------------------------------------------------------------------- */
static bool _service_alloc(SERVICE *p_serv)
{
	bool ret = false;

	if(p_serv->event_num) {
		if(!evelist_alloc(&p_serv->evels, p_serv->event_num)) goto End;
	}
	if(p_serv->delay_num) {
		p_serv->delays = calloc(p_serv->delay_num, sizeof(DELAY));
		if(!p_serv->delays) goto End;
	}
	if(p_serv->ovdrv_num) {
		p_serv->ovdrvs = calloc(p_serv->ovdrv_num, sizeof(OVERDRIVE));
		if(!p_serv->ovdrvs) goto End;
	}
	if(p_serv->woice_num) {
		p_serv->woices = calloc(p_serv->woice_num, sizeof(WOICE));
		if(!p_serv->woices) goto End;
	}
	if(p_serv->unit_num) {
		p_serv->units = calloc(p_serv->unit_num, sizeof(UNIT));
		if(!p_serv->units) goto End;
	}

	ret = true;
End:
	if(!ret) service_free(p_serv);
	return ret;
}

void service_free(SERVICE *p_serv)
{
	if(!p_serv) return;

	evelist_free(&p_serv->evels);

	if(p_serv->delays) {
		for(u32 i = 0; i < p_serv->delay_num; ++i) {
			delay_free(&p_serv->delays[i]);
		}
		free(p_serv->delays);
	}

	if(p_serv->ovdrvs) free(p_serv->ovdrvs);

	if(p_serv->woices) {
		for(u32 i = 0; i < p_serv->woice_num; ++i) {
			woice_free(&p_serv->woices[i]);
		}
		free(p_serv->woices);
	}

	if(p_serv->units)  free(p_serv->units);

	memset(p_serv, 0, sizeof(SERVICE));
}

/* -------------------------------------------------------------------------- */

bool service_tone_init(SERVICE *p_serv)
{
	if(!p_serv->valid) return false;
	return true;
}


/* -------------------------------------------------------------------------- */
static bool _read_delay(SERVICE *p_serv, DESCRIPTOR *p_desc)
{
	bool ret = false;

	if(!p_serv->delay_num) return false;
	if(p_serv->delay_idx >= p_serv->delay_num) return false;

	DELAY *p_d = &p_serv->delays[p_serv->delay_idx];
	ret = delay_read(p_d, p_desc);

	if(ret) p_serv->delay_idx++;

	return ret;
}

/* -------------------------------------------------------------------------- */
static bool _read_overdrive(SERVICE *p_serv, DESCRIPTOR *p_desc)
{
	bool ret = false;

	if(!p_serv->ovdrv_num) return false;
	if(p_serv->ovdrv_idx >= p_serv->ovdrv_num) return false;

	OVERDRIVE *p_d = &p_serv->ovdrvs[p_serv->ovdrv_idx];
	ret = overdrive_read(p_d, p_desc);

	if(ret) p_serv->ovdrv_idx++;

	return ret;
}

/* -------------------------------------------------------------------------- */
static bool _read_woice(SERVICE *p_serv, DESCRIPTOR *p_desc, WOICETYPE type)
{
	bool ret = false;

	if(!p_serv->woice_num) return false;
	if(p_serv->woice_idx >= p_serv->woice_num) return false;

	WOICE *p_w = &p_serv->woices[p_serv->woice_idx];

	switch(type)
	{
	case WOICE_PCM:  ret = woice_read_matePCM(p_w, p_desc);  break;
	case WOICE_PTV:  ret = woice_read_matePTV(p_w, p_desc);  break;
	case WOICE_PTN:  ret = woice_read_matePTN(p_w, p_desc);  break;
#ifdef MPXTN_OGGVORBIS
	case WOICE_OGGV: ret = woice_read_mateOGGV(p_w, p_desc); break;
#endif
	default: return false;
	}

	if(ret) p_serv->woice_idx++;

	return ret;
}

/* -------------------------------------------------------------------------- */
static const size_t _NUM_UNITSIZE = 4;

struct _NUM_UNIT
{
	u16 num; // 0:2
	u16 rrr; // 2:4 -> 4byte
};

static mpxtn_err_t _read_unit_num(DESCRIPTOR *p_desc, u32 *p_num)
{
	u32 size = 0;
	struct _NUM_UNIT n = {0};

	if(!desc_u32_r(p_desc, &size )) return MPXTN_EDESC;
	if(!desc_u16_r(p_desc, &n.num)) return MPXTN_EDESC;
	if(!desc_u16_r(p_desc, &n.rrr)) return MPXTN_EDESC;

	/* check */
	if(size != _NUM_UNITSIZE) return MPXTN_EUNKNOWNFMT;
	if(n.rrr) return MPXTN_EUNKNOWNFMT;

	*p_num = n.num;

	return MPXTN_NOERR;
}


/* -------------------------------------------------------------------------- */
static bool _read_skip(DESCRIPTOR *p_desc)
{
	s32 size = 0;
	if(!desc_s32_r(p_desc, &size)) return false;
	if(!desc_seek(p_desc, size, SEEK_CUR)) return false;
	return true;
}

/* -------------------------------------------------------------------------- */
static mpxtn_err_t _read_tune_items(SERVICE *p_serv, DESCRIPTOR *p_desc)
{
	bool end = false;
	char code[CODESIZE + 1] = {0};

	/// must the unit before the voice.
	while(!end)
	{
		if(!desc_dat_r(p_desc, code, CODESIZE)) return MPXTN_EDESC;

		enum _Tag tag = _check_tag_code(code);

		switch(tag)
		{
		case _TAG_Master:

			if(!master_read(&p_serv->master, p_desc)) return MPXTN_EREADMASTER;
			break;

		case _TAG_Event:

			if(!evelist_read(&p_serv->evels, p_desc)) return MPXTN_EREADEVENT;
			break;

		/* material */
		case _TAG_materialPCM:

			if(!_read_woice(p_serv, p_desc, WOICE_PCM)) return MPXTN_EREADPCM;
			break;

		case _TAG_materialPTV:

			if(!_read_woice(p_serv, p_desc, WOICE_PTV)) return MPXTN_EREADPTV;
			break;

		case _TAG_materialPTN:

			if(!_read_woice(p_serv, p_desc, WOICE_PTN)) return MPXTN_EREADPTN;
			break;

#ifdef MPXTN_OGGVORBIS
		case _TAG_materialOGGV:

			if(!_read_woice(p_serv, p_desc, WOICE_OGGV)) return MPXTN_EREADOGGV;
			break;
#endif

		/* effect */
		case _TAG_effectDELAY:

			if(!_read_delay(p_serv, p_desc)) return MPXTN_EREADDELAY;
			break;

		case _TAG_effectOVERDRIVE:

			if(!_read_overdrive(p_serv, p_desc)) return MPXTN_EREADOVDRV;
			break;

		/* skip */
		case _TAG_textNAME:
		case _TAG_textCOMMENT:
		case _TAG_assistWOICE:
		case _TAG_assistUNIT:
		case _TAG_num_UNIT:

			if(!_read_skip(p_desc)) return MPXTN_EDESC;
			break;

		/* end */
		case _TAG_pxtoneND:
			end = true;
			break;

		/* not support */
		case _TAG_UNKNOWN:
		default:
			return MPXTN_EUNKNOWNFMT;
		}
	}

	return MPXTN_NOERR;
}



static mpxtn_err_t _read_version(DESCRIPTOR *p_desc, u8 *p_fmtver, u16 *p_exever)
{
	u16 exever = 0;
	u16 dummy  = 0;
	char version[VERSIONSIZE] = {0};

	if(!desc_dat_r(p_desc, version, VERSIONSIZE)) return MPXTN_EDESC;

	/* fmt version */
	if(!memcmp(version, _version_proj, VERSIONSIZE) &&
	   !memcmp(version, _version_tune, VERSIONSIZE)) return MPXTN_EOLDFMT;

	/* exe version */
	if(!desc_u16_r(p_desc, &exever)) return MPXTN_EDESC;
	if(!desc_u16_r(p_desc, &dummy )) return MPXTN_EDESC;

	/* TODO: add exe_ver check(?) */
	if(p_fmtver) *p_fmtver = 1;
	if(p_exever) *p_exever = exever;

	return MPXTN_NOERR;
}


static mpxtn_err_t _read_info(SERVICE *p_serv, DESCRIPTOR *p_desc)
{
	bool end    = false;
	u32  count  = 0;
	u8   fmtver = 0;
	u16  exever = 0;
	char code[CODESIZE + 1] = {0};
	mpxtn_err_t ret = MPXTN_NOERR;

	ret = _read_version(p_desc, &fmtver, &exever);
	if(ret != MPXTN_NOERR) return ret;

	while(!end)
	{
		if(!desc_dat_r(p_desc, code, CODESIZE)) return MPXTN_EDESC;

		switch(_check_tag_code(code))
		{
		/* proc */
		case _TAG_Event : count += evelist_read_event_num(p_desc); break;
		case _TAG_Master: count += master_read_event_num(p_desc);  break;
		case _TAG_num_UNIT:

			ret = _read_unit_num(p_desc, &p_serv->unit_num);
			if(ret != MPXTN_NOERR) return ret;
			break;

		/* count */
#ifndef MPXTN_OGGVORBIS
		case _TAG_materialOGGV:
			return MPXTN_EUSEOGG;
			break;
#else
		case _TAG_materialOGGV:
#endif
		case _TAG_materialPCM:
		case _TAG_materialPTV:
		case _TAG_materialPTN:

			p_serv->woice_num++;
			if(!_read_skip(p_desc)) return MPXTN_EDESC;
			break;

		case _TAG_effectDELAY:

			p_serv->delay_num++;
			if(!_read_skip(p_desc)) return MPXTN_EDESC;
			break;

		case _TAG_effectOVERDRIVE:

			p_serv->ovdrv_num++;
			if(!_read_skip(p_desc)) return MPXTN_EDESC;
			break;

		/* skip */
		case _TAG_textNAME:
		case _TAG_textCOMMENT:
		case _TAG_assistUNIT:
		case _TAG_assistWOICE:

			if(!_read_skip(p_desc)) return MPXTN_EDESC;
			break;

		/* end */
		case _TAG_pxtoneND:

			end = true;
			break;

		/* unsupported */
		case _TAG_UNKNOWN:
		default:

			return MPXTN_EUNKNOWNFMT;
		}
	}

	p_serv->event_num = count;

	/* check invalid size */
	if(p_serv->event_num >     EVENT_MAX) return MPXTN_EMANYEVENT;
	if(p_serv->unit_num  >      UNIT_MAX) return MPXTN_EMANYUNIT;
	if(p_serv->woice_num >     WOICE_MAX) return MPXTN_EMANYWOICE;
	if(p_serv->delay_num >     DELAY_MAX) return MPXTN_EMANYDELAY;
	if(p_serv->ovdrv_num > OVERDRIVE_MAX) return MPXTN_EMANYOVDRV;

	return MPXTN_NOERR;
}

/* -------------------------------------------------------------------------- */
mpxtn_err_t service_read(SERVICE *p_serv, DESCRIPTOR *p_desc)
{
	mpxtn_err_t ret = MPXTN_NOERR;

	if(!p_serv) return MPXTN_EINTERNAL;
	if(!p_desc) return MPXTN_EINTERNAL;

	service_free(p_serv);

	/* read & count event */
	ret = _read_info(p_serv, p_desc);
	if(ret != MPXTN_NOERR) goto End;

	/* memory allocate */
	if(!_service_alloc(p_serv)) {
		ret = MPXTN_ENOMEM;
		goto End;
	}

	/* seek_set 0 & skip version section... */
	if(!desc_seek(p_desc, VERSIONSIZE + 4, SEEK_SET)) {
		ret = MPXTN_EDESC;
		goto End;
	}

	/* event reading */
	evelist_linear_start(&p_serv->evels);
	ret = _read_tune_items(p_serv, p_desc);
	if(ret != MPXTN_NOERR) goto End;
	evelist_linear_end(&p_serv->evels);

	/* check event value */
	if(!evelist_check_value(&p_serv->evels) ||
	   !evelist_check_unitno(&p_serv->evels, p_serv->unit_num) ||
	   !evelist_check_voiceno(&p_serv->evels, p_serv->woice_num)) {
		ret = MPXTN_EEVEINVAL;
		goto End;
	}

	/* beat clock always default value */
	if(p_serv->master.beat_clock != EVENTDEFAULT_BEATCLOCK) {
		ret = MPXTN_EUNKNOWNFMT;
		goto End;
	}

	{
		u32 clock1 = (u32)evelist_get_max_clock(&p_serv->evels);
		u32 clock2 = master_get_last_clock(&p_serv->master);

		if(clock1 > clock2) master_adjust_meas_num(&p_serv->master, clock1);
		else                master_adjust_meas_num(&p_serv->master, clock2);
	}

	p_serv->valid = true;
End:
	if(!p_serv->valid) {
		service_free(p_serv);
	}

	return ret;
}

