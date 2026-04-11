module rres

import raylib as rl

// Raw / text
fn C.LoadDataFromResource(chunk ResourceChunk, size &u32) voidptr
fn C.LoadTextFromResource(chunk ResourceChunk) &u8

// Single-chunk raylib types
fn C.LoadImageFromResource(chunk ResourceChunk) rl.Image
fn C.LoadWaveFromResource(chunk ResourceChunk) rl.Wave

// Multi-chunk raylib types
fn C.LoadFontFromResource(multi ResourceMulti) rl.Font
fn C.LoadMeshFromResource(multi ResourceMulti) rl.Mesh

// Decompression / decryption — mutates the chunk in-place
fn C.UnpackResourceChunk(chunk &ResourceChunk) int

// Base directory for LINK chunk resolution
fn C.SetBaseDirectory(baseDir &u8)

// raylib allocator — rres-raylib.h allocates with RL_MALLOC, so we must
// pair every LoadData/LoadText call with RL_FREE (= raylib's MemFree).
fn C.MemFree(ptr voidptr)

// unpack decompresses and/or decrypts the chunk payload in-place.
// Returns true on success (the underlying C function returns 0 for success).
// Must be called before passing a compressed or encrypted chunk to any loader.
pub fn (mut chunk ResourceChunk) unpack() bool {
	return C.UnpackResourceChunk(&chunk) == 0
}

pub fn load_data_from_resource(chunk ResourceChunk) (voidptr, u32) {
	mut bytesize := u32(0)

	return C.LoadDataFromResource(chunk, &bytesize), bytesize
}

pub fn load_text_from_resource(chunk ResourceChunk) string {
	ptr := C.LoadTextFromResource(chunk)
	if ptr == unsafe { nil } {
		return ''
	}
	result := unsafe { tos_clone(ptr) }
	C.MemFree(ptr)
	return result
}

pub fn load_image_from_resource(chunk ResourceChunk) rl.Image {
	return C.LoadImageFromResource(chunk)
}

pub fn load_wave_from_resource(chunk ResourceChunk) rl.Wave {
	return C.LoadWaveFromResource(chunk)
}

pub fn load_font_from_resource(multi ResourceMulti) rl.Font {
	return C.LoadFontFromResource(multi)
}

pub fn load_mesh_from_resource(multi ResourceMulti) rl.Mesh {
	return C.LoadMeshFromResource(multi)
}

// set_base_directory sets the base path used when resolving LINK chunks
// (chunks that reference an external file path rather than embedded data).
// Pass '' to reset to the default (current working directory).
pub fn set_base_directory(base_dir string) {
	if base_dir == '' {
		C.SetBaseDirectory(unsafe { nil })
	} else {
		C.SetBaseDirectory(base_dir.str)
	}
}
