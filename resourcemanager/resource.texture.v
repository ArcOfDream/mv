module resourcemanager

import raylib as rl
import rres

pub struct TextureResource {
pub:
	tex rl.Texture2D
pub mut:
	frames []rl.Rectangle
}

fn (tr TextureResource) unload() {
	rl.unload_texture(tr.tex)
}

// set_frames replaces the frame list for the resource pointed to by handle.
pub fn (mut tm TextureResource) set_frames(frames []rl.Rectangle) {
	tm.frames = frames
}

// add a region to the frame list
pub fn (mut tm TextureResource) add_frame(x int, y int, w int, h int) {
	tm.frames << rl.Rectangle{x, y, w, h}
}

// add a Rectangle region to the frame list
pub fn (mut tm TextureResource) add_frame_rect(frame rl.Rectangle) {
	tm.frames << frame
}

// generate_frames_grid slices the texture into a uniform cols×rows grid and
// stores the resulting Rectangles as the frame list. Any remainder pixels at
// the right/bottom edge are ignored. Overwrites any previously set frames.
pub fn (mut tm TextureResource) generate_frames_grid(cols int, rows int) {
	if cols <= 0 || rows <= 0 {
		return
	}

	tex := tm.tex
	fw := tex.width / cols
	fh := tex.height / rows
	count := cols * rows

	mut frames := []rl.Rectangle{cap: count}
	for row in 0 .. rows {
		for col in 0 .. cols {
			frames << rl.Rectangle{
				x:      col * fw
				y:      row * fh
				width:  fw
				height: fh
			}
		}
	}

	tm.frames = frames
}

pub fn (mut rm ResourceManager[TextureResource]) load(name string, path string) ?Handle[TextureResource] {
	if h := rm.get_handle(name) {
		return h
	}

	t := rl.load_texture(path)
	if t.id <= 0 {
		return none
	}

	return rm.add(name, TextureResource{ tex: t })
}

// load_from_rres loads an IMGE chunk named rres_name, promotes it to a
// Texture2D via an intermediate Image, and registers it under name.
pub fn (mut rm ResourceManager[TextureResource]) load_from_rres(loader &rres.RresLoader, name string, rres_name string) ?Handle[TextureResource] {
	if h := rm.get_handle(name) {
		return h
	}

	chunk := loader.load_single(rres_name) or { return none }
	defer { chunk.unload() }

	img := rres.load_image_from_resource(chunk)
	if !rl.is_image_valid(img) {
		return none
	}

	tex := rl.load_texture_from_image(img)
	rl.unload_image(img)

	if tex.id <= 0 {
		return none
	}

	return rm.add(name, TextureResource{ tex: tex })
}