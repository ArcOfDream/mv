module rres

// RresLoader holds an open .rres file path and its Central Directory.
// Construct once, pass to as many load_from_rres calls as needed, then
// call unload() when all loads are complete.
//
// Example:
//   mut loader := mv.new_rres_loader('assets.rres') or { panic('missing assets') }
//   defer { loader.unload() }
//
//   tex := rm_tex.load_from_rres(loader, 'hero', 'textures/hero.png') or { ... }
//   snd := rm_snd.load_from_rres(loader, 'jump', 'audio/jump.wav')    or { ... }
pub struct RresLoader {
pub:
	file_path string
pub mut:
	dir CentralDir
}

// opens file_path and loads its Central Directory.
// returns none if the file has no Central Directory (count == 0).
pub fn RresLoader.new(file_path string) ?RresLoader {
	dir := load_central_directory(file_path)
	if dir.count == 0 {
		return none
	}
	return RresLoader{
		file_path: file_path
		dir:       dir
	}
}

// unload frees the Central Directory. Call after all loads are complete.
pub fn (loader RresLoader) unload() {
	loader.dir.unload()
}

// chunk_id resolves rres_name to a resource id via the Central Directory.
// Returns none if the name is absent.
pub fn (loader RresLoader) chunk_id(rres_name string) ?u32 {
	id := loader.dir.get_resource_id(rres_name)
	if id == 0 {
		return none
	}
	return id
}

// load_single loads a single chunk by rres_name and unpacks it in-place if
// needed. The caller is responsible for calling chunk.unload().
pub fn (loader RresLoader) load_single(rres_name string) ?ResourceChunk {
	id := loader.chunk_id(rres_name) or { return none }
	mut chunk := load_resource_chunk(loader.file_path, id)
	if chunk.is_compressed() || chunk.is_encrypted() {
		if !chunk.unpack() {
			chunk.unload()
			return none
		}
	}
	return chunk
}

// load_multi loads all chunks for rres_name and unpacks each one in-place.
// Unpacking is performed via a direct pointer into the C-owned chunk array —
// working on copies would leave the original packed buffers untouched, so
// LoadFontFromResource / LoadMeshFromResource would receive stale data.
// The caller is responsible for calling multi.unload().
pub fn (loader RresLoader) load_multi(rres_name string) ?ResourceMulti {
	id := loader.chunk_id(rres_name) or { return none }
	multi := load_resource_multi(loader.file_path, id)
	if multi.count == 0 {
		multi.unload()
		return none
	}

	mut chunks := multi.chunks_slice()
	for mut c in chunks {
		if c.is_compressed() || c.is_encrypted() {
			if !c.unpack() {
				multi.unload()
				return none
			}
		}
	}

	return multi
}
