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
#ifndef MPXTNLIB_ERROR_H
#define MPXTNLIB_ERROR_H

#include "common.h"

/* Error */
#define MPXTN_NOERR          0
#define MPXTN_ENOMEM         1 /* cannot allocate enough memory */
#define MPXTN_ETOOBIG        2 /* file/memory is too big */
#define MPXTN_EDESC          3 /* file/memory read failure */
#define MPXTN_EOLDFMT        4 /* old project */
#define MPXTN_EUSEOGGV       5 /* not support ogg */
#define MPXTN_EINVDESC       6
#define MPXTN_EINVMEM        7
#define MPXTN_EINVFILE       8
#define MPXTN_EINTERNAL      9
#define MPXTN_EUNKNOWNFMT   10
#define MPXTN_EMANYEVENT    11
#define MPXTN_EMANYDELAY    12
#define MPXTN_EMANYOVDRV    13
#define MPXTN_EMANYUNIT     14
#define MPXTN_EMANYWOICE    15
#define MPXTN_EEVEINVAL     16 /* event contain invalid value */
#define MPXTN_EREADMASTER   17
#define MPXTN_EREADEVENT    18
#define MPXTN_EREADDELAY    19
#define MPXTN_EREADOVDRV    20
#define MPXTN_EREADPCM      21
#define MPXTN_EREADPTV      22
#define MPXTN_EREADPTN      23
#define MPXTN_EREADOGGV     24
#define MPXTN_EPREPARE      25


typedef s32 mpxtn_err_t;

#ifdef _DEBUG
#define error_msg(...) _error_msg(__FILE__, __VA_ARGS__)
#else
#define error_msg(...)
#endif

#ifdef _DEBUG
void _error_msg(const char *path, const char *fmt, ...);
#endif

#endif
