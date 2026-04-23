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
#ifndef MPXTNLIB_MPXTN_H
#define MPXTNLIB_MPXTN_H

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

#ifdef _WIN32

#if defined (_USRDLL) && defined (mpxtn_EXPORTS)
#define MPXTN_API __declspec(dllexport)
#else
#ifdef MPXTN_DLL
#define MPXTN_API __declspec(dllimport)
#endif /* MPXTN_DLL */
#endif /* _USERDLL && mpxtn_EXPORTS */

#else /* _WIN32 */

#ifdef mpxtn_EXPORTS /* for gcc/clang */
#define MPXTN_API __attribute__((visibility("default")))
#endif /* mpxtn_EXPORTS */

#endif /* _WIN32 */

#ifndef MPXTN_API
#define MPXTN_API
#endif

struct _MPXTN;
typedef struct _MPXTN MPXTN;

MPXTN_API MPXTN *mpxtn_fread(FILE* fp, int* err);
MPXTN_API MPXTN *mpxtn_mread(const void* p, size_t size, int* err);

/* NOTE: must alloc count * 4 byte memory */
MPXTN_API size_t mpxtn_vomit(void* buffer, size_t count, MPXTN* mp);

MPXTN_API bool mpxtn_seek(MPXTN *mp, size_t smp_num);

MPXTN_API bool mpxtn_reset(MPXTN *mp);

MPXTN_API size_t mpxtn_get_total_samples(const MPXTN *mp);
MPXTN_API size_t mpxtn_get_current_sample(const MPXTN *mp);
MPXTN_API size_t mpxtn_get_repeat_sample(const MPXTN *mp);

MPXTN_API void mpxtn_set_loop(MPXTN *mp, bool loop);
MPXTN_API bool mpxtn_get_loop(const MPXTN *mp);

MPXTN_API void mpxtn_close(MPXTN *mp);

/* --- metadata / note extraction --- */

/* Flat event record for bulk copy; fields ordered to avoid struct padding.
 * clock and value come first (4-byte aligned), then the two byte fields. */
typedef struct {
	int32_t  clock;
	int32_t  value;
	uint8_t  kind;
	uint8_t  unit_no;
	uint8_t  _pad[2];
} MPXTN_EVENTREC;

/* Event kind constants (mirrors internal EVENTKIND enum). */
#define MPXTN_EK_ON          1
#define MPXTN_EK_KEY         2
#define MPXTN_EK_PAN_VOLUME  3
#define MPXTN_EK_VELOCITY    4
#define MPXTN_EK_VOLUME      5
#define MPXTN_EK_PORTAMENT   6
#define MPXTN_EK_VOICENO    12
#define MPXTN_EK_GROUPNO    13
#define MPXTN_EK_TUNING     14
#define MPXTN_EK_PAN_TIME   15

/* Key value corresponding to A4 (440 Hz); use as reference for pitch math. */
#define MPXTN_BASICKEY 0x4500

/* Master / tempo info. */
MPXTN_API uint32_t mpxtn_get_beat_num(const MPXTN *mp);
MPXTN_API float    mpxtn_get_beat_tempo(const MPXTN *mp);
MPXTN_API uint32_t mpxtn_get_beat_clock(const MPXTN *mp);
MPXTN_API uint32_t mpxtn_get_meas_num(const MPXTN *mp);
MPXTN_API uint32_t mpxtn_get_meas_repeat(const MPXTN *mp);

/* Number of units (tracks). */
MPXTN_API uint32_t mpxtn_get_unit_num(const MPXTN *mp);

/* Raw event access.
 * mpxtn_copy_events writes at most `count` records into buf (caller-allocated).
 * Returns false if mp or buf is null. */
MPXTN_API uint32_t mpxtn_get_event_num(const MPXTN *mp);
MPXTN_API bool     mpxtn_copy_events(const MPXTN *mp, MPXTN_EVENTREC *buf, uint32_t count);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif
