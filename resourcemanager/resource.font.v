module resourcemanager

import raylib as rl
import rres
import strings

pub struct FontResource {
pub:
	fnt rl.Font
}

fn (fr FontResource) unload() {
	rl.unload_font(fr.fnt)
}

// load loads a font directly from a file path via raylib.
pub fn (mut rm ResourceManager[FontResource]) load(name string, path string) ?Handle[FontResource] {
	return rm.acquire_or_insert(name, fn [path] () ?FontResource {
		f := rl.load_font(path)
		if !rl.is_font_valid(f) {
			return none
		}
		return FontResource{ fnt: f }
	})
}

// TODO: write an extended version of this function
// ---
// NOTE: raylib expects a unicode character set (runes in V) to be passed as codepoints, but passing nil assumes an ASCII character set
pub fn (mut rm ResourceManager[FontResource]) load_from_memory(name string, size int, data []u8) ?Handle[FontResource] {
	return rm.acquire_or_insert(name, fn [size, data] () ?FontResource {
		//ascii := get_ascii_printable().runes()
		f := rl.load_font_from_memory('.ttf', data.data, data.element_size * (data.len - 1),
			size, unsafe { nil }, 0)
		if !rl.is_font_valid(f) {
			return none
		}
		return FontResource{ fnt: f }
	})
}

// load_from_rres loads a multi-chunk font resource (IMGE atlas + FNTG glyph
// data) named rres_name and registers it under name.
pub fn (mut rm ResourceManager[FontResource]) load_from_rres(loader &rres.RresLoader, name string, rres_name string) ?Handle[FontResource] {
	return rm.acquire_or_insert(name, fn [loader, rres_name] () ?FontResource {
		multi := loader.load_multi(rres_name) or { return none }
		defer { multi.unload() }

		fnt := rres.load_font_from_resource(multi)
		if !rl.is_font_valid(fnt) {
			return none
		}
		return FontResource{ fnt: fnt }
	})
}

// helper function to provide an ascii character set
fn get_ascii_printable() string {
	mut sb := strings.new_builder(95)
	for i in 32 .. 127 {
		sb.write_byte(u8(i))
	}
	return sb.str()
}