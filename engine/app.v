module engine

import raylib as rl
import math as m
import os
import core { GameState, StringNameMap, Vec2 }
import physics as phys
import resourcemanager { FontResource, Handle, ResourceManager, ShaderResource, SoundResource, TextureResource }
import audio
import wren

pub const plex_font = $embed_file('res/plex.ttf')
pub const plex_mono = $embed_file('res/plex_mono.ttf')

pub fn engine_font_data() []u8 {
	return plex_font.to_bytes()
}

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
	wren_from_native_handle  ?&wren.Handle
	wren_signal_call_handles []?&wren.Handle
	wren_bootstrap_seq       u64

	viewport rl.RenderTexture2D
	state    GameState
	wren_cfg wren.Configuration
	names    &StringNameMap
	debug    &DebugPanel = DebugPanel.new()
	menu_bar &MenuBar    = MenuBar.new()
pub mut:
	scene_registry &SceneRegistry = SceneRegistry.new()
	pending_free   []INode

	wren                ?WrenSetup
	wren_module_sources []string
	scene_root          ?&Node

	textures ResourceManager[TextureResource]
	shaders  ResourceManager[ShaderResource]
	sounds   ResourceManager[SoundResource]
	fonts    ResourceManager[FontResource]

	active_camera  ?&CameraNode
	audio_server   audio.AudioServer
	physics_world  phys.PhysicsWorld
	bodies         map[int]&PhysicsBody
	bodies_next_id int
	input_map      &core.InputMap

	init_func          ?fn ()
	update_func        ?fn (f32)
	draw_func          ?fn ()
	backdrop_draw_func ?fn ()
	run_func           ?fn (&App)
}

pub fn App.new(init ?fn (), update ?fn (f32), draw ?fn (), backdrop ?fn ()) &App {
	mut n := &StringNameMap{}
	mut imap := core.InputMap.new(n)

	return &App{
		names:     n
		input_map: imap

		audio_server: audio.AudioServer.new()

		init_func:          init
		update_func:        update
		draw_func:          draw
		backdrop_draw_func: backdrop
	}
}

pub fn (app &App) new_node[T](name string, x f32, y f32) &T {
	mut node := &T{
		app:       app
		node_name: name
		pos:       Vec2{x, y}
	}
	emit_notification(mut node, .init)
	return node
}

pub fn (mut app App) set_target_fps(value int) {
	app.target_fps = value
	if app.is_running {
		rl.set_target_fps(value)
	}
}

pub fn (app &App) get_target_fps() int {
	return app.target_fps
}

pub fn (mut app App) set_window_title(text string) {
	app.window_title = text
	if app.is_running {
		rl.set_window_title(text)
	}
}

pub fn (app &App) get_window_title() string {
	return app.window_title
}

pub fn (mut app App) set_window_size(x int, y int) {
	app.window_size = Vec2{x, y}
	if app.is_running {
		rl.set_window_size(x, y)
	}
}

pub fn (app &App) get_window_size() Vec2 {
	return app.window_size
}

pub fn (mut app App) set_window_min_size(x int, y int) {
	app.window_min_size = Vec2{x, y}
	if app.is_running {
		rl.set_window_min_size(x, y)
	}
}

pub fn (app &App) get_window_min_size() Vec2 {
	return app.window_min_size
}

pub fn (mut app App) set_viewport_size(x int, y int) {
	app.viewport_size = Vec2{f32(x), f32(y)}
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

fn (mut app App) process_update() {
	if !app.debug.paused || app.debug.consume_step() {
		app.physics_world.hash.clear()
		app.audio_server.process()

		if update := app.update_func {
			update(app.state.dt)
		}

		if mut root := app.scene_root {
			emit_notification(mut root, .update)
		}

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
}

$if !single_thread ? {
	fn (mut app App) update_loop(update_done chan bool, render_done chan bool) {
		for app.is_running {
			app.process_update()
			update_done <- true
			_ := <-render_done
		}
	}
}

pub fn (mut app App) run() {
	app.is_running = true

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
		app.wren_from_native_handle = vm.make_call_handle('fromNative(_)')
		app.wren_signal_call_handles = [
			?&wren.Handle(vm.make_call_handle('call()')),
			?&wren.Handle(vm.make_call_handle('call(_)')),
			?&wren.Handle(vm.make_call_handle('call(_,_)')),
			?&wren.Handle(vm.make_call_handle('call(_,_,_)')),
			?&wren.Handle(vm.make_call_handle('call(_,_,_,_)')),
		]

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
	rl.init_audio_device()
	rl.set_target_fps(app.target_fps)

	app.debug.debug_font = app.fonts.load_from_memory('debug', 16, plex_font.to_bytes()) or {
		Handle[FontResource]{}
	}
	register_builtin_nodes(mut app.scene_registry, &app)

	if init := app.init_func {
		init()
	}
	app.viewport = rl.load_render_texture(int(app.viewport_size.x), int(app.viewport_size.y))

	if run := app.run_func {
		run(&app)
		rl.close_window()
		return
	}

	render_done := chan bool{}
	update_done := chan bool{}

	$if !single_thread ? {
		spawn app.update_loop(update_done, render_done)
	}

	for !rl.window_should_close() {
		$if !single_thread ? {
			_ := <-update_done
		}

		mut scale := m.min(f64(rl.get_screen_width()) / app.viewport_size.x, f64(rl.get_screen_height()) / app.viewport_size.y)
		app.state.dt = rl.get_frame_time() * app.debug.time_scale

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

		$if single_thread ? {
			app.process_update()
		}

		rl.begin_texture_mode(app.viewport)
		if cam_node := app.active_camera {
			rl.begin_mode_2d(cam_node.camera)
		}
		rl.clear_background(app.clear_color)

		if draw := app.draw_func {
			draw()
		}

		if mut root := app.scene_root {
			emit_notification(mut root, .draw)
		}

		if app.debug.section_enabled('physics') {
			app.draw_physics_overlay()
		}

		if _ := app.active_camera {
			rl.end_mode_2d()
		}
		rl.end_texture_mode()

		rl.begin_drawing()
		rl.clear_background(app.backdrop_color)

		if backdrop_draw := app.backdrop_draw_func {
			backdrop_draw()
		}

		rl.draw_texture_pro(app.viewport.texture, vp_source, vp_dest, Vec2{}, 0, rl.white)
		app.draw_debug_panel()
		app.draw_inspector_panel()
		app.draw_input_panel()
		app.draw_menu_bar()
		rl.end_drawing()

		$if !single_thread ? {
			render_done <- true
		}
	}

	rl.close_window()
}
