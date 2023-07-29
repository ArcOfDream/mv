module core

import sdl
import mv.resource
import mv.graphics

const (
	target_fps = 120
)

[heap]
pub struct Context {
pub mut:
	window_width  int
	window_height int
	title         string
	sdl_window    &sdl.Window        = sdl.null
	renderer      &graphics.Renderer = sdl.null
	gl_context    sdl.GLContext
	data          map[string]resource.Resource
	fps           u32
mut:
	should_close bool

	init_func   ?fn ()
	update_func ?fn (f32)
	draw_func   ?fn ()
	event_func  ?fn (&sdl.Event)
}

pub fn (mut ctx Context) init() {
	ctx.renderer = &graphics.Renderer{}
	sdl.init(sdl.init_everything)

	ctx.renderer.set_sdl_attributes()

	ctx.sdl_window = ctx.renderer.create_sdl_window(ctx.window_width, ctx.window_height) or {
		panic(err)
	}
	sdl.set_window_title(ctx.sdl_window, ctx.title.str)
	ctx.renderer.init()
	if init := ctx.init_func {
		init()
	}
}

pub fn (mut ctx Context) run() {
	sdl.show_window(ctx.sdl_window)

	mut old_time := sdl.get_ticks()
	mut fps := u32(0)
	mut minticks := u32(1000 / core.target_fps)

	for {
		new_time := sdl.get_ticks()
		time_since_last_frame := new_time - old_time
		delta_time := f32(old_time) / f32(new_time)

		ctx.event()
		if ctx.should_close {
			break
		}

		if update := ctx.update_func {
			update(delta_time)
		}
		ctx.draw()

		fps++
		sdl.delay(minticks)

		if time_since_last_frame > 1000 {
			old_time = new_time
			ctx.fps = fps
			fps = 0
		}
	}

	ctx.renderer.free()
	sdl.gl_delete_context(ctx.gl_context)
	sdl.destroy_window(ctx.sdl_window)
	sdl.quit()
}

pub fn (mut ctx Context) draw() {
	ctx.renderer.clear_frame()
	ctx.renderer.begin_frame()

	if draw := ctx.draw_func {
		draw()
	}

	ctx.renderer.end_frame()
	sdl.gl_swap_window(ctx.sdl_window)
}

pub fn (mut ctx Context) event() {
	evt := sdl.Event{}

	for 0 < sdl.poll_event(&evt) {
		match evt.@type {
			.quit {
				ctx.exit()
			}
			else {
				if ev := ctx.event_func {
					ev(&evt)
				}
			}
		}
	}
}

pub fn (mut ctx Context) exit() {
	ctx.should_close = true
}

pub fn (ctx Context) get_shader(key string) ?&resource.Shader {
	if key !in ctx.data {
		return none
	}
	shd := ctx.data[key] or { return none }
	if shd is resource.Shader {
		return shd
	}
	return none
}

pub fn (ctx Context) get_texture(key string) ?&resource.Texture {
	if key !in ctx.data {
		return none
	}
	tex := ctx.data[key] or { return none }
	if tex is resource.Texture {
		return tex
	}
	return none
}
