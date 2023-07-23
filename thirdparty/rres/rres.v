[translated]
module rres

#include <@VMODROOT/include/rres.h>
#flag "-DRRES_IMPLEMENTATION"

pub const (
	used_import = 1
)

pub struct C.rresFileHeader {
pub:
	id         [4]u8
	version    u16
	chunkCount u16
	cdOffset   u32
	reserved   u32
}

type FileHeader = C.rresFileHeader

pub struct C.rresResourceChunkInfo {
pub mut:
	type_      [4]u8
	id         u32
	compType   CompressionType
	cipherType CipherType
	flags      u16
	packedSize u32
	baseSize   u32
	nextOffset u32
	reserved   u32
	crc32      u32
}

type ResourceChunkInfo = C.rresResourceChunkInfo

pub struct C.rresResourceChunkData {
pub mut:
	propCount u32
	props     &u32
	raw       voidptr
}

type ResourceChunkData = C.rresResourceChunkData

pub struct C.rresResourceChunk {
pub:
	info ResourceChunkInfo
	data ResourceChunkData
}

type ResourceChunk = C.rresResourceChunk

pub struct C.rresResourceMulti {
pub:
	count  u32
	chunks &C.rresResourceChunk
}

type ResourceMulti = C.rresResourceMulti

pub struct C.rresDirEntry {
pub:
	id           u32
	offset       u32
	reserved     u32
	fileNameSize u32
	fileName     [1024]i8
}

type DirEntry = C.rresDirEntry

pub struct C.rresCentralDir {
pub:
	count   u32
	entries &C.rresDirEntry
}

type CentralDir = C.rresCentralDir

pub struct C.rresFontGlyphInfo {
pub:
	x        int
	y        int
	width    int
	height   int
	value    int
	offsetX  int
	offsetY  int
	advanceX int
}

type FontGlyphInfo = C.rresFontGlyphInfo

pub enum ResourceDataType as u8 {
	rres_data_null = 0
	rres_data_raw = 1
	rres_data_text = 2
	rres_data_image = 3
	rres_data_wave = 4
	rres_data_vertex = 5
	rres_data_font_glyphs = 6
	rres_data_link = 99
	rres_data_directory = 100
}

pub enum CompressionType as u8 {
	rres_comp_none = 0
	rres_comp_rle = 1
	rres_comp_deflate = 10
	rres_comp_lz4 = 20
	rres_comp_lzma2 = 30
	rres_comp_qoi = 40
}

pub enum CipherType as u8 {
	rres_cipher_none = 0
	rres_cipher_xor = 1
	rres_cipher_des = 10
	rres_cipher_tdes = 11
	rres_cipher_idea = 20
	rres_cipher_aes = 30
	rres_cipher_aes_gcm = 31
	rres_cipher_xtea = 40
	rres_cipher_blowfish = 50
	rres_cipher_rsa = 60
	rres_cipher_salsa20 = 70
	rres_cipher_chacha20 = 71
	rres_cipher_xchacha20 = 72
	rres_cipher_xchacha20_poly1305 = 73
}

pub enum ErrorType {
	rres_success = 0
	rres_error_file_not_found
	rres_error_file_format
	rres_error_memory_alloc
}

pub enum TextEncoding {
	rres_text_encoding_undefined = 0
	rres_text_encoding_utf8 = 1
	rres_text_encoding_utf8_bom = 2
	rres_text_encoding_utf16_le = 10
	rres_text_encoding_utf16_be = 11
}

pub enum CodeLang {
	rres_code_lang_undefined = 0
	rres_code_lang_c
	rres_code_lang_cpp
	rres_code_lang_cs
	rres_code_lang_lua
	rres_code_lang_js
	rres_code_lang_python
	rres_code_lang_rust
	rres_code_lang_zig
	rres_code_lang_odin
	rres_code_lang_jai
	rres_code_lang_gdscript
	rres_code_lang_glsl
}

pub enum PixelFormat {
	rres_pixelformat_undefined = 0
	rres_pixelformat_uncomp_grayscale = 1
	rres_pixelformat_uncomp_gray_alpha
	rres_pixelformat_uncomp_r5g6b5
	rres_pixelformat_uncomp_r8g8b8
	rres_pixelformat_uncomp_r5g5b5a1
	rres_pixelformat_uncomp_r4g4b4a4
	rres_pixelformat_uncomp_r8g8b8a8
	rres_pixelformat_uncomp_r32
	rres_pixelformat_uncomp_r32g32b32
	rres_pixelformat_uncomp_r32g32b32a32
	rres_pixelformat_comp_dxt1_rgb
	rres_pixelformat_comp_dxt1_rgba
	rres_pixelformat_comp_dxt3_rgba
	rres_pixelformat_comp_dxt5_rgba
	rres_pixelformat_comp_etc1_rgb
	rres_pixelformat_comp_etc2_rgb
	rres_pixelformat_comp_etc2_eac_rgba
	rres_pixelformat_comp_pvrt_rgb
	rres_pixelformat_comp_pvrt_rgba
	rres_pixelformat_comp_astc_4x4_rgba
	rres_pixelformat_comp_astc_8x8_rgba
}

pub enum VertexAttribute {
	rres_vertex_attribute_position = 0
	rres_vertex_attribute_texcoord1 = 10
	rres_vertex_attribute_texcoord2 = 11
	rres_vertex_attribute_texcoord3 = 12
	rres_vertex_attribute_texcoord4 = 13
	rres_vertex_attribute_normal = 20
	rres_vertex_attribute_tangent = 30
	rres_vertex_attribute_color = 40
	rres_vertex_attribute_index = 100
}

pub enum VertexFormat {
	rres_vertex_format_ubyte = 0
	rres_vertex_format_byte
	rres_vertex_format_ushort
	rres_vertex_format_short
	rres_vertex_format_uint
	rres_vertex_format_int
	rres_vertex_format_hfloat
	rres_vertex_format_float
}

pub enum FontStyle {
	rres_font_style_undefined = 0
	rres_font_style_regular
	rres_font_style_bold
	rres_font_style_italic
}

// struct Lldiv_t {
// 	quot i64
// 	rem  i64
// }

// struct Random_data {
// 	fptr      &int
// 	rptr      &int
// 	state     &int
// 	rand_type int
// 	rand_deg  int
// 	rand_sep  int
// 	end_ptr   &int
// }

// struct Drand48_data {
// 	__x     [3]u16
// 	__old_x [3]u16
// 	__c     u16
// 	__init  u16
// 	__a     i64
// }

fn C.rresLoadResourceChunk(filename &u8, rresid int) C.rresResourceChunk

pub fn load_resource_chunk(filename string, rresid int) ResourceChunk {
	return C.rresLoadResourceChunk(filename.str, rresid)
}

fn C.rresUnloadResourceChunk(chunk C.rresResourceChunk)

pub fn unload_resource_chunk(chunk ResourceChunk) {
	C.rresUnloadResourceChunk(chunk)
}

fn C.rresLoadResourceMulti(filename &u8, rresid int) C.rresResourceMulti

pub fn load_resource_multi(filename string, rresid int) ResourceMulti {
	return C.rresLoadResourceMulti(filename.str, rresid)
}

fn C.rresUnloadResourceMulti(multi C.rresResourceMulti)

pub fn unload_resource_multi(multi ResourceMulti) {
	C.rresUnloadResourceMulti(multi)
}

fn C.rresLoadResourceChunkInfo(filename &u8, rresid int) C.rresResourceChunkInfo

pub fn load_resource_chunk_info(filename string, rresid int) ResourceChunkInfo {
	return C.rresLoadResourceChunkInfo(filename.str, rresid)
}

fn C.rresLoadResourceChunkInfoAll(filename &u8, chunkcount &u32) &C.rresResourceChunkInfo

pub fn load_resource_chunk_info_all(filename string, chunkcount &u32) &ResourceChunkInfo {
	return C.rresLoadResourceChunkInfoAll(filename.str, chunkcount)
}

fn C.rresLoadCentralDirectory(filename &u8) C.rresCentralDir

pub fn load_central_directory(filename string) CentralDir {
	return C.rresLoadCentralDirectory(filename.str)
}

fn C.rresUnloadCentralDirectory(dir C.rresCentralDir)

pub fn unload_central_directory(dir CentralDir) {
	C.rresUnloadCentralDirectory(dir)
}

fn C.rresGetDataType(fourcc &u8) u32

pub fn get_data_type(fourcc string) u32 {
	return C.rresGetDataType(fourcc.str)
}

fn C.rresGetResourceId(dir C.rresCentralDir, filename &u8) int

pub fn get_resource_id(dir CentralDir, filename string) int {
	return C.rresGetResourceId(dir, filename.str)
}

fn C.rresComputeCRC32(data &u8, len int) u32

pub fn compute_crc32(data &u8, len int) u32 {
	return C.rresComputeCRC32(data, len)
}

fn C.rresSetCipherPassword(pass &u8)

pub fn set_cipher_password(pass string) {
	C.rresSetCipherPassword(pass.str)
}

fn C.rresGetCipherPassword() &u8

pub fn get_cipher_password() string {
	return unsafe { C.rresGetCipherPassword().vstring() }
}
