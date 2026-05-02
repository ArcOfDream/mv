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

	samples := C.ptn_build(&ptn)
	if samples == unsafe { nil } {
		C.ptn_free(&ptn)
		return error('ptn_build returned null')
	}

	// Copy samples into C-managed memory before freeing ptn (which may free the buffer)
	frame_count := usize(ptn.smp_num)
	buf_size := frame_count * 2 // 16-bit samples = 2 bytes each
	buf := unsafe { C.malloc(buf_size) }
	if buf == unsafe { nil } {
		C.ptn_free(&ptn)
		return error('failed to allocate wave buffer')
	}
	unsafe { C.memcpy(buf, samples, buf_size) }
	C.ptn_free(&ptn)

	return rl.Wave{
		frame_count: u32(frame_count)
		sample_rate: 44100
		sample_size: 16
		channels:    1
		data:        buf
	}
}
