module tfd

import raylib as rl

#flag -I @VMODROOT/lib/tfd
#flag @VMODROOT/lib/tfd/tinyfiledialogs.c
#include "tinyfiledialogs.h"

fn C.tinyfd_openFileDialog(title &char, default_path &char, num_filters int, filter_patterns &&char, single_desc &char, allow_multi int) &char
fn C.tinyfd_saveFileDialog(title &char, default_path &char, num_filters int, filter_patterns &&char, single_desc &char) &char
fn C.tinyfd_selectFolderDialog(title &char, default_path &char) &char

// open_file shows native open-file dialog. Returns empty string on cancel.
pub fn open_file(title string, default_path string) string {
	result := C.tinyfd_openFileDialog(title.str, default_path.str, 0, unsafe { nil },
		unsafe { nil }, 0)
	drain_drops()
	if result == unsafe { nil } {
		return ''
	}
	return unsafe { result.vstring() }
}

// open_file_filtered shows native open-file dialog with filter patterns. Returns empty string on cancel.
pub fn open_file_filtered(title string, default_path string, patterns []string, desc string) string {
	if patterns.len == 0 {
		return open_file(title, default_path)
	}
	ptrs := patterns.map(it.str)
	result := C.tinyfd_openFileDialog(title.str, default_path.str, patterns.len, unsafe { &&char(ptrs.data) },
		desc.str, 0)
	drain_drops()
	if result == unsafe { nil } {
		return ''
	}
	return unsafe { result.vstring() }
}

// save_file shows native save-file dialog. Returns empty string on cancel.
pub fn save_file(title string, default_path string) string {
	result := C.tinyfd_saveFileDialog(title.str, default_path.str, 0, unsafe { nil },
		unsafe { nil })
	drain_drops()
	if result == unsafe { nil } {
		return ''
	}
	return unsafe { result.vstring() }
}

// select_folder shows native folder-picker dialog. Returns empty string on cancel.
pub fn select_folder(title string, default_path string) string {
	result := C.tinyfd_selectFolderDialog(title.str, default_path.str)
	drain_drops()
	if result == unsafe { nil } {
		return ''
	}
	return unsafe { result.vstring() }
}

// drain_drops discards file-drop events queued while native dialog was open.
// On some Linux backends (GTK/zenity) tinyfiledialogs triggers raylib's drop
// handler with the selected path as a side-effect.
pub fn drain_drops() {
	if rl.is_file_dropped() {
		dropped := rl.load_dropped_files()
		rl.unload_dropped_files(dropped)
	}
}
