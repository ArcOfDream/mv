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

#include "ogg.h"

#ifdef MPXTN_OGGVORBIS

#include <vorbis/codec.h>
#include <vorbis/vorbisfile.h>

typedef struct
{
	const u8* p_buf; // ogg vorbis-data on memory.s
	s32       size ; //
	s32       pos  ; // reading position.
} OVMEM;

/* ogg vorbis callback func */
static size_t _mread(void *p, size_t size, size_t nmemb, void* p_void)
{
	OVMEM *pom = (OVMEM*)p_void;

	if(!pom) return 0;

	/* invalid position */
	if(pom->pos >= pom->size) return 0;
	if(pom->pos == -1) return 0;

	size_t left = (size_t)(pom->size - pom->pos);

	if(size * nmemb >= left)
	{
		memcpy(p, &pom->p_buf[pom->pos], (size_t)(pom->size - pom->pos));
		pom->pos = pom->size;
		return (size_t)(left / size);
	}

	memcpy(p, &pom->p_buf[pom->pos], nmemb * size);
	pom->pos += (s32)(nmemb * size);

	return nmemb;
}

static int _mseek(void* p_void, ogg_int64_t offset, int mode)
{
	s32 newpos;
	OVMEM *pom = (OVMEM*)p_void;

	if(!pom) return -1;

	/* invalid position */
	if(pom->pos < 0) return -1;

	switch(mode)
	{
	case SEEK_SET: newpos =             (s32)offset; break;
	case SEEK_CUR: newpos = pom->pos  + (s32)offset; break;
	case SEEK_END: newpos = pom->size + (s32)offset; break;
	default: return -1;
	}

	/* invalid new position */
	if(newpos < 0) return -1;

	pom->pos = newpos;

	return 0;
}

static long _mtell(void* p_void)
{
	OVMEM* pom = (OVMEM*)p_void;
	if(!pom) return -1;
	return pom->pos;
}

static int _mclose(void* p_void)
{
	OVMEM* pom = (OVMEM*)p_void;
	if(!pom) return -1;
	return 0;
}

static bool _ogg_decode(void **p_dst, s32 *p_dstsize, const void *p_src, s32 srcsize)
{
	bool ret = false;

	OggVorbis_File vf;
	vorbis_info*   vi;
	ov_callbacks   oc;

	OVMEM ovmem = {0};

	ovmem.p_buf = p_src;
	ovmem.pos   = 0;
	ovmem.size  = srcsize;

	/* set callback */
	oc.read_func  = _mread;
	oc.seek_func  = _mseek;
	oc.close_func = _mclose;
	oc.tell_func  = _mtell;

	switch(ov_open_callbacks(&ovmem, &vf, NULL, 0, oc))
	{
	case OV_EREAD     : goto End;
	case OV_ENOTVORBIS: goto End;
	case OV_EVERSION  : goto End;
	case OV_EBADHEADER: goto End;
	case OV_EFAULT    : goto End;
	default: break;
	}

	vi = ov_info(&vf, -1);

	{
		/* get info & alloc */
		s32 smp_num = (s32)ov_pcm_total(&vf, -1);
		if(smp_num <= 0) goto End;
		/* check channel value */
		if(vi->channels <= 0) goto End;
		if(vi->channels > 2) goto End;

		*p_dstsize = smp_num * 2 * vi->channels;

		*p_dst = calloc((size_t)(smp_num * vi->channels), sizeof(s16));
		if(!*p_dst) goto End;
	}
	{
		/* decode */
		char pcmout[4096] = {0};
		s32 current_section;
		u8  *p = (u8*)*p_dst;
		long r = 0;
		do {
			r = ov_read(&vf, pcmout, 4096, 0, 2, 1, &current_section);
			if(r > 0) memcpy(p, pcmout, (size_t)r);
			p += r;
		}
		while(r);
	}

	ret = true;
End:
	ov_clear(&vf);

	return ret;
}

void ogg_free(OGG *p_ogg)
{
	if(!p_ogg) return;
	free(p_ogg->p_data);

	/* clear */
	p_ogg->ch      = 0;
	p_ogg->sps     = 0;
	p_ogg->size    = 0;
	p_ogg->smp_num = 0;
	p_ogg->p_data  = NULL;
}

bool ogg_read(OGG *p_ogg, DESCRIPTOR *p_desc)
{
	bool ret = false;
	void *p_data = NULL;
	s32  size = 0;

	if(!desc_s32_r(p_desc, &p_ogg->ch     )) return false;
	if(!desc_s32_r(p_desc, &p_ogg->sps    )) return false;
	if(!desc_s32_r(p_desc, &p_ogg->smp_num)) return false;
	if(!desc_s32_r(p_desc, &size          )) return false;

	if(size <= 0) return false;

	p_data = calloc((size_t)size, sizeof(u8));
	if(!p_data) goto End;

	if(!desc_dat_r(p_desc, p_data, (size_t)size)) goto End;

	if(!_ogg_decode((void **)&p_ogg->p_data, &p_ogg->size, p_data, size)) goto End;

	ret = true;
End:
	if(!ret) ogg_free(p_ogg);
	free(p_data);

	return ret;
}

#endif
