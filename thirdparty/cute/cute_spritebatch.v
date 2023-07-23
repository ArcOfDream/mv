[translated]
module cute

#include "@VMODROOT/cute/cute_spritebatch.h"
#flag '-DSPRITEBATCH_IMPLEMENTATION'

pub struct C.spritebatch_sprite_t {
pub mut:
	image_id   i64
	texture_id i64
	w          int
	h          int
	x          f32
	y          f32
	sx         f32
	sy         f32
	c          f32
	s          f32
	minx       f32
	miny       f32
	maxx       f32
	maxy       f32
	sort_bits  int
}

pub type SpritebatchSprite = C.spritebatch_sprite_t

pub struct C.spritebatch_config_t {
pub mut:
	pixel_stride                   int
	atlas_width_in_pixels          int
	atlas_height_in_pixels         int
	atlas_use_border_pixels        int
	ticks_to_decay_texture         int
	lonely_buffer_count_till_flush int
	ratio_to_decay_atlas           f32
	ratio_to_merge_atlases         f32
	batch_callback                 &SubmitBatchFn
	get_pixels_callback            &GetPixelsFn
	generate_texture_callback      &GenerateTextureHandleFn
	delete_texture_callback        &DestroyTextureHandleFn
	sprites_sorter_callback        &SpritesSorterFn
	allocator_context              voidptr
}

pub type SpritebatchConfig = C.spritebatch_config_t

pub struct C.hashtable_internal_slot_t {
pub mut:
	key_hash   u32
	item_index int
	base_count int
}

pub type HashtableInternalSlot = C.hashtable_internal_slot_t

pub struct C.hashtable_t {
pub mut:
	memctx        voidptr
	count         int
	item_size     int
	slots         &C.hashtable_internal_slot_t
	slot_capacity int
	items_key     &i64
	items_slot    &int
	items_data    voidptr
	item_capacity int
	swap_temp     voidptr
}

pub type Hashtable = C.hashtable_t

pub struct C.spritebatch_internal_sprite_t {
pub mut:
	image_id     i64
	sort_bits    int
	w            int
	h            int
	x            f32
	y            f32
	sx           f32
	sy           f32
	c            f32
	s            f32
	premade_minx f32
	premade_miny f32
	premade_maxx f32
	premade_maxy f32
}

pub type SpritebatchInternalSprite = C.spritebatch_internal_sprite_t

pub struct C.spritebatch_internal_texture_t {
pub mut:
	timestamp int
	w         int
	h         int
	minx      f32
	miny      f32
	maxx      f32
	maxy      f32
	image_id  i64
}

pub type SpritebatchInternalTexture = C.spritebatch_internal_texture_t

pub struct C.spritebatch_internal_atlas_t {
pub mut:
	texture_id          i64
	volume_ratio        f32
	sprites_to_textures C.hashtable_t
	next                &C.spritebatch_internal_atlas_t
	prev                &C.spritebatch_internal_atlas_t
}

pub type SpritebatchInternalAtlas = C.spritebatch_internal_atlas_t

pub struct C.spritebatch_internal_lonely_texture_t {
pub mut:
	timestamp  int
	w          int
	h          int
	image_id   i64
	texture_id i64
}

pub type SpritebatchInternalLonelyTexture = C.spritebatch_internal_lonely_texture_t

pub struct C.spritebatch_internal_premade_atlas {
pub mut:
	w                int
	h                int
	mark_for_cleanup int
	image_id         i64
	texture_id       i64
}

pub type SpritebatchInternalPremadeAtlas = C.spritebatch_internal_premade_atlas

pub struct C.spritebatch_t {
pub mut:
	input_count    int
	input_capacity int
	input_buffer   &C.spritebatch_internal_sprite_t

	sprite_count    int
	sprite_capacity int
	sprites         &C.spritebatch_sprite_t
	sprites_scratch &C.spritebatch_sprite_t

	key_buffer_ciunt    int
	key_buffer_capacity int
	key_buffer          u64

	pixel_buffer_size int
	pixel_buffer      voidptr

	sprites_to_premade_textures C.hashtable_t
	sprites_to_lonely_textures  C.hashtable_t
	sprites_to_atlases          C.hashtable_t

	atlases &C.spritebatch_internal_atlas_t

	pixel_stride                   int
	atlas_width_in_pixels          int
	atlas_height_in_pixels         int
	atlas_use_border_pixels        int
	ticks_to_decay_texture         int
	lonely_buffer_count_till_flush int
	lonely_buffer_count_till_decay int
	ratio_to_decay_atlas           f32
	ratio_to_merge_atlases         f32
	batch_callback                 SubmitBatchFn
	get_pixels_callback            GetPixelsFn
	generate_texture_callback      GenerateTextureHandleFn
	delete_texture_callback        DestroyTextureHandleFn
	sprites_sorter_callback        SpritesSorterFn
	mem_ctx                        voidptr
	udata                          voidptr
}

pub type Spritebatch = C.spritebatch_t

pub struct C.Size_t {
pub mut:
	input_count                    int
	input_capacity                 int
	input_buffer                   &C.spritebatch_internal_sprite_t
	sprite_count                   int
	sprite_capacity                int
	sprites                        &C.spritebatch_sprite_t
	sprites_scratch                &C.spritebatch_sprite_t
	key_buffer_count               int
	key_buffer_capacity            int
	key_buffer                     &i64
	pixel_buffer_size              int
	pixel_buffer                   voidptr
	sprites_to_premade_textures    C.hashtable_t
	sprites_to_lonely_textures     C.hashtable_t
	sprites_to_atlases             C.hashtable_t
	atlases                        &C.spritebatch_internal_atlas_t
	pixel_stride                   int
	atlas_width_in_pixels          int
	atlas_height_in_pixels         int
	atlas_use_border_pixels        int
	ticks_to_decay_texture         int
	lonely_buffer_count_till_flush int
	lonely_buffer_count_till_decay int
	ratio_to_decay_atlas           f32
	ratio_to_merge_atlases         f32
	batch_callback                 &SubmitBatchFn
	get_pixels_callback            &GetPixelsFn
	generate_texture_callback      &GenerateTextureHandleFn
	delete_texture_callback        &DestroyTextureHandleFn
	sprites_sorter_callback        &SpritesSorterFn
	mem_ctx                        voidptr
	udata                          voidptr
}

pub type Size = C.Size_t

// struct C.Lldiv_t {
// 	quot i64
// 	rem  i64
// }

// struct C.Random_data {
// 	fptr      &int
// 	rptr      &int
// 	state     &int
// 	rand_type int
// 	rand_deg  int
// 	rand_sep  int
// 	end_ptr   &int
// }

pub type SubmitBatchFn = fn (&C.spritebatch_sprite_t, int, int, int, voidptr)

pub type GetPixelsFn = fn (u64, voidptr, int, voidptr)

pub type GenerateTextureHandleFn = fn (voidptr, int, int, voidptr) u64

pub type DestroyTextureHandleFn = fn (u64, voidptr) u64

pub type SpritesSorterFn = fn (&C.spritebatch_sprite_t, int)

fn C.spritebatch_push(sb &C.spritebatch_t, sprite C.spritebatch_sprite_t) int

pub fn spritebatch_push(sb &C.spritebatch_t, sprite C.spritebatch_sprite_t) int {
	return C.spritebatch_push(sb, sprite)
}

fn C.spritebatch_prefetch(sb &C.spritebatch_t, image_id i64, w int, h int)

pub fn spritebatch_prefetch(sb &C.spritebatch_t, image_id i64, w int, h int) {
	C.spritebatch_prefetch(sb, image_id, w, h)
}

fn C.spritebatch_fetch(sb &C.spritebatch_t, image_id i64, w int, h int) C.spritebatch_sprite_t

pub fn spritebatch_fetch(sb &C.spritebatch_t, image_id i64, w int, h int) C.spritebatch_sprite_t {
	return C.spritebatch_fetch(sb, image_id, w, h)
}

fn C.spritebatch_tick(sb &C.spritebatch_t)

pub fn spritebatch_tick(sb &C.spritebatch_t) {
	C.spritebatch_tick(sb)
}

fn C.spritebatch_flush(sb &C.spritebatch_t) int

pub fn spritebatch_flush(sb &C.spritebatch_t) int {
	return C.spritebatch_flush(sb)
}

fn C.spritebatch_defrag(sb &C.spritebatch_t) int

pub fn spritebatch_defrag(sb &C.spritebatch_t) int {
	return C.spritebatch_defrag(sb)
}

fn C.spritebatch_init(sb &C.spritebatch_t, config &C.spritebatch_config_t, udata voidptr) int

pub fn spritebatch_init(sb &C.spritebatch_t, config &C.spritebatch_config_t, udata voidptr) int {
	return C.spritebatch_init(sb, config, udata)
}

fn C.spritebatch_term(sb &C.spritebatch_t)

pub fn spritebatch_term(sb &C.spritebatch_t) {
	C.spritebatch_term(sb)
}

fn C.spritebatch_register_premade_atlas(sb &C.spritebatch_t, image_id i64, w int, h int)

pub fn spritebatch_register_premade_atlas(sb &C.spritebatch_t, image_id i64, w int, h int) {
	C.spritebatch_register_premade_atlas(sb, image_id, w, h)
}

fn C.spritebatch_cleanup_premade_atlas(sb &C.spritebatch_t, image_id i64)

pub fn spritebatch_cleanup_premade_atlas(sb &C.spritebatch_t, image_id i64) {
	C.spritebatch_cleanup_premade_atlas(sb, image_id)
}

fn C.spritebatch_reset_function_ptrs(sb &C.spritebatch_t, batch_callback &SubmitBatchFn, get_pixels_callback &GetPixelsFn, generate_texture_callback &GenerateTextureHandleFn, delete_texture_callback &DestroyTextureHandleFn, sprites_sorter_callback &SpritesSorterFn)

pub fn spritebatch_reset_function_ptrs(sb &C.spritebatch_t, batch_callback &SubmitBatchFn, get_pixels_callback &GetPixelsFn, generate_texture_callback &GenerateTextureHandleFn, delete_texture_callback &DestroyTextureHandleFn, sprites_sorter_callback &SpritesSorterFn) {
	C.spritebatch_reset_function_ptrs(sb, batch_callback, get_pixels_callback, generate_texture_callback,
		delete_texture_callback, sprites_sorter_callback)
}

fn C.spritebatch_set_default_config(config &C.spritebatch_config_t)

pub fn spritebatch_set_default_config(config &C.spritebatch_config_t) {
	C.spritebatch_set_default_config(config)
}

fn C.hashtable_init(table &C.hashtable_t, item_size int, initial_capacity int, memctx voidptr)

pub fn hashtable_init(table &C.hashtable_t, item_size int, initial_capacity int, memctx voidptr) {
	C.hashtable_init(table, item_size, initial_capacity, memctx)
}

fn C.hashtable_term(table &C.hashtable_t)

pub fn hashtable_term(table &C.hashtable_t) {
	C.hashtable_term(table)
}

fn C.hashtable_insert(table &C.hashtable_t, key i64, item voidptr) voidptr

pub fn hashtable_insert(table &C.hashtable_t, key i64, item voidptr) voidptr {
	return C.hashtable_insert(table, key, item)
}

fn C.hashtable_remove(table &C.hashtable_t, key i64)

pub fn hashtable_remove(table &C.hashtable_t, key i64) {
	C.hashtable_remove(table, key)
}

fn C.hashtable_clear(table &C.hashtable_t)

pub fn hashtable_clear(table &C.hashtable_t) {
	C.hashtable_clear(table)
}

fn C.hashtable_find(table &C.hashtable_t, key i64) voidptr

pub fn hashtable_find(table &C.hashtable_t, key i64) voidptr {
	return C.hashtable_find(table, key)
}

fn C.hashtable_count(table &C.hashtable_t) int

pub fn hashtable_count(table &C.hashtable_t) int {
	return C.hashtable_count(table)
}

fn C.hashtable_items(table &C.hashtable_t) voidptr

pub fn hashtable_items(table &C.hashtable_t) voidptr {
	return C.hashtable_items(table)
}

fn C.hashtable_keys(table &C.hashtable_t) &i64

pub fn hashtable_keys(table &C.hashtable_t) &i64 {
	return C.hashtable_keys(table)
}

fn C.hashtable_swap(table &C.hashtable_t, index_a int, index_b int)

pub fn hashtable_swap(table &C.hashtable_t, index_a int, index_b int) {
	C.hashtable_swap(table, index_a, index_b)
}
