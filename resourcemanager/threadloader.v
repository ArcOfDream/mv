module resourcemanager

import raylib as rl
import arrays as arr
import rres { RresLoader }
import os
import time

pub struct RresSource {
pub:
	key     string
	aux_key string
}

pub struct FileSource {
pub:
	path     string
	aux_path string
}

pub type LoadSource = RresSource | FileSource

pub struct ShaderFile {
pub:
	vs string
	fs string
}

pub type DataContent = rl.Image | rl.Wave | ShaderFile | []u8

pub enum LoadKind {
	texture
	sound
	shader
	data
}

pub struct LoadCommand {
pub:
	name   string // key to be used by ResourceManager
	kind   LoadKind
	source LoadSource
}

pub struct LoadEvent {
pub:
	name    string // echoed back from LoadComand
	content DataContent
	err     string
}

@[heap]
pub struct ThreadLoader {
pub:
	rres_path ?string
	commands  chan LoadCommand
	events    chan LoadEvent
mut:
	loader ?RresLoader
	closed bool
}

pub fn ThreadLoader.new(rres_path ?string) &ThreadLoader {
	mut tl := &ThreadLoader{
		rres_path: rres_path
		commands:  chan LoadCommand{cap: 64}
		events:    chan LoadEvent{cap: 64}
	}
	go tl.worker()
	return tl
}

pub fn (tl &ThreadLoader) is_closed() bool {
	return tl.closed
}

pub fn (mut tl ThreadLoader) shutdown() {
	if !tl.closed {
		tl.closed = true
		tl.commands.close()
	}
}

pub fn (tl &ThreadLoader) request(cmd LoadCommand) bool {
	if tl.closed {
		return false
	}
	select {
		tl.commands <- cmd {
			return true
		}
		else {
			return false
		}
	}
	return false
}

// drains all currently available events without blocking.
// call once per frame; pass the results to your ResourceManager
pub fn (tl &ThreadLoader) poll_events() []LoadEvent {
	mut ready := []LoadEvent{}
	for {
		select {
			event := <-tl.events {
				ready << event
			}
			else {
				break
			}
		}
	}
	return ready
}

fn (mut tl ThreadLoader) worker() {
	if path := tl.rres_path {
		tl.loader = RresLoader.new(path) or {
			eprintln('threadloader: failed to open ${path}')
			return
		}
	}

	for {
		cmd := <-tl.commands or { break }
		match cmd.source {
			RresSource { tl.dispatch_rres(cmd, cmd.source) }
			FileSource { tl.dispatch_file(cmd, cmd.source) }
		}
	}

	if mut l := tl.loader {
		l.unload()
		tl.loader = none
	}
}

fn (tl &ThreadLoader) dispatch_rres(cmd LoadCommand, src RresSource) {
	loader := tl.loader or {
		tl.send_err(cmd.name, 'rres loader not initialised')
		return
	}

	match cmd.kind {
		.texture {
			if chunk := loader.load_single(src.key) {
				defer { chunk.unload() }
				img := rres.load_image_from_resource(chunk)
				if rl.is_image_valid(img) {
					tl.events <- LoadEvent{
						name:    cmd.name
						content: img
					}
					return
				}
			}
			tl.send_err(cmd.name, 'failed to load texture chunk: ${src.key}')
		}
		.sound {
			if chunk := loader.load_single(src.key) {
				defer { chunk.unload() }
				wave := rres.load_wave_from_resource(chunk)
				if rl.is_wave_valid(wave) {
					tl.events <- LoadEvent{
						name:    cmd.name
						content: wave
					}
					return
				}
			}
			tl.send_err(cmd.name, 'failed to load sound chunk: ${src.key}')
		}
		.shader {
			mut vs := src.key
			mut fs := src.aux_key
			if vs != '' {
				if chunk := loader.load_single(src.key) {
					vs = rres.load_text_from_resource(chunk)
					chunk.unload()
				}
			}
			if fs != '' {
				if chunk := loader.load_single(src.aux_key) {
					fs = rres.load_text_from_resource(chunk)
					chunk.unload()
				}
			}
			tl.events <- LoadEvent{
				name:    cmd.name
				content: ShaderFile{
					vs: vs
					fs: fs
				}
			}
		}
		.data {
			if chunk := loader.load_single(src.key) {
				defer { chunk.unload() }
				bytes, size := rres.load_data_from_resource(chunk)
				tl.events <- LoadEvent{
					name:    cmd.name
					content: unsafe { arr.carray_to_varray[u8](bytes, int(size)) }
				}
				return
			}
			tl.send_err(cmd.name, 'failed to load data chunk: ${src.key}')
		}
	}
}

fn (tl &ThreadLoader) dispatch_file(cmd LoadCommand, src FileSource) {
	match cmd.kind {
		.texture {
			img := rl.load_image(src.path)
			if rl.is_image_valid(img) {
				tl.events <- LoadEvent{
					name:    cmd.name
					content: img
				}
				return
			}
			tl.send_err(cmd.name, 'failed to load image: ${src.path}')
		}
		.sound {
			wave := rl.load_wave(src.path)
			if rl.is_wave_valid(wave) {
				tl.events <- LoadEvent{
					name:    cmd.name
					content: wave
				}
				return
			}
			tl.send_err(cmd.name, 'failed to load wave: ${src.path}')
		}
		.shader {
			vs := if src.path != '' { os.read_file(src.path) or { '' } } else { '' }
			fs := if src.aux_path != '' { os.read_file(src.aux_path) or { '' } } else { '' }
			tl.events <- LoadEvent{
				name:    cmd.name
				content: ShaderFile{
					vs: vs
					fs: fs
				}
			}
		}
		.data {
			bytes := os.read_bytes(src.path) or {
				tl.send_err(cmd.name, 'failed to read file: ${src.path}')
				return
			}
			tl.events <- LoadEvent{
				name:    cmd.name
				content: bytes
			}
		}
	}
}

fn (tl &ThreadLoader) send_err(name string, msg string) {
	tl.events <- LoadEvent{
		name: name
		err:  msg
	}
}
