module pxtn

import raylib as rl

#include "ptn.h"
#include "descriptor.h"

struct C.DESCRIPTOR {}

struct C.PTN {
	smp_num u32
	size    u8
	units   voidptr
}

fn C.desc_set_memory(p_desc &C.DESCRIPTOR, p_mem voidptr, size usize) int
fn C.ptn_read(p_ptn &C.PTN, p_desc &C.DESCRIPTOR) bool
fn C.ptn_build(p_ptn &C.PTN) &i16
fn C.ptn_free(p_ptn &C.PTN)

pub fn wave_from_ptnoise(data []u8) !rl.Wave {
	mut desc := C.DESCRIPTOR{}
	if C.desc_set_memory(&desc, data.data, usize(data.len)) != 0 {
		return error('failed to set ptnoise descriptor')
	}

	mut ptn := C.PTN{}
	if !C.ptn_read(&ptn, &desc) {
		return error('failed to read ptnoise data')
	}
	defer { C.ptn_free(&ptn) }

	samples := C.ptn_build(&ptn)
	if samples == unsafe { nil } {
		return error('ptn_build returned null')
	}

	return rl.Wave{
		frame_count: ptn.smp_num
		sample_rate: 44100
		sample_size: 16
		channels:    1
		data:        samples
	}
}
