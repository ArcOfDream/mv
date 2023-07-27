module main

import mv.resource
import mv.graphics

struct BMFontGlyph {
	id int
	x int
	y int
	width int
	height int
	xoffset int
	yoffset int
	xadvance int
	page u8
	chnl u8
}

struct BMFontInfo {
	face string
	size int
	bold bool
	italic bool
	charset string
	unicode bool
	stretch_h u32
	smooth bool
	aa u32

}

struct BMFontRenderer {
	atlas resource.Texture
	glyphs map[int]BMFontGlyph
	renderer ?&graphics.Renderer
}
