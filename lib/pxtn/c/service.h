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
#ifndef MPXTNLIB_SERVICE_H
#define MPXTNLIB_SERVICE_H

#include "common.h"

#include "descriptor.h"

#include "delay.h"
#include "evelist.h"
#include "overdrive.h"
#include "master.h"
#include "unit.h"

typedef struct {
	bool valid;
	u32 event_num;
	u32 delay_num;
	u32 ovdrv_num;
	u32 woice_num;
	u32 unit_num;
	u32 event_idx;
	u32 delay_idx;
	u32 ovdrv_idx;
	u32 woice_idx;
	u32 unit_idx;
	MASTER    master;
	EVELIST   evels;
	DELAY     *delays;
	OVERDRIVE *ovdrvs;
	UNIT      *units;
	WOICE     *woices;
} SERVICE;

void service_free(SERVICE *p_serv);

mpxtn_err_t service_read(SERVICE *p_serv, DESCRIPTOR *p_desc);

bool service_tone_init(SERVICE *p_serv);

#endif
