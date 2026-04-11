module pxtn

import os

// MPXTN is an opaque handle
@[typedef]
struct C.MPXTN {}

fn C.mpxtn_fread(fp &C.FILE, err &int) &C.MPXTN
fn C.mpxtn_mread(p voidptr, size usize, err &int) &C.MPXTN
fn C.mpxtn_vomit(buffer voidptr, count usize, mp &C.MPXTN) usize
fn C.mpxtn_seek(mp &C.MPXTN, smp_num usize) bool
fn C.mpxtn_reset(mp &C.MPXTN) bool
fn C.mpxtn_get_total_samples(mp &C.MPXTN) usize
fn C.mpxtn_get_current_sample(mp &C.MPXTN) usize
fn C.mpxtn_get_repeat_sample(mp &C.MPXTN) usize
fn C.mpxtn_set_loop(mp &C.MPXTN, loop bool)
fn C.mpxtn_get_loop(mp &C.MPXTN) bool
fn C.mpxtn_close(mp &C.MPXTN)

// public interface
pub type Pxtone = C.MPXTN

// from_memory loads a .ptcop from a raw memory slice.
// this is the primary entry point when using ResourceManager
pub fn from_memory(data []u8) !&Pxtone {
	mut err := 0
	handle := C.mpxtn_mread(data.data, usize(data.len), &err)
	if handle == unsafe { nil } {
		return error('mpxtn_mread failed (err=${err})')
	}
	return handle
}

// from_file loads a .ptcop directly from a file path.
pub fn from_file(path string) !&Pxtone {
	fp := os.vfopen(path, 'rb')!
	defer { C.fclose(fp) }

	mut err := 0
	handle := C.mpxtn_fread(fp, &err)
	if handle == unsafe { nil } {
		return error('mpxtn_fread failed (err=${err})')
	}

	return handle
}

// gen_buffer decodes up to count sample frames into buffer.
// Each frame is 4 bytes (stereo s16 LE, 44100 Hz).
// Returns the number of frames actually written;
// a return value less than count means playback has ended.
pub fn (p &Pxtone) gen_buffer(buffer voidptr, count usize) usize {
	return C.mpxtn_vomit(buffer, count, p)
}

// seek moves the playback position to smp_num sample frames from the start.
pub fn (p &Pxtone) seek(smp_num usize) bool {
	return C.mpxtn_seek(p, smp_num)
}

// reset returns playback to the beginning.
pub fn (p &Pxtone) reset() bool {
	return C.mpxtn_reset(p)
}

pub fn (p &Pxtone) total_samples() usize {
	return C.mpxtn_get_total_samples(p)
}

pub fn (p &Pxtone) current_sample() usize {
	return C.mpxtn_get_current_sample(p)
}

// repeat_sample returns the sample frame the track loops back to.
// Use this with seek() to implement the intro→loop structure
// common in .ptcop files.
pub fn (p &Pxtone) repeat_sample() usize {
	return C.mpxtn_get_repeat_sample(p)
}

pub fn (p &Pxtone) set_loop(loop bool) {
	C.mpxtn_set_loop(p, loop)
}

pub fn (p &Pxtone) get_loop() bool {
	return C.mpxtn_get_loop(p)
}

// close frees all resources held by the decoder.
// Call this when you are done with the Pxtone instance.
pub fn (p &Pxtone) close() {
	C.mpxtn_close(p)
}
