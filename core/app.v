module core

import sdl
import mv.resource
import mv.graphics

const (
	target_fps = 60
)

[heap]
pub struct App {
pub mut:
	window_width  int
	window_height int
	title         string
	sdl_window    &sdl.Window        = sdl.null
	renderer      &graphics.Renderer = sdl.null
	gl_context    sdl.GLContext
	data          map[string]resource.Resource
mut:
	should_close bool

	init_func   ?fn ()
	update_func ?fn (f32)
	draw_func   ?fn ()
	event_func  ?fn (&sdl.Event)
}

pub fn (mut app App) init() {
	app.renderer = &graphics.Renderer{}
	sdl.init(sdl.init_everything)

	app.renderer.set_sdl_attributes()

	app.sdl_window = app.renderer.create_sdl_window(app.window_width, app.window_height) or {
		panic(err)
	}
	sdl.set_window_title(app.sdl_window, app.title.str)
	app.renderer.init()
	if init := app.init_func {
		init()
	}
}

pub fn (mut app App) run() {
	sdl.show_window(app.sdl_window)

	mut old_time := sdl.get_ticks()
	mut fps := u32(0)
	mut minticks := u32(1000 / core.target_fps)

	for {
		new_time := sdl.get_ticks()
		time_since_last_frame := new_time - old_time
		delta_time := f32(old_time) / f32(new_time)

		app.event()
		if app.should_close {
			break
		}

		if update := app.update_func {
			update(delta_time)
		}

		app.draw()

		fps++
		sdl.delay(minticks)

		if time_since_last_frame > 1000 {
			old_time = new_time
			fps = 0
		}
	}

	app.renderer.free()
	sdl.gl_delete_context(app.gl_context)
	sdl.destroy_window(app.sdl_window)
	sdl.quit()
}

pub fn (mut app App) draw() {
	app.renderer.clear_frame()
	app.renderer.begin_frame()

	if draw := app.draw_func {
		draw()
	}

	app.renderer.end_frame()
	sdl.gl_swap_window(app.sdl_window)
}

pub fn (mut app App) event() {
	evt := sdl.Event{}

	for 0 < sdl.poll_event(&evt) {
		match evt.@type {
			.quit {
				app.exit()
			}
			else {
				if ev := app.event_func {
					ev(&evt)
				}
			}
		}
	}
}

pub fn (mut app App) exit() {
	app.should_close = true
}

pub fn (app App) get_shader(key string) ?&resource.Shader {
	if key !in app.data {
		return none
	}
	shd := app.data[key] or { return none }
	if shd is resource.Shader {
		return shd
	}
	return none
}

pub fn (app App) get_texture(key string) ?&resource.Texture {
	if key !in app.data {
		return none
	}
	tex := app.data[key] or { return none }
	if tex is resource.Texture {
		return tex
	}
	return none
}
