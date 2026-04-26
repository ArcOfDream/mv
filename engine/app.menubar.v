module engine

import raylib as rl
import raylib.raygui as gui

const mb_h = f32(24)
const mb_item_w = f32(120)
const mb_pad = f32(6)

@[heap]
pub struct MenuBar {
pub mut:
	visible bool = true
}

pub fn MenuBar.new() &MenuBar {
	return &MenuBar{}
}

pub fn (mut app App) draw_menu_bar() {
	if rl.is_key_pressed(int(rl.KeyboardKey.key_f2)) {
		app.menu_bar.visible = !app.menu_bar.visible
	}
	if !app.menu_bar.visible {
		return
	}

	sw := f32(rl.get_screen_width())
	rl.draw_rectangle(0, 0, int(sw), int(mb_h), rl.Color{0x1a, 0x1a, 0x28, 0xff})
	rl.draw_line(0, int(mb_h), int(sw), int(mb_h), rl.Color{0x3c, 0x3c, 0x58, 0xff})

	if f := app.debug.debug_font.get() {
		gui.gui_set_font(f.fnt)
	}
	saved := mb_push_style()
	defer { mb_pop_style(saved) }

	mut cx := mb_pad

	cx += mb_draw_item(mut app, 'Debug', cx, mut &app.debug.visible)
}

fn mb_draw_item(mut app App, label string, x f32, mut active &bool) f32 {
	act := *active
	r := rl.Rectangle{x, 1, mb_item_w, mb_h - 2}
	if act {
		rl.draw_rectangle_rec(r, rl.Color{0x2a, 0x2a, 0x42, 0xff})
	}
	text := if active { '[-] ${label}' } else { '[+] ${label}' }
	if gui.gui_label_button(r, text) == 1 {
		active = !act
	}
	return mb_item_w + mb_pad
}

// ---- style -------------------------------------------------------------------

struct MbSavedStyle {
	l_text_n  int
	l_text_f  int
	l_text_p  int
	d_text_sz int
}

fn mb_push_style() MbSavedStyle {
	d := int(gui.GuiControl.default)
	lbl := int(gui.GuiControl.label)
	ptn := int(gui.GuiControlProperty.text_color_normal)
	ptf := int(gui.GuiControlProperty.text_color_focused)
	ptp := int(gui.GuiControlProperty.text_color_pressed)
	pts := int(gui.GuiDefaultProperty.text_size)

	saved := MbSavedStyle{
		l_text_n:  gui.gui_get_style(lbl, ptn)
		l_text_f:  gui.gui_get_style(lbl, ptf)
		l_text_p:  gui.gui_get_style(lbl, ptp)
		d_text_sz: gui.gui_get_style(d, pts)
	}

	gui.gui_set_style(lbl, ptn, int(u32(0x8888a0ff)))
	gui.gui_set_style(lbl, ptf, int(u32(0xd4d4e8ff)))
	gui.gui_set_style(lbl, ptp, int(u32(0xffffffff)))
	gui.gui_set_style(d, pts, 16)

	return saved
}

fn mb_pop_style(s MbSavedStyle) {
	d := int(gui.GuiControl.default)
	lbl := int(gui.GuiControl.label)
	ptn := int(gui.GuiControlProperty.text_color_normal)
	ptf := int(gui.GuiControlProperty.text_color_focused)
	ptp := int(gui.GuiControlProperty.text_color_pressed)
	pts := int(gui.GuiDefaultProperty.text_size)

	gui.gui_set_style(lbl, ptn, s.l_text_n)
	gui.gui_set_style(lbl, ptf, s.l_text_f)
	gui.gui_set_style(lbl, ptp, s.l_text_p)
	gui.gui_set_style(d, pts, s.d_text_sz)
}
