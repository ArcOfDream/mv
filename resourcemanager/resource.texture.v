module resourcemanager

import raylib as rl
import rres

pub struct TextureResource {
pub:
	tex rl.Texture2D
pub mut:
	frames      []rl.Rectangle
	wrap_mode   rl.TextureWrap   = .texture_wrap_clamp
	filter_mode rl.TextureFilter = .texture_filter_bilinear
	// blend_mode is a draw-time state; stored here so consumers like Line and
	// Sprite can apply it around their draw calls without needing a separate field.
	blend_mode rl.BlendMode = .blend_alpha
}

fn (tr TextureResource) unload() {
	rl.unload_texture(tr.tex)
}

// apply_sampler_modes pushes the current wrap and filter fields to the GPU.
// called automatically after every load path so the GPU state always matches
// the struct. also call manually after changing wrap_mode or filter_mode.
pub fn (tr &TextureResource) apply_sampler_modes() {
	rl.set_texture_wrap(tr.tex, int(tr.wrap_mode))
	rl.set_texture_filter(tr.tex, int(tr.filter_mode))
}

pub fn (mut tr TextureResource) set_wrap_mode(mode rl.TextureWrap) {
	tr.wrap_mode = mode
	rl.set_texture_wrap(tr.tex, int(mode))
}

pub fn (mut tr TextureResource) set_filter_mode(mode rl.TextureFilter) {
	tr.filter_mode = mode
	rl.set_texture_filter(tr.tex, int(mode))
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

// generate_frames_grid slices the texture into a uniform cols x rows grid and
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
	h := rm.acquire_or_insert(name, fn [path] () ?TextureResource {
		t := rl.load_texture(path)
		if t.id <= 0 {
			return none
		}
		return TextureResource{ tex: t }
	})?

	// apply_sampler_modes is only needed on the fresh-insert path, but
	// applying it on cache hits is harmless (idempotent) and keeps this
	// simple.
	if mut res := h.get() {
		res.apply_sampler_modes()
	}
	return h
}

pub fn (mut rm ResourceManager[TextureResource]) add_texture(name string, tex rl.Texture2D) ?Handle[TextureResource] {
	h := rm.acquire_or_insert(name, fn [tex] () ?TextureResource {
		if tex.id <= 0 {
			return none
		}
		return TextureResource{ tex: tex }
	})?
	if mut res := h.get() {
		res.apply_sampler_modes()
	}
	return h
}

pub fn (mut rm ResourceManager[TextureResource]) load_from_image(name string, img rl.Image) ?Handle[TextureResource] {
	h := rm.acquire_or_insert(name, fn [img] () ?TextureResource {
		tex := rl.load_texture_from_image(img)
		if tex.id <= 0 {
			return none
		}
		return TextureResource{ tex: tex }
	})?
	if mut res := h.get() {
		res.apply_sampler_modes()
	}
	return h
}

// load_from_rres loads an IMGE chunk named rres_name, promotes it to a
// Texture2D via an intermediate Image, and registers it under name.
pub fn (mut rm ResourceManager[TextureResource]) load_from_rres(loader &rres.RresLoader, name string, rres_name string) ?Handle[TextureResource] {
	h := rm.acquire_or_insert(name, fn [loader, rres_name] () ?TextureResource {
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
		return TextureResource{ tex: tex }
	})?
	if mut res := h.get() {
		res.apply_sampler_modes()
	}
	return h
}
