module engine

import raylib as rl
import raylib.raygui as gui
import physics as phys
import math
import mv.resourcemanager { Handle, FontResource }

// DebugPanel - screen-space raygui overlay.
//
// Call at the end of the main loop, inside begin_drawing/end_drawing,
// after draw_texture_pro has composited the viewport:
//
//   rl.draw_texture_pro(...)
//   app.draw_debug_panel()
//   rl.end_drawing()
//
// Physics overlay runs in world space inside the viewport texture pass.
// Add this inside begin_texture_mode, after begin_mode_2d:
//
//   if app.debug.section_enabled('physics') {
//       app.draw_physics_overlay()
//   }
//
// Toggle panel visibility: F3

// ---- constants ---------------------------------------------------------------

const dbg_w = f32(290)
const dbg_row_h = f32(20)
const dbg_pad = f32(8)
const dbg_indent = f32(10)
const dbg_title_h = f32(24)
const dbg_toolbar_h = f32(24)
const dbg_col_sep = f32(130)
const dbg_node_max_h = f32(200) // max visible height of the scrollable node tree

// ---- section registry --------------------------------------------------------

pub struct DebugSection {
pub mut:
	id      string
	label   string
	title   string
	enabled bool = true
	open    bool = true
}

// ---- panel struct ------------------------------------------------------------

@[heap]
pub struct DebugPanel {
pub mut:
	visible bool = true
	x       f32  = 10
	y       f32  = 10

	sections       []DebugSection
	watches        map[string]string
	max_node_depth int = 5

	dragging   bool
	drag_off_x f32
	drag_off_y f32

	// node tree scroll state
	node_scroll rl.Vector2
	// outer panel scissor rect, saved each frame so the nodes branch can restore it
	scissor_rect rl.Rectangle
	
	debug_font Handle[FontResource]
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
			id:      'nodes'
			label:   'Tree'
			title:   'Scene tree'
			enabled: false
			open:    false
		},
		DebugSection{
			id:      'watches'
			label:   'Watch'
			title:   'Watches'
			enabled: true
			open:    true
		},
	]
	return p
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
// Pair with clear_watches() at the top of each frame.
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
	mp := rl.get_mouse_position()

	// drag via title bar
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

	// compute total height
	mut content_h := dbg_title_h + dbg_toolbar_h
	for s in d.sections {
		if !s.enabled {
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

	// save so inner scroll panel can restore it after overriding scissor mode
	d.scissor_rect = rl.Rectangle{
		x:      d.x
		y:      d.y + dbg_title_h
		width:  dbg_w
		height: panel_h - dbg_title_h
	}
	rl.begin_scissor_mode(int(d.scissor_rect.x), int(d.scissor_rect.y), int(d.scissor_rect.width),
		int(d.scissor_rect.height))

	dbg_draw_toolbar(d.x, d.y + dbg_title_h, mut d.sections)

	mut cy := d.y + dbg_title_h + dbg_toolbar_h + dbg_pad / 2

	for mut s in d.sections {
		if !s.enabled {
			continue
		}
		s.open = dbg_section_header(s.title, d.x, cy, s.open)
		cy += dbg_row_h
		if s.open {
			app.dbg_draw_section(s.id, d, d.x, mut cy)
		}
	}

	rl.end_scissor_mode()
}

// ---- physics overlay --------------------------------------------------------

// draw_physics_overlay must be called inside begin_texture_mode + begin_mode_2d.
// Iterates app.bodies directly; derives display bounds from shape fields without
// needing a mutable body reference.
pub fn (app &App) draw_physics_overlay() {
	static_color := rl.Color{
		r: 80
		g: 200
		b: 255
		a: 160
	} // blue  - static
	dynamic_color := rl.Color{
		r: 80
		g: 255
		b: 100
		a: 180
	} // green - kinematic

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

// dbg_body_rect derives a screen-space rl.Rectangle from a body's shape and
// current position without requiring a mutable receiver.
// Uses body.transform.translation + shape_offset as the world origin.
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

fn dbg_draw_toolbar(px f32, py f32, mut sections []DebugSection) {
	n := sections.len
	if n == 0 {
		return
	}
	btn_gap := f32(2)
	btn_h := dbg_toolbar_h - 4
	btn_w := (dbg_w - dbg_pad * 2 - btn_gap * f32(n - 1)) / f32(n)

	ctrl_btn := int(gui.GuiControl.button)
	prop_base := int(gui.GuiControlProperty.base_color_normal)
	prop_text := int(gui.GuiControlProperty.text_color_normal)

	for i, mut s in sections {
		bx := px + dbg_pad + f32(i) * (btn_w + btn_gap)
		r := rl.Rectangle{
			x:      bx
			y:      py + 2
			width:  btn_w
			height: btn_h
		}

		if !s.enabled {
			gui.gui_set_style(ctrl_btn, prop_base, 0x18181e) // darker than normal dark base
			gui.gui_set_style(ctrl_btn, prop_text, 0x505060) // clearly dimmed
		}
		if gui.gui_button(r, s.label) == 1 {
			s.enabled = !s.enabled
			if s.enabled {
				s.open = true
			}
		}
		if !s.enabled {
			gui.gui_set_style(ctrl_btn, prop_base, 0x2a2a42) // back to dark normal base
			gui.gui_set_style(ctrl_btn, prop_text, 0xcccccc)
		}
	}
}

// --- section dispatch ---

fn (app &App) dbg_draw_section(id string, d &DebugPanel, px f32, mut cy &f32) {
	match id {
		'perf' {
			fps := rl.get_fps()
			ft_ms := rl.get_frame_time() * 1000.0
			dbg_kv_row('fps', '${fps}', px, cy)
			cy += dbg_row_h
			dbg_kv_row('frame time', '${ft_ms:.2f} ms', px, cy)
			cy += dbg_row_h
		}
		'camera' {
			if cam := app.active_camera {
				c := cam.camera // rl.Camera2D
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
			dbg_kv_row('overlay', if d.section_enabled('physics') { 'on (mode2d)' } else { 'off' },
				px, cy)
			cy += dbg_row_h
		}
		'nodes' {
			if mut root := app.scene_root {
				node_count := app.count_visible_nodes(mut root, 0)
				content_h := f32(node_count) * dbg_row_h
				visible_h := if content_h < dbg_node_max_h { content_h } else { dbg_node_max_h }

				scroll_bounds := rl.Rectangle{
					x:      px
					y:      cy
					width:  dbg_w
					height: visible_h
				}
				content_rect := rl.Rectangle{
					x:      px
					y:      cy
					width:  dbg_w - 14
					height: content_h
				}
				mut view_rect := rl.Rectangle{}

				// gui_scroll_panel overrides the active scissor mode, so we end
				// the outer one first, then restore it after.
				rl.end_scissor_mode()
				gui.gui_scroll_panel(scroll_bounds, '', content_rect, &d.node_scroll,
					&view_rect)

				rl.begin_scissor_mode(int(view_rect.x), int(view_rect.y), int(view_rect.width),
					int(view_rect.height))
				mut draw_cy := *cy + d.node_scroll.y
				app.draw_node_rows(mut root, px, mut &draw_cy, 0)
				rl.end_scissor_mode()

				// restore outer panel scissor for any sections drawn after this one
				rl.begin_scissor_mode(int(d.scissor_rect.x), int(d.scissor_rect.y), int(d.scissor_rect.width),
					int(d.scissor_rect.height))

				cy += visible_h
			} else {
				dbg_label_row('(no scene root)', px, cy)
				cy += dbg_row_h
			}
		}
		'watches' {
			if d.watches.len == 0 {
				dbg_label_row('(none)', px, cy)
				cy += dbg_row_h
			} else {
				for name, val in d.watches {
					dbg_kv_row(name, val, px, cy)
					cy += dbg_row_h
				}
			}
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
			f32(2)
		}
		'camera' {
			f32(4)
		}
		'physics' {
			f32(3)
		}
		'nodes' {
			node_count := if mut root := app.scene_root {
				f32(app.count_visible_nodes(mut root, 0))
			} else {
				f32(1)
			}
			cap := dbg_node_max_h / dbg_row_h
			if node_count < cap {
				node_count
			} else {
				cap
			}
		}
		'watches' {
			watches_len := app.debug.watches.len
			n := if watches_len == 0 { 1 } else { watches_len }
			f32(n)
		}
		else {
			f32(1)
		}
	}
}

// --- node tree ---

fn (app &App) draw_node_rows(mut node INode, px f32, mut cy &f32, depth int) {
	if depth > app.debug.max_node_depth {
		return
	}
	indent_x := px + dbg_pad + f32(depth) * dbg_indent
	avail_w := dbg_w - (indent_x - px) - dbg_pad
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
	gui.gui_label(type_r, node.wren_class_name()) // typeof(node).name simply returns the INode type...
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

// DbgSavedStyle holds the raygui style properties that dbg_push_dark_style
// overrides, so dbg_pop_style can fully restore global state afterward.
struct DbgSavedStyle {
	// GuiControl.default
	d_bg      int // GuiDefaultProperty.background_color (19)
	d_line    int // GuiDefaultProperty.line_color       (18)
	d_text_sz int // GuiDefaultProperty.text_size        (16)
	d_text    int
	d_base    int
	d_border  int
	// GuiControl.label
	l_text int
	// GuiControl.button - all three interaction states
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

// dbg_push_dark_style saves the current raygui style, applies a dark theme and
// a slightly larger font, and returns the saved state for later restoration.
// Call before gui_window_box; restore with dbg_pop_style after end_scissor_mode.
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

	// apply dark theme
	gui.gui_set_style(d, pbg, 0x1e1e30ff) // panel body fill
	gui.gui_set_style(d, pli, 0x3c3c58ff) // title bar separator line
	gui.gui_set_style(d, pts, 16) // text size
	gui.gui_set_style(d, ptn, 0x7a7a8aff) // default text (approx 0xd4d4d4, R capped)
	gui.gui_set_style(d, pan, 0x242432ff) // default control base
	gui.gui_set_style(d, pbn, 0x3c3c58ff) // default border

	gui.gui_set_style(lbl, ptn, 0x7a7a8aff) // label text

	gui.gui_set_style(btn, pan, 0x2a2a42ff) // button base normal
	gui.gui_set_style(btn, ptn, 0x6e6e8aff) // button text normal (approx 0xcccccc, R capped)
	gui.gui_set_style(btn, pbn, 0x505078ff) // button border normal
	gui.gui_set_style(btn, paf, 0x353558ff) // button base focused
	gui.gui_set_style(btn, ptf, 0x7e7ea8ff) // button text focused (approx 0xffffff, R capped)
	gui.gui_set_style(btn, pbf, 0x6060a0ff) // button border focused
	gui.gui_set_style(btn, pap, 0x4a4a78ff) // button base pressed (unchanged, already valid)
	gui.gui_set_style(btn, ptp, 0x7e7ea8ff) // button text pressed (approx 0xffffff, R capped)
	gui.gui_set_style(btn, pbp, 0x7878c0ff) // button border pressed

	return saved
}

// dbg_pop_style restores the raygui style saved by dbg_push_dark_style.
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

// ---- row helpers ------------------------------------------------------------

fn dbg_section_header(title string, px f32, py f32, open bool) bool {
	label := '${if open { '[-]' } else { '[+]' }} ${title}'
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
	gui.gui_set_style(ctrl_lbl, prop_text, 0x5ecf8a)
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
// Explicit str() prevents V from auto-generating one that traverses into
// rl.Sound (via App.sounds -> SoundResource), where the V binding uses
// snake_case field names that don't match the C struct (e.g. frame_count vs
// frameCount), causing a C compile error.
pub fn (a &App) str() string {
	return 'App{}'
}
