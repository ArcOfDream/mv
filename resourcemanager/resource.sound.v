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
	if h := rm.get_handle(name) {
		return h
	}

	s := rl.load_sound(path)
	if !rl.is_sound_valid(s) {
		return none
	}

	return rm.add(name, SoundResource{ snd: s })
}

// load_from_rres loads a WAVE chunk named rres_name, converts it to a Sound
// via an intermediate Wave, and registers it under name.
pub fn (mut rm ResourceManager[SoundResource]) load_from_rres(loader &rres.RresLoader, name string, rres_name string) ?Handle[SoundResource] {
	if h := rm.get_handle(name) {
		return h
	}

	raw_chunk := loader.load_single(rres_name)
	if chunk := raw_chunk {
		defer { chunk.unload() }
	
		wave := rres.load_wave_from_resource(chunk)
		if !rl.is_wave_valid(wave) {
			return none
		}
	
		snd := rl.load_sound_from_wave(wave)
		rl.unload_wave(wave)
	
		if !rl.is_sound_valid(snd) {
			return none
		}
	
		return rm.add(name, SoundResource{ snd: snd })
	}
	
	return none
}