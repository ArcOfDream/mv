module fons

pub struct C.FONSparams {
	width   int
	height  int
	flags   char
	userPtr voidptr
	// int (*renderCreate)(void* uptr, int width, int height)
	renderCreate fn (uptr voidptr, width int, height int) int
	// int (*renderResize)(void* uptr, int width, int height)
	renderResize fn (uptr voidptr, width int, height int) int
	// void (*renderUpdate)(void* uptr, int* rect, const unsigned char* data)
	renderUpdate fn (uptr voidptr, rect &int, data &u8)
	// void (*renderDraw)(void* uptr, const float* verts, const float* tcoords, const unsigned int* colors, int nverts)
	renderDraw fn (uptr voidptr, verts &f32, tcoords &f32, colors &u32, nverts int)
	// void (*renderDelete)(void* uptr)
	renderDelete fn (uptr voidptr)
	// void (*pushQuad)(void* uptr, const FONSquad* quad)
	pushQuad fn (uptr voidptr, quad &C.FONSquad)
}

pub struct C.FONSquad {
pub:
	x0 f32
	y0 f32
	s0 f32
	t0 f32
	x1 f32
	y1 f32
	s1 f32
	t1 f32
}

pub struct C.FONStextIter {
	x              f32
	y              f32
	nextx          f32
	nexty          f32
	scale          f32
	spacing        f32
	codepoint      u32
	isize          i16
	iblur          i16
	font           &C.FONSfont = unsafe { nil }
	prevGlyphIndex int
	str            &u8
	next           &u8
	end            &u8
	utf8state      u32
}

pub struct C.FONSfont {}

pub struct C.FONScontext {}
