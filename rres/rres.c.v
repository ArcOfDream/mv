module rres

import arrays as arr

// rresFileHeader — the 16-byte file header at the start of every .rres file.
pub struct C.rresFileHeader {
pub:
	id         [4]u8 // Magic bytes: 'r','r','e','s'
	version    u16   // Format version × 100  (100 == v1.0)
	chunkCount u16   // Number of resource chunks that follow
	cdOffset   u32   // Byte offset of the Central Directory (0 if absent)
	reserved   u32
}

// rresResourceChunkInfo — 32-byte per-chunk header describing one resource.
pub struct C.rresResourceChunkInfo {
pub:
	// Note: 'type' is a V keyword, accessed as @type or via the wrapper struct.
	@type      [4]u8 // FourCC data-type code, e.g. "IMGE", "TEXT", "WAVE" …
	id         u32   // CRC32 of the original filename → unique resource id
	compType   u8    // Compression algorithm (see CompressionType)
	cipherType u8    // Encryption algorithm  (see CipherType)
	flags      u16   // Reserved flags
	packedSize u32   // Byte size of the data as stored (after comp/enc)
	baseSize   u32   // Byte size of the data uncompressed/unencrypted
	nextOffset u32   // File offset of the next linked chunk (0 = no more)
	reserved   u8
	propCount  u8  // Number of u32 properties that precede the raw bytes
	crc32      u32 // CRC32 over (propCount + props[] + raw)
}

// rresResourceChunkData — the actual payload following a chunk info header.
pub struct C.rresResourceChunkData {
pub:
	propCount u32     // Mirror of info.propCount after loading
	props     &u32    // Array of propCount u32 property values (heap-allocated)
	raw       voidptr // Raw byte payload (heap-allocated, size = info.baseSize – props)
}

// rresResourceChunk — a complete loaded resource chunk (info + data).
pub struct C.rresResourceChunk {
pub:
	info ChunkInfo
	data ChunkData
}

// rresResourceMulti — a set of chunks that all share the same resource id.
// (e.g. a TTF font produces an image chunk + a glyph-info chunk.)
pub struct C.rresResourceMulti {
pub:
	count  u32                  // Number of chunks in this multi-resource
	chunks &ResourceChunk // Heap-allocated array of 'count' chunks
}

// rresDirEntry — one record inside the Central Directory.
pub struct C.rresDirEntry {
pub:
	id       u32 // Resource id (same CRC32 as in chunk info)
	offset   u32 // Absolute byte offset of the chunk in the file
	reserved u32
	fileName [256]u8 // Null-terminated original filename (max 255 chars)
}

// rresCentralDir — the optional Central Directory appended to .rres files.
pub struct C.rresCentralDir {
pub:
	count   u32             // Number of directory entries
	entries &DirEntry // Heap-allocated array of 'count' entries
}

// rresFontGlyphInfo — per-glyph metrics stored in a FNTG chunk.
pub struct C.rresFontGlyphInfo {
pub:
	x        int // Glyph rectangle x in the atlas
	y        int // Glyph rectangle y in the atlas
	width    int
	height   int
	value    int // Unicode codepoint
	offsetX  int
	offsetY  int
	advanceX int
}

pub type FileHeader = C.rresFileHeader
pub type ChunkInfo = C.rresResourceChunkInfo
pub type ChunkData = C.rresResourceChunkData
pub type ResourceChunk = C.rresResourceChunk
pub type ResourceMulti = C.rresResourceMulti
pub type DirEntry = C.rresDirEntry
pub type CentralDir = C.rresCentralDir
pub type FontGlyphInfo = C.rresFontGlyphInfo

fn C.rresLoadResourceChunk(fileName &u8, rresId u32) ResourceChunk
fn C.rresLoadResourceMulti(fileName &u8, rresId u32) ResourceMulti
fn C.rresLoadCentralDirectory(fileName &u8) CentralDir

fn C.rresUnloadResourceChunk(chunk ResourceChunk)
fn C.rresUnloadResourceMulti(multi ResourceMulti)
fn C.rresUnloadCentralDirectory(dir CentralDir)

fn C.rresGetResourceId(dir CentralDir, fileName &u8) u32

fn C.rresComputeCRC32(data &u8, len int) u32
fn C.rresSetCipherPassword(pass &u8)
fn C.rresGetCipherPassword() &u8

pub enum ResourceDataType {
	null
	raw
	text
	image
	wave
	vertex
	font_glyphs
	link      = 99
	directory = 100
}

pub enum CompressionType {
	none
	deflate = 8
	lz4     = 32
}

pub enum CipherType {
	none
	xor
	aes128
	aes256
	chacha20
}

pub enum TextEncoding {
	undefined
	utf8
	utf8_bom
	utf16_le
	utf16_be
}

pub enum CodeLang {
	undefined
	glsl
	hlsl
	msl
	wgsl
	spirv
	lua
	python
	javascript
	custom
}

pub enum PixelFormat {
	undefined
	grayscale
	gray_alpha
	r5g6b5
	r8g8b8
	r5g5b5a1
	r4g4b4a4
	r8g8b8a8
	r32
	r32g32b32
	r32g32b32a32
	dxt1_rgb
	dxt1_rgba
	dxt3_rgba
	dxt5_rgba
	etc1_rgb
	etc2_rgb
	etc2_eac_rgba
	pvrt_rgb
	pvrt_rgba
	astc_4x4_rgba
	astc_8x8_rgba
}

pub enum VertexAttribute {
	position
	texcoord1
	texcoord2
	normal
	tangent
	color
	indices
	custom
}

pub enum VertexFormat {
	ubyte
	byte_
	ushort
	short
	uint
	int_
	half
	float_
	double
}

// unload frees the C-heap memory owned by this chunk
pub fn (chunk ResourceChunk) unload() {
	C.rresUnloadResourceChunk(ResourceChunk(chunk))
}

// data_type decodes the FourCC field and returns the matching ResourceDataType
pub fn (chunk &ResourceChunk) data_type() ResourceDataType {
	return fourcc_to_data_type(chunk.info.@type)
}

// is_compressed returns true when the chunk payload is compressed
pub fn (chunk &ResourceChunk) is_compressed() bool {
	return CompressionType.from(chunk.info.compType) or { CompressionType.none } != CompressionType.none
}

// is_encrypted returns true when the chunk payload is encrypted
pub fn (chunk &ResourceChunk) is_encrypted() bool {
	return CipherType.from(chunk.info.cipherType) or { CipherType.none } != CipherType.none
}

// props returns the property array as a V slice (view into C-owned memory)
// do not use after calling unload()
pub fn (chunk &ResourceChunk) props() []u32 {
	count := int(chunk.data.propCount)
	if count == 0 {
		return []
	}
	return unsafe { arr.carray_to_varray[u32](chunk.data.props, count) }
}

// font_glyphs interprets the raw payload of a FNTG chunk as []FontGlyphInfo.
// Returns an empty slice when the chunk is not of type font_glyphs.
pub fn (chunk &ResourceChunk) font_glyphs() []FontGlyphInfo {
    if chunk.data_type() != .font_glyphs {
        return []
    }
    prop_bytes := u32(4) + chunk.data.propCount * u32(4)
    raw_bytes  := chunk.info.baseSize - prop_bytes
    count      := int(raw_bytes) / int(sizeof(FontGlyphInfo))
    return unsafe { arr.carray_to_varray[FontGlyphInfo](chunk.data.raw, count) }
}

// ResourceMulti methods

// unload frees the C-heap memory owned by this multi-resource.
pub fn (multi ResourceMulti) unload() {
	C.rresUnloadResourceMulti(ResourceMulti(multi))
}

// chunk returns the i-th ResourceChunk.  Panics if i is out of range.
pub fn (multi &ResourceMulti) chunk(i int) ResourceChunk {
	if i < 0 || u32(i) >= multi.count {
		panic('rres: ResourceMulti.chunk(${i}) out of range (count=${multi.count})')
	}
	return unsafe { ResourceChunk(multi.chunks[i]) }
}

// chunks_slice returns all chunks as a V slice (view into C-owned memory).
// Do not use after calling unload().
pub fn (multi &ResourceMulti) chunks_slice() []ResourceChunk {
	if multi.count == 0 {
		return []
	}
	return unsafe { arr.carray_to_varray[ResourceChunk](multi.chunks, int(multi.count)) }
}

// CentralDir methods

// unload frees the C-heap memory owned by this central directory
pub fn (dir CentralDir) unload() {
	C.rresUnloadCentralDirectory(CentralDir(dir))
}

// get_resource_id looks up the resource id (CRC32) for a given filename
// Returns 0 if the filename is not present in the directory
pub fn (dir CentralDir) get_resource_id(file_name string) u32 {
	return C.rresGetResourceId(CentralDir(dir), file_name.str)
}

// find returns the DirEntry whose filename matches, or none if absent
pub fn (dir &CentralDir) find(file_name string) ?DirEntry {
	for i in 0 .. int(dir.count) {
		entry := unsafe { dir.entries[i] }
		if unsafe { tos_clone(&entry.fileName[0]) } == file_name {
			return DirEntry(entry)
		}
	}
	return none
}

// entries_slice returns all directory entries as a V slice (view into C-owned memory)
// do not use after calling unload()
pub fn (dir &CentralDir) entries_slice() []DirEntry {
	if dir.count == 0 {
		return []
	}
	return unsafe{ arr.carray_to_varray[DirEntry](dir.entries, int(dir.count)) }
}

// DirEntry methods

// file_name returns the entry's stored filename as a V string
pub fn (e &DirEntry) file_name() string {
	return unsafe { tos_clone(&e.fileName[0]) }
}

// loading functions

// load_resource_chunk loads a single resource chunk from file_name by its id
// If the resource has multiple linked chunks, only the first is returned;
// use load_resource_multi to get all of them
pub fn load_resource_chunk(file_name string, rres_id u32) ResourceChunk {
    chunk := C.rresLoadResourceChunk(file_name.str, rres_id)
    return ResourceChunk(chunk)
}

// load_resource_multi loads all chunks sharing rres_id from file_name
pub fn load_resource_multi(file_name string, rres_id u32) ResourceMulti {
    multi := C.rresLoadResourceMulti(file_name.str, rres_id)
    return ResourceMulti(multi)
}

// load_central_directory loads the Central Directory from file_name
// returns an empty CentralDir (count == 0) if the file has no directory
pub fn load_central_directory(file_name string) CentralDir {
    dir := C.rresLoadCentralDirectory(file_name.str)
    return CentralDir(dir)
}

// utility functions

// compute_crc32 computes the CRC32 of data, matching rres's internal hash
// useful for deriving resource ids without a Central Directory
pub fn compute_crc32(data []u8) u32 {
	if data.len == 0 {
		return 0
	}
	return C.rresComputeCRC32(data.data, data.len)
}

// resource_id_for returns the rres resource id (CRC32) for a filename string
pub fn resource_id_for(file_name string) u32 {
	return compute_crc32(file_name.bytes())
}

// set_cipher_password sets the password used to decrypt encrypted chunks
// must be called before loading any encrypted resource
pub fn set_cipher_password(pass string) {
	C.rresSetCipherPassword(pass.str)
}

// get_cipher_password returns the currently active cipher password, or '' if none
pub fn get_cipher_password() string {
	ptr := C.rresGetCipherPassword()
	if ptr == unsafe { nil } {
		return ''
	}
	return unsafe { tos_clone(ptr) }
}

// fourcc_str returns a FourCC byte array as a printable 4-character string
pub fn fourcc_str(t [4]u8) string {
	return '${t[0]:c}${t[1]:c}${t[2]:c}${t[3]:c}'
}

// internal helpers

fn fourcc_to_data_type(t [4]u8) ResourceDataType {
	if t[0] == 0 && t[1] == 0 && t[2] == 0 && t[3] == 0 {
		return .null
	}
	match true {
		t[0] == `R` && t[1] == `A` && t[2] == `W` && t[3] == `D` { return .raw }
		t[0] == `T` && t[1] == `E` && t[2] == `X` && t[3] == `T` { return .text }
		t[0] == `I` && t[1] == `M` && t[2] == `G` && t[3] == `E` { return .image }
		t[0] == `W` && t[1] == `A` && t[2] == `V` && t[3] == `E` { return .wave }
		t[0] == `V` && t[1] == `R` && t[2] == `T` && t[3] == `X` { return .vertex }
		t[0] == `F` && t[1] == `N` && t[2] == `T` && t[3] == `G` { return .font_glyphs }
		t[0] == `L` && t[1] == `I` && t[2] == `N` && t[3] == `K` { return .link }
		t[0] == `C` && t[1] == `D` && t[2] == `I` && t[3] == `R` { return .directory }
		else { return .null }
	}
}
