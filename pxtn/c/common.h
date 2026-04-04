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
#ifndef MPXTNLIB_COMMON_H
#define MPXTNLIB_COMMON_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

/* use short type */
typedef int8_t    s8;
typedef int16_t  s16;
typedef int32_t  s32;
typedef int64_t  s64;
typedef uint8_t   u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef float    f32;
typedef double   f64;

#define MPXTN_SPS   44100
#define MPXTN_BPS       8
#define MPXTN_CH        2

#define FILESIZE_MAX   (32*1024*1024) /* 32MB, must be 2^n */

#define EVENT_MAX      500000
#define WOICE_MAX         100
#define DELAY_MAX           4
#define OVERDRIVE_MAX       2
#define UNIT_MAX           50
#define GROUP_MAX           7

#define PAN_MAX           128
#define VOLUME_MAX        128
#define PAN_VOLUME_MAX    (PAN_MAX / 2)
#define VELOCITY_MAX      128

#define ASSISTNAME_MAX      16
#define NOISEUNIT_MAX        4
#define NOISEENVELOPE_MAX    3

#define WOICEINSTANCE_MAX    2

#define BUFSIZE_TIMEPAN      0x40

#define VOICEFLAG_WAVELOOP   0x00000001u
#define VOICEFLAG_SMOOTH     0x00000002u
#define VOICEFLAG_BEATFIT    0x00000004u
#define VOICEFLAG_UNCOVERED  0xfffffff8u

/* for evelist/unit */
#define EVENTDEFAULT_VOLUME        104
#define EVENTDEFAULT_VELOCITY      104
#define EVENTDEFAULT_PAN_VOLUME     64
#define EVENTDEFAULT_PAN_TIME       64
#define EVENTDEFAULT_PORTAMENT       0
#define EVENTDEFAULT_VOICENO         0
#define EVENTDEFAULT_GROUPNO         0
#define EVENTDEFAULT_KEY        0x6000
#define EVENTDEFAULT_BASICKEY   0x4500 // 4A(440Hz?)
#define EVENTDEFAULT_TUNING        1.0

#define EVENTDEFAULT_BEATNUM         4
#define EVENTDEFAULT_BEATTEMPO     120
#define EVENTDEFAULT_BEATCLOCK     480

typedef struct {
	s32 x;
	s32 y;
} POINT;

#include "error.h"

#endif
