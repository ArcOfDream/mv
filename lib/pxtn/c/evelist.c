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

#include "evelist.h"

/* -------------------------------------------------------------------------- */

bool evelist_alloc(EVELIST *p_eve, u32 size)
{
	if(p_eve->records) return false; /* already initialized */
	p_eve->records = calloc(size, sizeof(EVERECORD));

	/* set size */
	if(p_eve->records) p_eve->size = size;
	else               p_eve->size = 0;

	return p_eve->records != NULL;
}

void evelist_free(EVELIST *p_eve)
{
	if(!p_eve) return;
	if(!p_eve->records) return;
	free(p_eve->records);
	p_eve->records = NULL;
}

/* -------------------------------------------------------------------------- */

static bool _record_check(EVERECORD *p_er)
{
	switch(p_er->kind) {
	case EVENTKIND_ON:
	case EVENTKIND_PORTAMENT:
		/* value = clock(span) */
		if(p_er->value < 0) return false;
		if(p_er->clock + p_er->value < 0) return false;
		break;
	case EVENTKIND_PAN_VOLUME:
	case EVENTKIND_PAN_TIME:
		if(p_er->value < 0) return false;
		if(p_er->value > PAN_MAX) return false;
		break;
	case EVENTKIND_VOLUME:
		if(p_er->value < 0) return false;
		if(p_er->value > VOLUME_MAX) return false;
		break;
	case EVENTKIND_VELOCITY:
		if(p_er->value < 0) return false;
		if(p_er->value > VELOCITY_MAX) return false;
		break;
	case EVENTKIND_KEY:
		if(p_er->value < 0) return false;
		break;
	}
	return true;
}

bool evelist_check_value(EVELIST *p_eve)
{
	for(EVERECORD* p = p_eve->start; p; p = p->next)
	{
		if(p->kind >= EVENTKIND_NUM) return false;
		if(!_record_check(p)) return false;

	}
	return true;
}

bool evelist_check_unitno(EVELIST *p_eve, u32 unit_num)
{
	for(EVERECORD* p = p_eve->start; p; p = p->next)
	{
		if(p->unit_no >= unit_num) return false;
	}
	return true;
}

bool evelist_check_voiceno(EVELIST *p_eve, u32 woice_num)
{
	for(EVERECORD* p = p_eve->start; p; p = p->next)
	{
		if(p->kind != EVENTKIND_VOICENO) continue;
		if(p->value < 0) return false;
		if(p->value >= (s32)woice_num) return false;
	}
	return true;
}

/* -------------------------------------------------------------------------- */

s32 evelist_get_max_clock(EVELIST *p_eve)
{
	s32 max_clock = 0;
	s32 clock;

	for(EVERECORD* p = p_eve->start; p; p = p->next)
	{
		if(evelist_kind_istail(p->kind)) clock = p->clock + p->value;
		else                             clock = p->clock;
		if( clock > max_clock ) max_clock = clock;
	}

	return max_clock;

}

EVERECORD *evelist_get_records(EVELIST *p_eve)
{
	if(!p_eve->size) return NULL;
	return p_eve->start;
}

bool evelist_kind_istail(u8 kind)
{
	if(kind == EVENTKIND_ON || kind == EVENTKIND_PORTAMENT) return true;
	return false;
}

/* -------------------------------------------------------------------------- */

bool evelist_linear_start(EVELIST *p_eve)
{
	if(!p_eve->records) return false;
	memset(p_eve->records, 0, p_eve->size * sizeof(EVERECORD));
	p_eve->start = NULL;
	p_eve->linear = 0;
	return false;
}

static void _evelist_linear_add_s32(EVELIST *p_eve, s32 clock, u8 unit_no, u8 kind, s32 value)
{
	EVERECORD *p = &p_eve->records[p_eve->linear++];

	p->clock   = clock;
	p->unit_no = unit_no;
	p->kind    = kind;
	p->value   = value;
}

void evelist_linear_end(EVELIST *p_eve)
{
	if(p_eve->records[0].kind != 0) p_eve->start = &p_eve->records[0];
	for(u32 r = 1; r < p_eve->size; ++r) {
		if(p_eve->records[r].kind == 0) break;
		p_eve->records[r    ].prev = &p_eve->records[r - 1];
		p_eve->records[r - 1].next = &p_eve->records[r    ];
	}
}

/* -------------------------------------------------------------------------- */

bool evelist_read(EVELIST *p_eve, DESCRIPTOR *p_desc)
{
	u32 size    = 0;
	u32 eve_num = 0;
	u8 kind      = 0;
	u8 unit_no   = 0;
	s32 clock    = 0;
	s32 absolute = 0;
	s32 value    = 0;

	if(!desc_u32_r(p_desc, &size   )) return false;
	if(!desc_u32_r(p_desc, &eve_num)) return false;

	for(u32 e = 0; e < eve_num; ++e)
	{
		if(!desc_s32_vr(p_desc, &clock)) return false;
		if(!desc_u8_r(p_desc, &unit_no)) return false;
		if(!desc_u8_r(p_desc, &kind   )) return false;
		if(!desc_s32_vr(p_desc, &value)) return false;
		absolute += clock;
		clock     = absolute;
		_evelist_linear_add_s32(p_eve, clock, unit_no, kind, value);
	}

	return true;
}

u32 evelist_read_event_num(DESCRIPTOR *p_desc)
{
	u32 size = 0;
	u32 eve_num = 0;

	if(!desc_u32_r(p_desc, &size   )) return 0;
	if(!desc_u32_r(p_desc, &eve_num)) return 0;

	u32 c = 0;

	for( u32 e = 0; e < eve_num; e++ )
	{
		u32 work  = 0;
		u8  work8 = 0;
		if(!desc_u32_vr(p_desc, &work)) return false; /* seek */
		if(!desc_u8_r(p_desc, &work8 )) return false;
		if(!desc_u8_r(p_desc, &work8 )) return false;
		if(!desc_u32_vr(p_desc, &work)) return false;
		c++;
	}

	if( c != eve_num ) return 0;

	return eve_num;
}
