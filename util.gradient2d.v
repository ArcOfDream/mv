module mv

import raylib as rl { Color, PixelFormat }
import math { atan2, floorf, sqrtf }

pub enum GradientFill {
	linear
	radial
	radial_focal // two-point: center/radius + separate focal point
	conic
}

pub struct Gradient2D {
pub mut:
	gradient    Gradient
	fill        GradientFill = .linear
	fill_from   Vec2         = Vec2{0.0, 0.5}
	fill_to     Vec2         = Vec2{1.0, 0.5}
	center      Vec2         = Vec2{0.5, 0.5}
	radius      f32          = 0.5
	focal       Vec2         = Vec2{0.5, 0.5} // only used by radial_focal
	start_angle f32          = 0.0
	width       int          = 256
	height      int          = 256
}

pub fn (gt &Gradient2D) bake() rl.Texture2D {
	img := gt.bake_image()
	tex := rl.load_texture_from_image(img)
	return tex
}

pub fn (gt &Gradient2D) bake_image() rl.Image {
	return match gt.fill {
		.linear {
			gen_image_gradient_linear(gt.width, gt.height, &gt.gradient, gt.fill_from,
				gt.fill_to)
		}
		.radial {
			gen_image_gradient_radial(gt.width, gt.height, &gt.gradient, gt.center, gt.radius)
		}
		.radial_focal {
			gen_image_gradient_radial_focal(gt.width, gt.height, &gt.gradient, gt.center,
				gt.radius, gt.focal)
		}
		.conic {
			gen_image_gradient_conic(gt.width, gt.height, &gt.gradient, gt.center, gt.start_angle)
		}
	}
}

@[inline]
fn write_pixel(mut pixels []u8, idx int, c Color) {
	pixels[idx * 4] = c.r
	pixels[idx * 4 + 1] = c.g
	pixels[idx * 4 + 2] = c.b
	pixels[idx * 4 + 3] = c.a
}

// allocates a pixel buffer that raylib can own and free via rl.unload_image
fn alloc_pixels(width int, height int) []u8 {
	size := width * height * 4
	return unsafe { malloc(size).vbytes(size) }
}

fn image_from_pixels(width int, height int, pixels []u8) rl.Image {
	return rl.Image{
		data:    pixels.data
		width:   width
		height:  height
		mipmaps: 1
		format:  int(PixelFormat.pixelformat_uncompressed_r8g8b8a8)
	}
}

// gen_image_gradient_linear samples gradient along the axis defined by two
// normalized-image-space points `from` and `to` (each component in 0 to 1)
pub fn gen_image_gradient_linear(width int, height int, gradient &Gradient, from Vec2, to Vec2) rl.Image {
	mut pixels := alloc_pixels(width, height)
	dir := Vec2{(to.x - from.x) * f32(width), (to.y - from.y) * f32(height)}
	len_sq := dir.x * dir.x + dir.y * dir.y
	for y in 0 .. height {
		for x in 0 .. width {
			fx := f32(x) - from.x * f32(width)
			fy := f32(y) - from.y * f32(height)
			t := if !len_sq.eq_epsilon(0) { (fx * dir.x + fy * dir.y) / len_sq } else { f32(0.0) }
			write_pixel(mut pixels, y * width + x, gradient.sample(t))
		}
	}
	return image_from_pixels(width, height, pixels)
}

// gen_image_gradient_radial samples gradient by distance from `center`
// out to `radius` (in normalized units, e.g. 0.5 = half-width).
pub fn gen_image_gradient_radial(width int, height int, gradient &Gradient, center Vec2, radius f32) rl.Image {
	mut pixels := alloc_pixels(width, height)
	inv_r := if !radius.eq_epsilon(0) { 1.0 / radius } else { 0.0 }
	// use pixel-aspect-corrected distance so circles stay round on non-square images
	aspect := f32(width) / f32(height)
	for y in 0 .. height {
		for x in 0 .. width {
			nx := (f32(x) / f32(width) - center.x) * aspect
			ny := f32(y) / f32(height) - center.y
			t := sqrtf(nx * nx + ny * ny) * inv_r
			write_pixel(mut pixels, y * width + x, gradient.sample(t))
		}
	}
	return image_from_pixels(width, height, pixels)
}

// gen_image_gradient_radial_focal is a two-point radial gradient.
// `center` + `radius` define the outer circle (t = 1)
// `focal` defines the inner bright point (t = 0) -- must be inside the circle.
// this function is equivalent to gen_image_gradient_radial if center = focal
pub fn gen_image_gradient_radial_focal(width int, height int, gradient &Gradient, center Vec2, radius f32, focal Vec2) rl.Image {
	mut pixels := alloc_pixels(width, height)

	// convert all coords to pixel space so we work in one unit system
	pw := f32(width)
	ph := f32(height)

	cx := center.x * pw
	cy := center.y * ph
	r := radius * pw // radius in pixels (use width as reference axis)

	// clamp focal inside the circle so the quadratic always has a solution.
	// we nudge it to 99% of the radius to keep a small margin.
	mut fx := focal.x * pw
	mut fy := focal.y * ph
	fdx := fx - cx
	fdy := fy - cy
	fd := sqrtf(fdx * fdx + fdy * fdy)
	if fd > r * 0.99 {
		scale := (r * 0.99) / fd
		fx = cx + fdx * scale
		fy = cy + fdy * scale
	}

	r2 := r * r

	for y in 0 .. height {
		for x in 0 .. width {
			px := f32(x)
			py := f32(y)

			// ray direction: focal -> pixel
			dx := px - fx
			dy := py - fy
			dist_fp := sqrtf(dx * dx + dy * dy)

			mut t := f32(0.0)

			if dist_fp < 1e-4 {
				// pixel is exactly at focal point t = 0.
				t = 0.0
			} else {
				// quadratic: |F + s*(P-F) - C|² = R²
				// let o = F - C
				ox := fx - cx
				oy := fy - cy

				a := dx * dx + dy * dy
				b := 2.0 * (ox * dx + oy * dy)
				c_ := ox * ox + oy * oy - r2

				disc := b * b - 4.0 * a * c_
				s_max := if disc < 0.0 {
					// shouldn't happen after focal clamp; fallback gracefully
					f32(1.0)
				} else {
					(-b + sqrtf(math.max(disc, f32(0.0)))) / (2.0 * a)
				}

				t = if !s_max.eq_epsilon(0) { dist_fp / (s_max * sqrtf(a)) } else { f32(1.0) }
			}

			write_pixel(mut pixels, y * width + x, gradient.sample(t))
		}
	}
	return image_from_pixels(width, height, pixels)
}

// gen_image_gradient_conic samples gradient by angle around `center`.
// `start_angle` is in radians, the gradient wraps at 2pi.
pub fn gen_image_gradient_conic(width int, height int, gradient &Gradient, center Vec2, start_angle f32) rl.Image {
	mut pixels := alloc_pixels(width, height)
	tau := f32(math.pi * 2.0)
	for y in 0 .. height {
		for x in 0 .. width {
			nx := f32(x) / f32(width) - center.x
			ny := f32(y) / f32(height) - center.y
			mut angle := f32(atan2(ny, nx) - start_angle)
			// Normalise to [0, 1]
			angle = angle - tau * floorf(angle / tau)
			write_pixel(mut pixels, y * width + x, gradient.sample(angle / tau))
		}
	}
	return image_from_pixels(width, height, pixels)
}

// gen_image_fill floods the whole image with a single color
pub fn gen_image_fill(width int, height int, color Color) rl.Image {
	mut pixels := alloc_pixels(width, height)
	for i in 0 .. width * height {
		write_pixel(mut pixels, i, color)
	}
	return image_from_pixels(width, height, pixels)
}

// gen_image_checker produces a checkerboard with two colors
pub fn gen_image_checker(width int, height int, cols int, rows int, color_a Color, color_b Color) rl.Image {
	mut pixels := alloc_pixels(width, height)
	for y in 0 .. height {
		for x in 0 .. width {
			cx := x * cols / width
			cy := y * rows / height
			c := if (cx + cy) % 2 == 0 { color_a } else { color_b }
			write_pixel(mut pixels, y * width + x, c)
		}
	}
	return image_from_pixels(width, height, pixels)
}

// gen_image_grid draws a grid with the given number of columns and rows.
// `bg` is the fill color, `line` is the grid line color, `thickness` is in pixels.
pub fn gen_image_grid(width int, height int, cols int, rows int, thickness int, bg Color, line Color) rl.Image {
	mut pixels := alloc_pixels(width, height)
	for y in 0 .. height {
		for x in 0 .. width {
			// Check if this pixel falls on a vertical or horizontal grid line.
			on_col := (x * cols / width) != ((x + thickness - 1) * cols / width)
			on_row := (y * rows / height) != ((y + thickness - 1) * rows / height)
			write_pixel(mut pixels, y * width + x, if on_col || on_row { line } else { bg })
		}
	}
	return image_from_pixels(width, height, pixels)
}
