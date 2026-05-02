module engine

import raylib as rl
import raylib.raygui as gui
import physics as phys
import math
import mv.resourcemanager { FontResource, Handle }
import core { Vec2 }

// DebugPanel - screen-space raygui overlay.
//
// call at the end of the main loop, inside begin_drawing/end_drawing,
// after draw_texture_pro has composited the viewport:
//
//   rl.draw_texture_pro(...)
//   app.draw_debug_panel()
//   app.draw_inspector_panel()
//   app.draw_input_panel()
//   rl.end_drawing()
//
// physics overlay runs in world space inside the viewport texture pass.
// add this inside begin_texture_mode, after begin_mode_2d:
//
//   if app.debug.section_enabled('physics') {
//       app.draw_physics_overlay()
//   }
//
// toggle panel visibility: F3
// inspector panel: toolbar 'Insp' button (floating, node tree + properties)
// input panel: toolbar 'Input' button (floating, mouse + keyboard monitor)

// ---- constants ---------------------------------------------------------------

const dbg_w = f32(290)
const dbg_row_h = f32(20)
const dbg_pad = f32(8)
const dbg_indent = f32(10)
const dbg_title_h = f32(24)
const dbg_toolbar_h = f32(24)
const dbg_col_sep = f32(130)
const insp_panel_ph = f32(460)
const input_panel_ph = f32(120)

// ---- floating panel structs --------------------------------------------------

@[heap]
pub struct InspectorPanel {
pub mut:
	px          f32
	py          f32 = 30
	positioned  bool
	dragging    bool
	drag_ox     f32
	drag_oy     f32
	tree_open   bool = true
	insp_open   bool = true
	tree_scroll rl.Vector2
}

@[heap]
pub struct InputPanel {
pub mut:
	px         f32
	py         f32 = 500
	positioned bool
	dragging   bool
	drag_ox    f32
	drag_oy    f32
}

// ---- section registry --------------------------------------------------------

struct NodeInspectorCache {
mut:
	valid            bool
	name             string
	type_name        string
	pos              Vec2
	scale            Vec2
	angle_deg        f32
	global_pos       Vec2
	global_scale     Vec2
	global_angle_deg f32
	child_count      int
	wren_owned       bool
	process_flags    ProcessFlags
	// pending writes applied by draw_node_rows next frame
	pending_pos   ?Vec2
	pending_angle ?f32
}

pub struct DebugSection {
pub mut:
	id       string
	label    string
	title    string
	enabled  bool = true
	open     bool = true
	floating bool // toolbar-only: drives a separate floating panel, not an inline section
}

// ---- panel struct ------------------------------------------------------------

@[heap]
pub struct DebugPanel {
pub mut:
	visible bool = true
	x       f32  = 10
	y       f32  = 30

	sections       []DebugSection
	watches        map[string]string
	max_node_depth int = 5

	dragging   bool
	drag_off_x f32
	drag_off_y f32

	debug_font Handle[FontResource]

	selected_node_ptr voidptr
	inspector_cache   NodeInspectorCache

	inspector_panel InspectorPanel
	input_panel     InputPanel

	// sparkline - ring buffer of raw frame times
	ft_buf  [120]f32
	ft_head int

	// time control
	time_scale f32 = 1.0
	paused     bool
	step_frame bool

	// inspector float editors: 0=pos.x  1=pos.y  2=angle
	insp_edit int = -1
	insp_bufs [3][32]u8

	// input panel - recent key presses
	key_log      [8]string
	key_log_head int
}

pub fn DebugPanel.new() &DebugPanel {
	mut p := &DebugPanel{}
	p.sections = [
		DebugSection{
			id:      'perf'
			label:   'Perf'
			title:   'Performance'
			enabled: true
			open:    true
		},
		DebugSection{
			id:      'camera'
			label:   'Cam'
			title:   'Camera2D'
			enabled: true
			open:    true
		},
		DebugSection{
			id:      'physics'
			label:   'Phys'
			title:   'Physics'
			enabled: true
			open:    true
		},
		DebugSection{
			id:      'watches'
			label:   'Watch'
			title:   'Watches'
			enabled: true
			open:    true
		},
		DebugSection{
			id:      'time'
			label:   'Time'
			title:   'Time'
			enabled: true
			open:    true
		},
		DebugSection{
			id:       'inspector'
			label:    'Insp'
			title:    'Inspector'
			enabled:  false
			open:     false
			floating: true
		},
		DebugSection{
			id:       'input'
			label:    'Input'
			title:    'Input'
			enabled:  false
			open:     false
			floating: true
		},
	]
	return p
}

pub fn (mut p DebugPanel) consume_step() bool {
	if p.step_frame {
		p.step_frame = false
		return true
	}
	return false
}

fn (mut d DebugPanel) update_key_log() {
	for {
		k := rl.get_key_pressed()
		if k == 0 {
			break
		}
		d.key_log[d.key_log_head % 8] = dbg_key_name(k)
		d.key_log_head++
	}
}

// register_section adds a new entry to the toolbar and draw loop at runtime.
pub fn (mut p DebugPanel) register_section(id string, label string, title string) {
	p.sections << DebugSection{
		id:    id
		label: label
		title: title
	}
}

pub fn (p &DebugPanel) section_enabled(id string) bool {
	for s in p.sections {
		if s.id == id {
			return s.enabled
		}
	}
	return false
}

// watch sets a named value shown in the Watches section.
pub fn (mut p DebugPanel) watch(name string, value string) {
	p.watches[name] = value
}

pub fn (mut p DebugPanel) clear_watches() {
	p.watches.clear()
}

// ---- main draw entry point ---------------------------------------------------

pub fn (mut app App) draw_debug_panel() {
	if rl.is_key_pressed(int(rl.KeyboardKey.key_f3)) {
		app.debug.visible = !app.debug.visible
	}
	if !app.debug.visible {
		return
	}

	mut d := app.debug

	d.ft_buf[d.ft_head % 120] = rl.get_frame_time()
	d.ft_head++

	mp := rl.get_mouse_position()

	title_rect := rl.Rectangle{
		x:      d.x
		y:      d.y
		width:  dbg_w
		height: dbg_title_h
	}
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left))
		&& rl.check_collision_point_rec(mp, title_rect) {
		d.dragging = true
		d.drag_off_x = mp.x - d.x
		d.drag_off_y = mp.y - d.y
	}
	if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		d.dragging = false
	}
	if d.dragging {
		d.x = mp.x - d.drag_off_x
		d.y = mp.y - d.drag_off_y
	}

	mut content_h := dbg_title_h + dbg_toolbar_h
	for s in d.sections {
		if !s.enabled || s.floating {
			continue
		}
		content_h += dbg_row_h
		if s.open {
			content_h += app.dbg_section_row_count(s.id) * dbg_row_h
		}
	}
	content_h += dbg_pad

	screen_h := f32(rl.get_screen_height())
	panel_h := if content_h > screen_h - d.y - 10 { screen_h - d.y - 10 } else { content_h }

	panel_rect := rl.Rectangle{
		x:      d.x
		y:      d.y
		width:  dbg_w
		height: panel_h
	}

	if font := app.debug.debug_font.get() {
		gui.gui_set_font(font.fnt)
	}
	saved := dbg_push_dark_style()
	defer { dbg_pop_style(saved) }

	if gui.gui_window_box(panel_rect, 'Debug') == 1 {
		d.visible = false
		return
	}

	scissor_r := rl.Rectangle{
		x:      d.x
		y:      d.y + dbg_title_h
		width:  dbg_w
		height: panel_h - dbg_title_h
	}
	rl.begin_scissor_mode(int(scissor_r.x), int(scissor_r.y), int(scissor_r.width), int(scissor_r.height))

	dbg_draw_toolbar(d.x, d.y + dbg_title_h, mut d.sections)

	mut cy := d.y + dbg_title_h + dbg_toolbar_h + dbg_pad / 2

	for mut s in d.sections {
		if !s.enabled || s.floating {
			continue
		}
		s.open = dbg_section_header(s.title, d.x, cy, s.open)
		cy += dbg_row_h
		if s.open {
			app.dbg_draw_section(s.id, d.x, mut cy)
		}
	}

	rl.end_scissor_mode()
}

// ---- inspector floating panel -----------------------------------------------

pub fn (mut app App) draw_inspector_panel() {
	mut insp_enabled := false
	for s in app.debug.sections {
		if s.id == 'inspector' {
			insp_enabled = s.enabled
			break
		}
	}
	if !insp_enabled {
		return
	}

	mut panel := &app.debug.inspector_panel
	mp := rl.get_mouse_position()
	sw := f32(rl.get_screen_width())
	sh := f32(rl.get_screen_height())

	if !panel.positioned {
		panel.px = app.debug.x + dbg_w + 10
		panel.py = app.debug.y
		panel.positioned = true
	}

	title_r := rl.Rectangle{
		x:      panel.px
		y:      panel.py
		width:  dbg_w
		height: dbg_title_h
	}
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left))
		&& rl.check_collision_point_rec(mp, title_r) {
		panel.dragging = true
		panel.drag_ox = mp.x - panel.px
		panel.drag_oy = mp.y - panel.py
	}
	if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		panel.dragging = false
	}
	if panel.dragging {
		panel.px = mp.x - panel.drag_ox
		panel.py = mp.y - panel.drag_oy
		if panel.px < 0 {
			panel.px = 0
		}
		if panel.px + dbg_w > sw {
			panel.px = sw - dbg_w
		}
		if panel.py < 0 {
			panel.py = 0
		}
		if panel.py + insp_panel_ph > sh {
			panel.py = sh - insp_panel_ph
		}
	}

	ph := if panel.py + insp_panel_ph > sh - 10 { sh - panel.py - 10 } else { insp_panel_ph }
	panel_r := rl.Rectangle{
		x:      panel.px
		y:      panel.py
		width:  dbg_w
		height: ph
	}

	if font := app.debug.debug_font.get() {
		gui.gui_set_font(font.fnt)
	}
	saved := dbg_push_dark_style()
	defer { dbg_pop_style(saved) }

	if gui.gui_window_box(panel_r, 'Inspector') == 1 {
		for mut s in app.debug.sections {
			if s.id == 'inspector' {
				s.enabled = false
			}
		}
		return
	}

	scissor_r := rl.Rectangle{
		x:      panel.px
		y:      panel.py + dbg_title_h
		width:  dbg_w
		height: ph - dbg_title_h
	}
	rl.begin_scissor_mode(int(scissor_r.x), int(scissor_r.y), int(scissor_r.width), int(scissor_r.height))

	mut cy := panel.py + dbg_title_h + dbg_pad * 0.5

	// --- scene tree ---
	panel.tree_open = dbg_section_header('Scene Tree', panel.px, cy, panel.tree_open)
	cy += dbg_row_h

	if panel.tree_open {
		// invalidate only when tree is drawn - keeps Properties visible while tree is collapsed
		app.debug.inspector_cache.valid = false
		if mut root := app.scene_root {
			node_count := app.count_visible_nodes(mut root, 0)
			content_h := f32(node_count) * dbg_row_h
			tree_vis_h := f32(160)
			visible_h := if content_h < tree_vis_h { content_h } else { tree_vis_h }

			scroll_bounds := rl.Rectangle{
				x:      panel.px
				y:      cy
				width:  dbg_w
				height: visible_h
			}
			content_rect := rl.Rectangle{
				x:      panel.px
				y:      cy
				width:  dbg_w - 14
				height: content_h
			}
			mut view_rect := rl.Rectangle{}

			rl.end_scissor_mode()
			gui.gui_scroll_panel(scroll_bounds, '', content_rect, &panel.tree_scroll,
				&view_rect)
			rl.begin_scissor_mode(int(view_rect.x), int(view_rect.y), int(view_rect.width),
				int(view_rect.height))
			mut draw_cy := view_rect.y + panel.tree_scroll.y
			app.draw_node_rows(mut root, panel.px, mut &draw_cy, 0)
			rl.end_scissor_mode()
			rl.begin_scissor_mode(int(scissor_r.x), int(scissor_r.y), int(scissor_r.width),
				int(scissor_r.height))

			cy += visible_h
		} else {
			dbg_label_row('(no scene root)', panel.px, cy)
			cy += dbg_row_h
		}
	}

	// --- properties ---
	panel.insp_open = dbg_section_header('Properties', panel.px, cy, panel.insp_open)
	cy += dbg_row_h

	if panel.insp_open {
		if !app.debug.inspector_cache.valid {
			dbg_label_row('(no node selected)', panel.px, cy)
			cy += dbg_row_h
		} else {
			cache := &app.debug.inspector_cache
			dbg_kv_row('name', cache.name, panel.px, cy)
			cy += dbg_row_h
			dbg_kv_row('type', cache.type_name, panel.px, cy)
			cy += dbg_row_h
			lbl_w := f32(24)
			half_w := (dbg_w - dbg_pad * 2 - lbl_w * 2 - 4) * 0.5
			bx := panel.px + dbg_pad
			gui.gui_label(rl.Rectangle{bx, cy, lbl_w, dbg_row_h}, 'pos')
			x_r := rl.Rectangle{bx + lbl_w, cy, half_w, dbg_row_h - 2}
			y_r := rl.Rectangle{bx + lbl_w + half_w + 4, cy, half_w, dbg_row_h - 2}
			if unsafe {
				C.GuiValueBoxFloat(x_r, c'', &app.debug.insp_bufs[0][0], &cache.pos.x,
					app.debug.insp_edit == 0)
			} == 1 {
				if app.debug.insp_edit == 0 {
					app.debug.inspector_cache.pending_pos = Vec2{cache.pos.x, cache.pos.y}
					app.debug.insp_edit = -1
				} else {
					app.debug.insp_edit = 0
				}
			}
			if unsafe {
				C.GuiValueBoxFloat(y_r, c'', &app.debug.insp_bufs[1][0], &cache.pos.y,
					app.debug.insp_edit == 1)
			} == 1 {
				if app.debug.insp_edit == 1 {
					app.debug.inspector_cache.pending_pos = Vec2{cache.pos.x, cache.pos.y}
					app.debug.insp_edit = -1
				} else {
					app.debug.insp_edit = 1
				}
			}
			cy += dbg_row_h
			dbg_kv_row('scale', '(${cache.scale.x:.2f}, ${cache.scale.y:.2f})', panel.px,
				cy)
			cy += dbg_row_h
			gui.gui_label(rl.Rectangle{bx, cy, lbl_w, dbg_row_h}, 'ang')
			a_r := rl.Rectangle{bx + lbl_w, cy, dbg_w - dbg_pad * 2 - lbl_w, dbg_row_h - 2}
			if unsafe {
				C.GuiValueBoxFloat(a_r, c'', &app.debug.insp_bufs[2][0], &cache.angle_deg,
					app.debug.insp_edit == 2)
			} == 1 {
				if app.debug.insp_edit == 2 {
					app.debug.inspector_cache.pending_angle = cache.angle_deg
					app.debug.insp_edit = -1
				} else {
					app.debug.insp_edit = 2
				}
			}
			cy += dbg_row_h
			dbg_kv_row('gpos', '(${cache.global_pos.x:.1f}, ${cache.global_pos.y:.1f})',
				panel.px, cy)
			cy += dbg_row_h
			dbg_kv_row('gscale', '(${cache.global_scale.x:.2f}, ${cache.global_scale.y:.2f})',
				panel.px, cy)
			cy += dbg_row_h
			dbg_kv_row('gangle', '${cache.global_angle_deg:.1f}', panel.px, cy)
			cy += dbg_row_h
			dbg_kv_row('children', '${cache.child_count}', panel.px, cy)
			cy += dbg_row_h
		}
	}

	rl.end_scissor_mode()
}

// ---- input floating panel ---------------------------------------------------

pub fn (mut app App) draw_input_panel() {
	mut input_enabled := false
	for s in app.debug.sections {
		if s.id == 'input' {
			input_enabled = s.enabled
			break
		}
	}
	if !input_enabled {
		return
	}

	app.debug.update_key_log()

	mut panel := &app.debug.input_panel
	mp := rl.get_mouse_position()
	sw := f32(rl.get_screen_width())
	sh := f32(rl.get_screen_height())

	if !panel.positioned {
		panel.px = app.debug.x + dbg_w + 10
		panel.py = app.debug.y + insp_panel_ph + 10
		panel.positioned = true
	}

	title_r := rl.Rectangle{
		x:      panel.px
		y:      panel.py
		width:  dbg_w
		height: dbg_title_h
	}
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left))
		&& rl.check_collision_point_rec(mp, title_r) {
		panel.dragging = true
		panel.drag_ox = mp.x - panel.px
		panel.drag_oy = mp.y - panel.py
	}
	if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		panel.dragging = false
	}
	if panel.dragging {
		panel.px = mp.x - panel.drag_ox
		panel.py = mp.y - panel.drag_oy
		if panel.px < 0 {
			panel.px = 0
		}
		if panel.px + dbg_w > sw {
			panel.px = sw - dbg_w
		}
		if panel.py < 0 {
			panel.py = 0
		}
		if panel.py + input_panel_ph > sh {
			panel.py = sh - input_panel_ph
		}
	}

	panel_r := rl.Rectangle{
		x:      panel.px
		y:      panel.py
		width:  dbg_w
		height: input_panel_ph
	}

	if font := app.debug.debug_font.get() {
		gui.gui_set_font(font.fnt)
	}
	saved := dbg_push_dark_style()
	defer { dbg_pop_style(saved) }

	if gui.gui_window_box(panel_r, 'Input') == 1 {
		for mut s in app.debug.sections {
			if s.id == 'input' {
				s.enabled = false
			}
		}
		return
	}

	scissor_r := rl.Rectangle{
		x:      panel.px
		y:      panel.py + dbg_title_h
		width:  dbg_w
		height: input_panel_ph - dbg_title_h
	}
	rl.begin_scissor_mode(int(scissor_r.x), int(scissor_r.y), int(scissor_r.width), int(scissor_r.height))

	mut cy := panel.py + dbg_title_h + dbg_pad * 0.5
	px := panel.px

	dbg_kv_row('screen', '(${int(mp.x)}, ${int(mp.y)})', px, cy)
	cy += dbg_row_h
	if cam := app.active_camera {
		wp := rl.get_screen_to_world_2d(mp, cam.camera)
		dbg_kv_row('world', '(${int(wp.x)}, ${int(wp.y)})', px, cy)
	} else {
		dbg_kv_row('world', '(no camera)', px, cy)
	}
	cy += dbg_row_h
	mb_str := '${if rl.is_mouse_button_down(0) { 'L' } else { '-' }}${if rl.is_mouse_button_down(1) {
		'R'
	} else {
		'-'
	}}${if rl.is_mouse_button_down(2) { 'M' } else { '-' }}'
	dbg_kv_row('mouse btn', mb_str, px, cy)
	cy += dbg_row_h
	mut keys_str := ''
	n_show := if app.debug.key_log_head < 8 { app.debug.key_log_head } else { 8 }
	for i in 0 .. n_show {
		idx := (app.debug.key_log_head - 1 - i + 8) % 8
		k := app.debug.key_log[idx]
		if k.len > 0 {
			if keys_str.len > 0 {
				keys_str += ' '
			}
			keys_str += k
		}
	}
	dbg_kv_row('keys', if keys_str.len > 0 { keys_str } else { '-' }, px, cy)

	rl.end_scissor_mode()
}

// ---- physics overlay --------------------------------------------------------

pub fn (app &App) draw_physics_overlay() {
	static_color := rl.Color{
		r: 80
		g: 200
		b: 255
		a: 160
	}
	dynamic_color := rl.Color{
		r: 80
		g: 255
		b: 100
		a: 180
	}

	for _, body in app.bodies {
		col := if body.body_type == .static_body { static_color } else { dynamic_color }
		rect := dbg_body_rect(body) or { continue }
		rl.draw_rectangle_lines_ex(rect, 1, col)

		cx := rect.x + rect.width * 0.5
		cy := rect.y + rect.height * 0.5
		rl.draw_line_v(rl.Vector2{cx - 3, cy}, rl.Vector2{cx + 3, cy}, col)
		rl.draw_line_v(rl.Vector2{cx, cy - 3}, rl.Vector2{cx, cy + 3}, col)
	}
}

fn dbg_body_rect(body &PhysicsBody) ?rl.Rectangle {
	pos := body.transform.translation + body.shape_offset
	return match body.shape {
		phys.AABB {
			rl.Rectangle{
				x:      body.shape.min.x + pos.x
				y:      body.shape.min.y + pos.y
				width:  body.shape.max.x - body.shape.min.x
				height: body.shape.max.y - body.shape.min.y
			}
		}
		phys.Circle {
			rl.Rectangle{
				x:      body.shape.p.x + pos.x - body.shape.r
				y:      body.shape.p.y + pos.y - body.shape.r
				width:  body.shape.r * 2
				height: body.shape.r * 2
			}
		}
		phys.Capsule {
			min_x := math.min(body.shape.a.x, body.shape.b.x) + pos.x - body.shape.r
			min_y := math.min(body.shape.a.y, body.shape.b.y) + pos.y - body.shape.r
			max_x := math.max(body.shape.a.x, body.shape.b.x) + pos.x + body.shape.r
			max_y := math.max(body.shape.a.y, body.shape.b.y) + pos.y + body.shape.r
			rl.Rectangle{
				x:      min_x
				y:      min_y
				width:  max_x - min_x
				height: max_y - min_y
			}
		}
		else {
			return none
		}
	}
}

// ---- toolbar ----------------------------------------------------------------

fn dbg_section_icon(id string) int {
	return match id {
		'perf' { int(gui.GuiIconName.icon_cpu) }
		'camera' { int(gui.GuiIconName.icon_camera) }
		'physics' { int(gui.GuiIconName.icon_tools) }
		'watches' { int(gui.GuiIconName.icon_eye_on) }
		'inspector' { int(gui.GuiIconName.icon_lens) }
		'time' { int(gui.GuiIconName.icon_sand_timer) }
		'input' { int(gui.GuiIconName.icon_cursor_classic) }
		else { int(gui.GuiIconName.icon_none) }
	}
}

fn dbg_draw_toolbar(px f32, py f32, mut sections []DebugSection) {
	n := sections.len
	if n == 0 {
		return
	}
	btn_gap := f32(2)
	btn_h := dbg_toolbar_h - 4
	btn_w := (dbg_w - dbg_pad * 2 - btn_gap * f32(n - 1)) / f32(n)

	for i, mut s in sections {
		bx := px + dbg_pad + f32(i) * (btn_w + btn_gap)
		r := rl.Rectangle{
			x:      bx
			y:      py + 2
			width:  btn_w
			height: btn_h
		}
		lbl := gui.gui_icon_text(dbg_section_icon(s.id), '')
		was := s.enabled
		gui.gui_toggle(r, lbl, &s.enabled)
		if !s.floating && s.enabled && !was {
			s.open = true
		}
	}
}

// --- section dispatch ---

fn (mut app App) dbg_draw_section(id string, px f32, mut cy &f32) {
	match id {
		'perf' {
			fps := rl.get_fps()
			ft_ms := rl.get_frame_time() * 1000.0
			dbg_kv_row('fps', '${fps}', px, cy)
			cy += dbg_row_h
			dbg_kv_row('frame time', '${ft_ms:.2f} ms', px, cy)
			cy += dbg_row_h
			dbg_draw_sparkline(app.debug.ft_buf, app.debug.ft_head, px, cy)
			cy += 44
		}
		'camera' {
			if cam := app.active_camera {
				c := cam.camera
				dbg_kv_row('target', '(${c.target.x:.1f}, ${c.target.y:.1f})', px, cy)
				cy += dbg_row_h
				dbg_kv_row('offset', '(${c.offset.x:.1f}, ${c.offset.y:.1f})', px, cy)
				cy += dbg_row_h
				dbg_kv_row('zoom', '${c.zoom:.3f}', px, cy)
				cy += dbg_row_h
				dbg_kv_row('rotation', '${c.rotation:.2f}', px, cy)
				cy += dbg_row_h
			} else {
				dbg_label_row('(no active camera)', px, cy)
				cy += dbg_row_h
			}
		}
		'physics' {
			mut dyn := 0
			mut sta := 0
			for _, b in app.bodies {
				if b.body_type == .static_body {
					sta++
				} else {
					dyn++
				}
			}
			cell_count := app.physics_world.hash.cells.len + app.physics_world.hash.static_cells.len
			body_count := app.bodies.len
			dbg_kv_row('bodies', '${body_count} (d:${dyn} s:${sta})', px, cy)
			cy += dbg_row_h
			dbg_kv_row('hash cells', '${cell_count}', px, cy)
			cy += dbg_row_h
			dbg_kv_row('overlay', if app.debug.section_enabled('physics') {
				'on (mode2d)'
			} else {
				'off'
			}, px, cy)
			cy += dbg_row_h
		}
		'watches' {
			if app.debug.watches.len == 0 {
				dbg_label_row('(none)', px, cy)
				cy += dbg_row_h
			} else {
				for name, val in app.debug.watches {
					dbg_kv_row(name, val, px, cy)
					cy += dbg_row_h
				}
			}
		}
		'time' {
			lbl_w := f32(52)
			bx := px + dbg_pad
			fw := dbg_w - dbg_pad * 2
			gui.gui_label(rl.Rectangle{bx, cy, lbl_w, dbg_row_h}, 'scale')
			gui.gui_slider(rl.Rectangle{bx + lbl_w, cy, fw - lbl_w - 34, dbg_row_h - 2},
				'', '${app.debug.time_scale:.2f}x', &app.debug.time_scale, 0.0, 2.0)
			cy += dbg_row_h
			pause_lbl := gui.gui_icon_text(int(gui.GuiIconName.icon_player_pause), if app.debug.paused {
				'Resume'
			} else {
				'Pause'
			})
			gui.gui_toggle(rl.Rectangle{bx, cy, fw, dbg_row_h - 2}, pause_lbl, &app.debug.paused)
			cy += dbg_row_h
			if app.debug.paused {
				step_lbl := gui.gui_icon_text(int(gui.GuiIconName.icon_step_over), 'Step frame')
				if gui.gui_button(rl.Rectangle{bx, cy, fw, dbg_row_h - 2}, step_lbl) == 1 {
					app.debug.step_frame = true
				}
			} else {
				dbg_label_row('(pause to step)', px, cy)
			}
			cy += dbg_row_h
		}
		else {
			dbg_label_row('(external)', px, cy)
			cy += dbg_row_h
		}
	}
}

fn (app &App) dbg_section_row_count(id string) f32 {
	return match id {
		'perf' {
			f32(2) + 44.0 / dbg_row_h
		}
		'camera' {
			f32(4)
		}
		'physics' {
			f32(3)
		}
		'watches' {
			n := if app.debug.watches.len == 0 { 1 } else { app.debug.watches.len }
			f32(n)
		}
		'time' {
			f32(3)
		}
		else {
			f32(1)
		}
	}
}

// --- node tree ---

fn (mut app App) draw_node_rows(mut node INode, px f32, mut cy &f32, depth int) {
	if depth > app.debug.max_node_depth {
		return
	}
	indent_x := px + dbg_pad + f32(depth) * dbg_indent
	avail_w := dbg_w - (indent_x - px) - dbg_pad
	row_r := rl.Rectangle{
		x:      indent_x
		y:      cy
		width:  avail_w
		height: dbg_row_h
	}
	if rl.check_collision_point_rec(rl.get_mouse_position(), row_r)
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		if app.debug.selected_node_ptr != node.node_ptr() {
			app.debug.insp_edit = -1
		}
		app.debug.selected_node_ptr = node.node_ptr()
	}
	if app.debug.selected_node_ptr != unsafe { nil }
		&& node.node_ptr() == app.debug.selected_node_ptr {
		// apply pending inspector edits before refreshing cache
		if pos := app.debug.inspector_cache.pending_pos {
			node.set_pos(pos)
		}
		if angle := app.debug.inspector_cache.pending_angle {
			node.set_angle_deg(angle)
		}
		rl.draw_rectangle_rec(row_r, rl.Color{60, 80, 120, 160})
		// struct replacement clears pending_pos/pending_angle (default to none)
		app.debug.inspector_cache = NodeInspectorCache{
			valid:            true
			name:             node.name()
			type_name:        node.wren_class_name()
			pos:              node.get_pos()
			scale:            node.get_scale()
			angle_deg:        node.get_angle_deg()
			global_pos:       node.get_global_pos()
			global_scale:     node.get_global_scale()
			global_angle_deg: node.get_global_angle_deg()
			child_count:      node.get_child_count()
			wren_owned:       node.wren_owned
			process_flags:    node.process_flags
		}
	}
	name_r := rl.Rectangle{
		x:      indent_x
		y:      cy
		width:  avail_w * 0.45
		height: dbg_row_h
	}
	type_r := rl.Rectangle{
		x:      indent_x + avail_w * 0.45
		y:      cy
		width:  avail_w * 0.55
		height: dbg_row_h
	}
	gui.gui_label(name_r, node.name())
	gui.gui_label(type_r, node.wren_class_name())
	cy += dbg_row_h
	for mut child in node.get_children() {
		app.draw_node_rows(mut child, px, mut cy, depth + 1)
	}
}

fn (app &App) count_visible_nodes(mut node INode, depth int) int {
	if depth > app.debug.max_node_depth {
		return 0
	}
	mut n := 1
	for mut child in node.get_children() {
		n += app.count_visible_nodes(mut child, depth + 1)
	}
	return n
}

// --- dark theme style ---

struct DbgSavedStyle {
	d_bg       int
	d_line     int
	d_text_sz  int
	d_text     int
	d_base     int
	d_border   int
	l_text     int
	b_base_n   int
	b_text_n   int
	b_border_n int
	b_base_f   int
	b_text_f   int
	b_border_f int
	b_base_p   int
	b_text_p   int
	b_border_p int
}

fn dbg_push_dark_style() DbgSavedStyle {
	d := int(gui.GuiControl.default)
	lbl := int(gui.GuiControl.label)
	btn := int(gui.GuiControl.button)

	pbn := int(gui.GuiControlProperty.border_color_normal)
	pan := int(gui.GuiControlProperty.base_color_normal)
	ptn := int(gui.GuiControlProperty.text_color_normal)
	pbf := int(gui.GuiControlProperty.border_color_focused)
	paf := int(gui.GuiControlProperty.base_color_focused)
	ptf := int(gui.GuiControlProperty.text_color_focused)
	pbp := int(gui.GuiControlProperty.border_color_pressed)
	pap := int(gui.GuiControlProperty.base_color_pressed)
	ptp := int(gui.GuiControlProperty.text_color_pressed)
	pts := int(gui.GuiDefaultProperty.text_size)
	pli := int(gui.GuiDefaultProperty.line_color)
	pbg := int(gui.GuiDefaultProperty.background_color)

	saved := DbgSavedStyle{
		d_bg:       gui.gui_get_style(d, pbg)
		d_line:     gui.gui_get_style(d, pli)
		d_text_sz:  gui.gui_get_style(d, pts)
		d_text:     gui.gui_get_style(d, ptn)
		d_base:     gui.gui_get_style(d, pan)
		d_border:   gui.gui_get_style(d, pbn)
		l_text:     gui.gui_get_style(lbl, ptn)
		b_base_n:   gui.gui_get_style(btn, pan)
		b_text_n:   gui.gui_get_style(btn, ptn)
		b_border_n: gui.gui_get_style(btn, pbn)
		b_base_f:   gui.gui_get_style(btn, paf)
		b_text_f:   gui.gui_get_style(btn, ptf)
		b_border_f: gui.gui_get_style(btn, pbf)
		b_base_p:   gui.gui_get_style(btn, pap)
		b_text_p:   gui.gui_get_style(btn, ptp)
		b_border_p: gui.gui_get_style(btn, pbp)
	}

	gui.gui_set_style(d, pbg, 0x1e1e30ff)
	gui.gui_set_style(d, pli, 0x3c3c58ff)
	gui.gui_set_style(d, pts, 16)
	gui.gui_set_style(d, ptn, 0x7a7a8aff)
	gui.gui_set_style(d, pan, 0x242432ff)
	gui.gui_set_style(d, pbn, 0x3c3c58ff)

	gui.gui_set_style(lbl, ptn, 0x7a7a8aff)

	gui.gui_set_style(btn, pan, 0x2a2a42ff)
	gui.gui_set_style(btn, ptn, 0x6e6e8aff)
	gui.gui_set_style(btn, pbn, 0x505078ff)
	gui.gui_set_style(btn, paf, 0x353558ff)
	gui.gui_set_style(btn, ptf, 0x7e7ea8ff)
	gui.gui_set_style(btn, pbf, 0x6060a0ff)
	gui.gui_set_style(btn, pap, 0x4a4a78ff)
	gui.gui_set_style(btn, ptp, 0x7e7ea8ff)
	gui.gui_set_style(btn, pbp, 0x7878c0ff)

	return saved
}

fn dbg_pop_style(s DbgSavedStyle) {
	d := int(gui.GuiControl.default)
	lbl := int(gui.GuiControl.label)
	btn := int(gui.GuiControl.button)

	pbn := int(gui.GuiControlProperty.border_color_normal)
	pan := int(gui.GuiControlProperty.base_color_normal)
	ptn := int(gui.GuiControlProperty.text_color_normal)
	pbf := int(gui.GuiControlProperty.border_color_focused)
	paf := int(gui.GuiControlProperty.base_color_focused)
	ptf := int(gui.GuiControlProperty.text_color_focused)
	pbp := int(gui.GuiControlProperty.border_color_pressed)
	pap := int(gui.GuiControlProperty.base_color_pressed)
	ptp := int(gui.GuiControlProperty.text_color_pressed)
	pts := int(gui.GuiDefaultProperty.text_size)
	pli := int(gui.GuiDefaultProperty.line_color)
	pbg := int(gui.GuiDefaultProperty.background_color)

	gui.gui_set_style(d, pbg, s.d_bg)
	gui.gui_set_style(d, pli, s.d_line)
	gui.gui_set_style(d, pts, s.d_text_sz)
	gui.gui_set_style(d, ptn, s.d_text)
	gui.gui_set_style(d, pan, s.d_base)
	gui.gui_set_style(d, pbn, s.d_border)
	gui.gui_set_style(lbl, ptn, s.l_text)
	gui.gui_set_style(btn, pan, s.b_base_n)
	gui.gui_set_style(btn, ptn, s.b_text_n)
	gui.gui_set_style(btn, pbn, s.b_border_n)
	gui.gui_set_style(btn, paf, s.b_base_f)
	gui.gui_set_style(btn, ptf, s.b_text_f)
	gui.gui_set_style(btn, pbf, s.b_border_f)
	gui.gui_set_style(btn, pap, s.b_base_p)
	gui.gui_set_style(btn, ptp, s.b_text_p)
	gui.gui_set_style(btn, pbp, s.b_border_p)
}

// ---- sparkline + key helpers ------------------------------------------------

fn dbg_draw_sparkline(ft_buf [120]f32, head int, px f32, cy f32) {
	w := dbg_w - dbg_pad * 2
	h := f32(40)
	bx := px + dbg_pad
	target := f32(1.0 / 60.0)
	max_ft := target * 3.0
	bar_w := w / 120.0

	rl.draw_rectangle_rec(rl.Rectangle{bx, cy, w, h}, rl.Color{0x10, 0x10, 0x18, 0xff})
	for i in 0 .. 120 {
		ft := ft_buf[(head + i) % 120]
		ratio := if f64(ft) / f64(max_ft) < 1.0 { f64(ft) / f64(max_ft) } else { 1.0 }
		bar_h := f32(ratio) * h
		col := if ft <= target * 1.1 {
			rl.Color{0x40, 0xff, 0x40, 0xff}
		} else if ft <= target * 2.0 {
			rl.Color{0xff, 0xcc, 0x00, 0xff}
		} else {
			rl.Color{0xff, 0x44, 0x44, 0xff}
		}
		rl.draw_rectangle(int(bx + f32(i) * bar_w), int(cy + h - bar_h), if bar_w >= 1.0 {
			int(bar_w)
		} else {
			1
		}, int(bar_h), col)
	}
	y60 := cy + h - h * (target / max_ft)
	y30 := cy + h - h * (target * 2.0 / max_ft)
	rl.draw_line(int(bx), int(y60), int(bx + w), int(y60), rl.Color{0x40, 0xff, 0x40, 0x50})
	rl.draw_line(int(bx), int(y30), int(bx + w), int(y30), rl.Color{0xff, 0xcc, 0x00, 0x50})
}

fn dbg_key_name(k int) string {
	return match k {
		32 { 'SPC' }
		13 { 'ENT' }
		27 { 'ESC' }
		9 { 'TAB' }
		int(rl.KeyboardKey.key_left) { 'left' }
		int(rl.KeyboardKey.key_right) { 'right' }
		int(rl.KeyboardKey.key_up) { 'up' }
		int(rl.KeyboardKey.key_down) { 'down' }
		65...90 { rune(k).str() }
		48...57 { rune(k).str() }
		else { '#${k}' }
	}
}

// ---- row helpers ------------------------------------------------------------

fn dbg_section_header(title string, px f32, py f32, open bool) bool {
	arrow := if open {
		int(gui.GuiIconName.icon_arrow_down_fill)
	} else {
		int(gui.GuiIconName.icon_arrow_right_fill)
	}
	label := '${gui.gui_icon_text(arrow, '')} ${title}'
	r := rl.Rectangle{
		x:      px + dbg_pad
		y:      py
		width:  dbg_w - dbg_pad * 2
		height: dbg_row_h
	}
	gui.gui_label(r, label)
	if rl.check_collision_point_rec(rl.get_mouse_position(), r)
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		return !open
	}
	return open
}

fn dbg_kv_row(key string, val string, px f32, py f32) {
	ctrl_lbl := int(gui.GuiControl.label)
	prop_text := int(gui.GuiControlProperty.text_color_normal)
	key_r := rl.Rectangle{
		x:      px + dbg_pad
		y:      py
		width:  dbg_col_sep - dbg_pad
		height: dbg_row_h
	}
	val_r := rl.Rectangle{
		x:      px + dbg_col_sep
		y:      py
		width:  dbg_w - dbg_col_sep - dbg_pad
		height: dbg_row_h
	}
	gui.gui_label(key_r, key)
	prev := gui.gui_get_style(ctrl_lbl, prop_text)
	gui.gui_set_style(ctrl_lbl, prop_text, 0x8eff8a)
	gui.gui_label(val_r, val)
	gui.gui_set_style(ctrl_lbl, prop_text, prev)
}

fn dbg_label_row(text string, px f32, py f32) {
	ctrl_lbl := int(gui.GuiControl.label)
	prop_text := int(gui.GuiControlProperty.text_color_normal)
	r := rl.Rectangle{
		x:      px + dbg_pad * 2
		y:      py
		width:  dbg_w - dbg_pad * 3
		height: dbg_row_h
	}
	prev := gui.gui_get_style(ctrl_lbl, prop_text)
	gui.gui_set_style(ctrl_lbl, prop_text, 0xaaaaaa)
	gui.gui_label(r, text)
	gui.gui_set_style(ctrl_lbl, prop_text, prev)
}

// ---- App str() --------------------------------------------------------------
// explicit str() prevents V from auto-generating one that traverses into
// rl.Sound (via App.sounds -> SoundResource), where the V binding uses
// snake_case field names that don't match the C struct.
pub fn (a &App) str() string {
	return 'App{}'
}
