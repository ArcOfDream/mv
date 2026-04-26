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
// Use this with seek() to implement the intro->loop structure
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

// --- metadata / note extraction ---

#include "mpxtn.h"

@[typedef]
struct C.MPXTN_EVENTREC {
	clock   i32
	value   i32
	kind    u8
	unit_no u8
}

fn C.mpxtn_get_beat_num(mp &C.MPXTN) u32
fn C.mpxtn_get_beat_tempo(mp &C.MPXTN) f32
fn C.mpxtn_get_beat_clock(mp &C.MPXTN) u32
fn C.mpxtn_get_meas_num(mp &C.MPXTN) u32
fn C.mpxtn_get_meas_repeat(mp &C.MPXTN) u32
fn C.mpxtn_get_unit_num(mp &C.MPXTN) u32
fn C.mpxtn_get_event_num(mp &C.MPXTN) u32
fn C.mpxtn_copy_events(mp &C.MPXTN, buf &C.MPXTN_EVENTREC, count u32) bool

// EventKind mirrors the MPXTN_EK_* constants from the C header.
pub enum EventKind as u8 {
	on         = 1
	key        = 2
	pan_volume = 3
	velocity   = 4
	volume     = 5
	portament  = 6
	voice_no   = 12
	group_no   = 13
	tuning     = 14
	pan_time   = 15
}

// Master holds the tempo and time signature data for a .ptcop file.
pub struct Master {
pub:
	beat_num    u32 // beats per measure
	beat_tempo  f32 // BPM
	beat_clock  u32 // clocks per beat (resolution)
	meas_num    u32 // total measures
	meas_repeat u32 // loop start measure
}

// EventRecord is a single event from the event list.
pub struct EventRecord {
pub:
	clock   i32
	value   i32
	kind    EventKind
	unit_no u8
}

// Note is a reconstructed note-on event with its context resolved.
// key is a raw PxTone key value; subtract pxtn.basickey to get the semitone
// offset from A4, then divide by 256 to get whole semitones.
pub struct Note {
pub:
	unit_no  u8
	clock    i32 // start clock
	duration i32 // length in clocks (from EVENTKIND_ON value)
	key      i32 // raw key value (sticky, last KEY event before this ON)
	velocity i32 // raw velocity (sticky, last VELOCITY event before this ON)
}

// basickey is the raw key value that corresponds to A4 (440 Hz).
pub const basickey = i32(0x4500)

// master returns the tempo and time signature metadata.
pub fn (p &Pxtone) master() Master {
	return Master{
		beat_num:    C.mpxtn_get_beat_num(p)
		beat_tempo:  C.mpxtn_get_beat_tempo(p)
		beat_clock:  C.mpxtn_get_beat_clock(p)
		meas_num:    C.mpxtn_get_meas_num(p)
		meas_repeat: C.mpxtn_get_meas_repeat(p)
	}
}

// unit_count returns the number of units (tracks) in the file.
pub fn (p &Pxtone) unit_count() u32 {
	return C.mpxtn_get_unit_num(p)
}

// events returns a copy of the raw event list.
pub fn (p &Pxtone) events() []EventRecord {
	count := C.mpxtn_get_event_num(p)
	if count == 0 {
		return []
	}
	raw := []C.MPXTN_EVENTREC{len: int(count)}
	C.mpxtn_copy_events(p, raw.data, count)
	return raw.map(EventRecord{
		clock:   it.clock
		value:   it.value
		kind:    unsafe { EventKind(it.kind) }
		unit_no: it.unit_no
	})
}

// notes reconstructs Note events by replaying KEY and VELOCITY state per unit.
// key and velocity are sticky: each unit inherits the last set value before
// an ON event, defaulting to A4 (basickey) and 104 respectively.
pub fn (p &Pxtone) notes() []Note {
	n_units := int(p.unit_count())
	if n_units == 0 {
		return []
	}

	mut keys := []i32{len: n_units, init: basickey}
	mut vels := []i32{len: n_units, init: 104} // EVENTDEFAULT_VELOCITY

	mut result := []Note{}
	for ev in p.events() {
		u := int(ev.unit_no)
		if u >= n_units {
			continue
		}
		match ev.kind {
			.key {
				keys[u] = ev.value
			}
			.velocity {
				vels[u] = ev.value
			}
			.on {
				result << Note{
					unit_no:  ev.unit_no
					clock:    ev.clock
					duration: ev.value
					key:      keys[u]
					velocity: vels[u]
				}
			}
			else {}
		}
	}
	return result
}
