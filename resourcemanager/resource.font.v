module resourcemanager

import raylib as rl
import rres

pub struct FontResource {
pub:
	fnt rl.Font
}

fn (fr FontResource) unload() {
	rl.unload_font(fr.fnt)
}

// load loads a font directly from a file path via raylib.
pub fn (mut rm ResourceManager[FontResource]) load(name string, path string) ?Handle[FontResource] {
	if h := rm.get_handle(name) {
		return h
	}

	f := rl.load_font(path)
	if !rl.is_font_valid(f) {
		return none
	}

	return rm.add(name, FontResource{ fnt: f })
}

// load_from_rres loads a multi-chunk font resource (IMGE atlas + FNTG glyph
// data) named rres_name and registers it under name.
pub fn (mut rm ResourceManager[FontResource]) load_from_rres(loader &rres.RresLoader, name string, rres_name string) ?Handle[FontResource] {
	if h := rm.get_handle(name) {
		return h
	}

	if multi := loader.load_multi(rres_name) {
		defer { multi.unload() }

		fnt := rres.load_font_from_resource(multi)
		if !rl.is_font_valid(fnt) {
			return none
		}

		return rm.add(name, FontResource{ fnt: fnt })
	}

	return none
}
