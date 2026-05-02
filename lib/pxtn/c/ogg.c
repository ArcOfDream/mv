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

#ifndef STB_VORBIS_IMPLEMENTATION
#define STB_VORBIS_IMPLEMENTATION
#endif

#include "stb_vorbis.c"

typedef struct
{
	const u8* p_buf; // ogg vorbis-data on memory.s
	s32       size ; //
	s32       pos  ; // reading position.
} OVMEM;

static bool _ogg_decode(void **p_dst, s32 *p_dstsize,
                        const void *p_src, s32 srcsize)
{
    int   channels   = 0;
    int   sample_rate = 0;
    short *pcm       = NULL;

    int smp_num = stb_vorbis_decode_memory(
                      (const uint8 *)p_src, srcsize,
                      &channels, &sample_rate, &pcm);

    if (smp_num < 0 || !pcm)
        return false;

    if (channels < 1 || channels > 2) {
        free(pcm);
        return false;
    }

    // stb_vorbis_decode_memory handles malloc for pcm
    *p_dst     = pcm;
    *p_dstsize = smp_num * channels * (s32)sizeof(s16);

    return true;
}

void ogg_free(OGG *p_ogg)
{
    if (!p_ogg) return;
    free(p_ogg->p_data);

    p_ogg->ch      = 0;
    p_ogg->sps     = 0;
    p_ogg->size    = 0;
    p_ogg->smp_num = 0;
    p_ogg->p_data  = NULL;
}

bool ogg_read(OGG *p_ogg, DESCRIPTOR *p_desc)
{
    bool  ret    = false;
    void *p_data = NULL;
    s32   size   = 0;

    if (!desc_s32_r(p_desc, &p_ogg->ch     )) return false;
    if (!desc_s32_r(p_desc, &p_ogg->sps    )) return false;
    if (!desc_s32_r(p_desc, &p_ogg->smp_num)) return false;
    if (!desc_s32_r(p_desc, &size          )) return false;

    if (size <= 0) return false;

    p_data = calloc((size_t)size, sizeof(u8));
    if (!p_data) goto End;

    if (!desc_dat_r(p_desc, p_data, (size_t)size)) goto End;

    if (!_ogg_decode((void **)&p_ogg->p_data, &p_ogg->size,
                     p_data, size)) goto End;

    ret = true;
End:
    if (!ret) ogg_free(p_ogg);
    free(p_data);
    return ret;
}

#endif
