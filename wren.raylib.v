module mv

import raylib as rl
import wren

// stored by value — rl.Color is 4 bytes (r, g, b, a u8), no pointer indirection
@[inline]
fn wren_get_color(vm &wren.VM, slot int) &rl.Color {
    return unsafe { &rl.Color(vm.get_slot_foreign(slot)) }
}

fn wren_push_color(vm &wren.VM, slot int, class_slot int, val rl.Color) {
    vm.ensure_slots(class_slot + 1)
    vm.get_variable('main', 'Color', class_slot)
    raw := vm.set_slot_new_foreign(slot, class_slot, sizeof(rl.Color))
    unsafe { 
    	ptr := &rl.Color(raw)
    	*ptr = val 
     }
}

fn color_wren_allocate(vm &wren.VM) {
    raw := vm.set_slot_new_foreign(0, 0, sizeof(rl.Color))
    unsafe {
    	ptr := &rl.Color(raw)
        *ptr = rl.Color{
            r: u8(vm.get_slot_double(1))
            g: u8(vm.get_slot_double(2))
            b: u8(vm.get_slot_double(3))
            a: u8(vm.get_slot_double(4))
        }
    }
}

fn color_wren_finalize(_ voidptr) {}

pub fn color_wren_class_methods() wren.ForeignClassMethods {
    return wren.ForeignClassMethods{
        allocate: color_wren_allocate
        finalize: color_wren_finalize
    }
}

// getters — components are read-only; construct a new Color to modify

fn color_wren_get_r(vm &wren.VM) { vm.set_slot_double(0, wren_get_color(vm, 0).r) }
fn color_wren_get_g(vm &wren.VM) { vm.set_slot_double(0, wren_get_color(vm, 0).g) }
fn color_wren_get_b(vm &wren.VM) { vm.set_slot_double(0, wren_get_color(vm, 0).b) }
fn color_wren_get_a(vm &wren.VM) { vm.set_slot_double(0, wren_get_color(vm, 0).a) }

// drawing

fn rl_wren_draw_rectangle(vm &wren.VM) {
    x     := int(vm.get_slot_double(1))
    y     := int(vm.get_slot_double(2))
    w     := int(vm.get_slot_double(3))
    h     := int(vm.get_slot_double(4))
    color := *wren_get_color(vm, 5)
    rl.draw_rectangle(x, y, w, h, color)
}

fn rl_wren_draw_circle(vm &wren.VM) {
    x      := int(vm.get_slot_double(1))
    y      := int(vm.get_slot_double(2))
    radius := f32(vm.get_slot_double(3))
    color  := *wren_get_color(vm, 4)
    rl.draw_circle(x, y, radius, color)
}

fn rl_wren_draw_line(vm &wren.VM) {
    x1    := int(vm.get_slot_double(1))
    y1    := int(vm.get_slot_double(2))
    x2    := int(vm.get_slot_double(3))
    y2    := int(vm.get_slot_double(4))
    color := *wren_get_color(vm, 5)
    rl.draw_line(x1, y1, x2, y2, color)
}

fn rl_wren_draw_text(vm &wren.VM) {
    text      := vm.get_slot_string(1)
    x         := int(vm.get_slot_double(2))
    y         := int(vm.get_slot_double(3))
    font_size := int(vm.get_slot_double(4))
    color     := *wren_get_color(vm, 5)
    rl.draw_text(text, x, y, font_size, color)
}

// input

fn rl_wren_is_key_down(vm &wren.VM) {
    vm.set_slot_bool(0, rl.is_key_down( int(vm.get_slot_double(1))))
}

fn rl_wren_is_key_pressed(vm &wren.VM) {
    vm.set_slot_bool(0, rl.is_key_pressed( int(vm.get_slot_double(1))) )
}

fn rl_wren_is_mouse_button_down(vm &wren.VM) {
    vm.set_slot_bool(0, rl.is_mouse_button_down( int(vm.get_slot_double(1))) )
}

fn rl_wren_get_mouse_position(vm &wren.VM) {
    // rl.get_mouse_position() returns rl.Vector2, which is the same underlying
    // C type as Vec2, so the cast is valid.
    pos := rl.get_mouse_position()
    wren_push_vec2(vm, 0, 1, Vec2{pos.x, pos.y})
}

pub fn color_wren_bind_method(signature string) wren.ForeignMethodFn {
    return match signature {
        'r' { color_wren_get_r }
        'g' { color_wren_get_g }
        'b' { color_wren_get_b }
        'a' { color_wren_get_a }
        else { unsafe { nil } }
    }
}

pub fn rl_wren_bind_method(signature string) wren.ForeignMethodFn {
    return match signature {
        'drawRectangle(_,_,_,_,_)' { rl_wren_draw_rectangle }
        'drawCircle(_,_,_,_)'      { rl_wren_draw_circle }
        'drawLine(_,_,_,_,_)'      { rl_wren_draw_line }
        'drawText(_,_,_,_,_)'      { rl_wren_draw_text }
        'isKeyDown(_)'             { rl_wren_is_key_down }
        'isKeyPressed(_)'          { rl_wren_is_key_pressed }
        'isMouseButtonDown(_)'     { rl_wren_is_mouse_button_down }
        'getMousePosition()'       { rl_wren_get_mouse_position }
        else                       { unsafe { nil } }
    }
}
