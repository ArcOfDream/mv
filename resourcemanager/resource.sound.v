module resourcemanager

import raylib as rl
import rres

pub struct SoundResource {
pub:
	snd rl.Sound
}

fn (sr SoundResource) unload() {
	rl.unload_sound(sr.snd)
}

pub fn (mut rm ResourceManager[SoundResource]) load(name string, path string) ?Handle[SoundResource] {
	return rm.acquire_or_insert(name, fn [path] () ?SoundResource {
		s := rl.load_sound(path)
		if !rl.is_sound_valid(s) {
			return none
		}
		return SoundResource{ snd: s }
	})
}

// load_from_wave converts wave into a Sound and registers it under name.
pub fn (mut rm ResourceManager[SoundResource]) load_from_wave(name string, wave rl.Wave) ?Handle[SoundResource] {
	defer { rl.unload_wave(wave) }
	return rm.acquire_or_insert(name, fn [wave] () ?SoundResource {
		snd := rl.load_sound_from_wave(wave)
		if !rl.is_sound_valid(snd) {
			return none
		}
		return SoundResource{ snd: snd }
	})
}

// load_from_rres loads a WAVE chunk named rres_name, converts it to a Sound
// via an intermediate Wave, and registers it under name.
pub fn (mut rm ResourceManager[SoundResource]) load_from_rres(loader &rres.RresLoader, name string, rres_name string) ?Handle[SoundResource] {
	return rm.acquire_or_insert(name, fn [loader, rres_name] () ?SoundResource {
		chunk := loader.load_single(rres_name) or { return none }
		defer { chunk.unload() }

		wave := rres.load_wave_from_resource(chunk)
		if !rl.is_wave_valid(wave) {
			return none
		}
		defer { rl.unload_wave(wave) }

		snd := rl.load_sound_from_wave(wave)
		if !rl.is_sound_valid(snd) {
			return none
		}
		return SoundResource{ snd: snd }
	})
}
