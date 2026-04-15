module mv

import raylib as rl
import wren
import math as m
import physics as phys
import resourcemanager { ResourceManager, ShaderResource, SoundResource, TextureResource }
import input
import stringname { StringNameMap }
import audio
import os

// import sync

// Target 60 updates per second
const tick_rate = 60
const dt = 1.0 / f64(tick_rate)

pub struct App {
mut:
	is_running      bool
	integer_scale   bool
	target_fps      int
	window_size     Vec2
	window_min_size Vec2
	viewport_size   Vec2
	window_title    string

	clear_color    rl.Color
	backdrop_color rl.Color

	wren_vm                  ?&wren.VM
	wren_update_handle       ?&wren.Handle
	wren_draw_handle         ?&wren.Handle
	wren_signal_call_handles []?&wren.Handle

	viewport rl.RenderTexture2D
	state    GameState = GameState{}
	wren_cfg wren.Configuration
	names    &StringNameMap
pub mut:
	pending_free []&INode

	wren                ?WrenSetup
	wren_module_sources []string
	scene_root          ?&Node

	textures ResourceManager[TextureResource]
	shaders  ResourceManager[ShaderResource]
	sounds   ResourceManager[SoundResource]

	active_camera ?&CameraNode
	audio_server  audio.AudioServer
	physics_world phys.PhysicsWorld
	bodies        map[int]&PhysicsBody
	input_map     &input.InputMap

	init_func          ?fn ()
	update_func        ?fn (f32)
	draw_func          ?fn ()
	backdrop_draw_func ?fn ()
	input_func         ?fn ()
}

pub fn App.new(init ?fn (), update ?fn (f32), draw ?fn (), backdrop ?fn (), input_fn ?fn ()) &App {
	mut n := &StringNameMap{}
	mut imap := input.InputMap.new(n)

	return &App{
		names:     n
		input_map: imap

		audio_server: audio.AudioServer.new()

		init_func:          init
		update_func:        update
		draw_func:          draw
		backdrop_draw_func: backdrop
		input_func:         input_fn
	}
}

// helper function to create and return a node type.
// ensure that the kind of node you're creating implements INode
pub fn (app &App) new_node[T](name string, x f32, y f32) &T {
	mut node := &T{
		app:       app
		node_name: name
		pos:       Vec2{
			x: x
			y: y
		}
	}

	emit_notification(mut node, .init)
	return node
}

pub fn (mut app App) set_target_fps(value int) {
	app.target_fps = value
	rl.set_target_fps(value)
}

pub fn (app &App) get_target_fps() int {
	return app.target_fps
}

pub fn (mut app App) set_window_title(text string) {
	app.window_title = text
	rl.set_window_title(text)
}

pub fn (app &App) get_window_title() string {
	return app.window_title
}

pub fn (mut app App) set_window_size(x int, y int) {
	app.window_size = Vec2{x, y}
	rl.set_window_size(x, y)
}

pub fn (app &App) get_window_size() Vec2 {
	return app.window_size
}

pub fn (mut app App) set_window_min_size(x int, y int) {
	app.window_min_size = Vec2{x, y}
	rl.set_window_min_size(x, y)
}

pub fn (app &App) get_window_min_size() Vec2 {
	return app.window_min_size
}

pub fn (mut app App) set_viewport_size(x int, y int) {
	app.viewport_size.x = x
	app.viewport_size.y = y

	if app.is_running {
		app.viewport = rl.load_render_texture(x, y)
	}
}

pub fn (app &App) get_viewport_size() Vec2 {
	return app.viewport_size
}

pub fn (mut app App) set_integer_scale(value bool) {
	app.integer_scale = value
}

pub fn (app &App) get_integer_scale() bool {
	return app.integer_scale
}

pub fn (mut app App) set_clear_color(value rl.Color) {
	app.clear_color = value
}

pub fn (app &App) get_clear_color() rl.Color {
	return app.clear_color
}

pub fn (mut app App) set_backdrop_color(value rl.Color) {
	app.backdrop_color = value
}

pub fn (app &App) get_backdrop_color() rl.Color {
	return app.backdrop_color
}

pub fn (mut app App) set_state(value GameState) {
	app.state = value
}

pub fn (app &App) get_state() GameState {
	return app.state
}

pub fn (mut app App) set_active_camera(cam &CameraNode) {
	app.active_camera = cam
}

$if !single_thread ? {
	fn (mut app App) update_loop(update_done chan bool, render_done chan bool) {
		for app.is_running {
			app.physics_world.hash.clear()
			app.audio_server.process()

			if update := app.update_func {
				update(app.state.dt)
			}

			if mut root := app.scene_root {
				emit_notification(mut root, .update)
			}

			// clean up pending nodes for removal
			for mut node in app.pending_free {
				if mut p := node.parent {
					idx := p.find_child(node)
					if idx != -1 {
						p.remove_child(idx)
					}
				}
			}
			app.pending_free.clear()

			update_done <- true

			_ := <-render_done
		}
	}
}

pub fn (mut app App) run() {
	app.is_running = true

	// making sure to init audio here!
	rl.init_audio_device()

	// set up the wren subsystem only if there's a WrenSetup present
	if mut setup := app.wren {
		wren.init_configuration(&app.wren_cfg)
		app.wren_cfg.bindForeignMethodFn = wren_bind_method
		app.wren_cfg.bindForeignClassFn = wren_bind_class
		app.wren_cfg.loadModuleFn = wren_load_module
		app.wren_cfg.writeFn = wren_write
		app.wren_cfg.errorFn = wren_error

		mut vm := wren.new_vm(&app.wren_cfg)
		app.wren_vm = vm
		vm.set_user_data(&app)

		app.wren_update_handle = vm.make_call_handle('update(_)')
		app.wren_draw_handle = vm.make_call_handle('draw()')
		app.wren_signal_call_handles = [
			?&wren.Handle(vm.make_call_handle('call()')),
			?&wren.Handle(vm.make_call_handle('call(_)')),
			?&wren.Handle(vm.make_call_handle('call(_,_)')),
			?&wren.Handle(vm.make_call_handle('call(_,_,_)')),
			?&wren.Handle(vm.make_call_handle('call(_,_,_,_)')),
		]

		// vm.interpret('main', $embed_file('wren_src/raylib.wren').to_string())
		// vm.interpret('main', $embed_file('wren_src/node.wren').to_string())

		if setup.entry != '' {
			src := os.read_file(setup.entry) or {
				eprintln('wren: entry script not found: ${setup.entry}')
				return
			}
			vm.interpret('main', src)
		}
	}

	rl.set_config_flags(.flag_window_resizable)
	rl.init_window(int(app.window_size.x), int(app.window_size.y), app.window_title)
	app.set_target_fps(app.target_fps)

	// run app.init()
	if init := app.init_func {
		init()
	}

	app.viewport = rl.load_render_texture(int(app.viewport_size.x), int(app.viewport_size.y))

	// sync channels
	render_done := chan bool{}
	update_done := chan bool{}

	$if !single_thread ? {
		spawn app.update_loop(update_done, render_done)
	}

	for !rl.window_should_close() {
		$if !single_thread ? {
			_ := <-update_done
		}

		mut scale := m.min(f64(rl.get_screen_width()) / app.viewport_size.x,
			f64(rl.get_screen_height()) / app.viewport_size.y)
		app.state.dt = rl.get_frame_time()

		if app.integer_scale {
			scale = m.floor(scale)
		}

		// vfmt off
		mut vp_source := rl.Rectangle{0, 0, f32(app.viewport.texture.width), f32(-app.viewport.texture.height)}
		mut vp_dest := rl.Rectangle{
			f32(rl.get_screen_width() - (app.viewport_size.x * scale)) * 0.5,
			f32(rl.get_screen_height() - (app.viewport_size.y * scale)) * 0.5,
			f32(app.viewport_size.x * scale),
			f32(app.viewport_size.y * scale)
		}
		// vfmt on

		// run app.update()
		$if single_thread ? {
			app.physics_world.hash.clear()
			app.audio_server.process()

			if update := app.update_func {
				update(app.state.dt)
			}

			if mut root := app.scene_root {
				emit_notification(mut root, .update)
			}

			// clean up pending nodes for removal
			for mut node in app.pending_free {
				if mut p := node.parent {
					idx := p.find_child(node)
					if idx != -1 {
						p.remove_child(idx)
					}
				}
			}
			app.pending_free.clear()
		}

		//
		// internal game view portion
		//
		rl.begin_texture_mode(app.viewport)
		if cam_node := app.active_camera {
			rl.begin_mode_2d(cam_node.camera)
		}
		rl.clear_background(app.clear_color)

		// run app.draw()
		if draw := app.draw_func {
			draw()
		}

		if mut root := app.scene_root {
			emit_notification(mut root, .draw)
		}

		if _ := app.active_camera {
			rl.end_mode_2d()
		}
		rl.end_texture_mode()

		//
		// drawing the backdrop and internal game view
		//
		rl.begin_drawing()
		rl.clear_background(app.backdrop_color)

		// run app.backdrop_draw()
		if backdrop_draw := app.backdrop_draw_func {
			backdrop_draw()
		}

		rl.draw_texture_pro(app.viewport.texture, vp_source, vp_dest, Vec2{}, 0, rl.white)
		rl.end_drawing()

		$if !single_thread ? {
			render_done <- true
		}
	}

	rl.close_window()
}
