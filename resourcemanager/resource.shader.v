module resourcemanager

import raylib as rl
import rres

pub struct ShaderResource {
pub:
	shd rl.Shader
}

fn (sr ShaderResource) unload() {
	rl.unload_shader(sr.shd)
}

pub fn (mut rm ResourceManager[ShaderResource]) load(name string, vs string, fs string) ?Handle[ShaderResource] {
	if h := rm.get_handle(name) {
		return h
	}

	s := rl.load_shader(vs, fs)
	if s.id <= 0 {
		return none
	}

	return rm.add(name, ShaderResource{ shd:s })
}

// load_from_rres loads two TEXT chunks (vs_rres_name for the vertex shader,
// fs_rres_name for the fragment shader) and compiles them into a Shader.
// Pass '' for either name to use raylib's default shader for that stage.
pub fn (mut rm ResourceManager[ShaderResource]) load_from_rres(loader &rres.RresLoader, name string, vs_rres_name string, fs_rres_name string) ?Handle[ShaderResource] {
	if h := rm.get_handle(name) {
		return h
	}
	
	mut vs_src := vs_rres_name
	mut fs_src := fs_rres_name
	
	if vs_src != '' {
		if chunk := loader.load_single(vs_rres_name) {
			vs_src = rres.load_text_from_resource(chunk)
			chunk.unload()
		}
	}
	
	if fs_src != '' {
		if chunk := loader.load_single(fs_rres_name) {
			fs_src = rres.load_text_from_resource(chunk)
			chunk.unload()
		}
	}

	shd := rl.load_shader_from_memory(vs_src, fs_src)
	if shd.id <= 0 {
		return none
	}

	return rm.add(name, ShaderResource{ shd: shd })
}