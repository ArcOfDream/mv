module mv

import wren

//@[inline]
//fn wren_get_sprite(vm &wren.VM) &Sprite {
//    return unsafe { &Sprite(vm.get_slot_foreign(0)) }
//}

//fn sprite_wren_allocate(vm &wren.VM) {
//    raw := vm.set_slot_new_foreign(0, 0, sizeof(voidptr))
//    app := unsafe { &App(vm.get_user_data()) }
//    sprite := &Sprite{
//        Node: Node{
//            node_name: vm.get_slot_string(1)
//            app:       app
//        }
//    }
//    unsafe { 
//    	mut ptr := &&Sprite(raw)
//     *ptr = sprite
//    }
//}

fn sprite_wren_allocate(vm &wren.VM) {
    // tell Wren to allocate enough space for the WHOLE struct
    raw := vm.set_slot_new_foreign(0, 0, sizeof(Sprite))
    
    app := unsafe { &App(vm.get_user_data()) }
    
    // cast the raw memory block directly to a Node pointer
    mut node := unsafe { &Sprite(raw) }
    
    // initialize fields directly in the Wren-managed memory
    node.node_name = vm.get_slot_string(1)
    node.app = app
    node.wren_handle = vm.get_slot_handle(0)
}

fn sprite_wren_finalize(data voidptr) {}

pub fn sprite_wren_class_methods() wren.ForeignClassMethods {
    return wren.ForeignClassMethods{
        allocate: sprite_wren_allocate
        finalize: sprite_wren_finalize
    }
}


fn sprite_wren_get_centered(vm &wren.VM) {
    vm.set_slot_bool(0, wren_get_object[Sprite](vm).get_centered())
}

fn sprite_wren_set_centered(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.set_centered(vm.get_slot_bool(1))
}

fn sprite_wren_get_offset(vm &wren.VM) {
    offset := wren_get_object[Sprite](vm).get_offset()
    wren_push_vec2(vm, 0, 1, offset)
}

fn sprite_wren_set_offset(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.set_offset(*wren_get_vec2(vm, 1))
}

fn sprite_wren_set_texture_id(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.set_texture_id(vm.get_slot_string(1))
}

fn sprite_wren_set_shader_id(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.set_shader_id(vm.get_slot_string(1))
}

fn sprite_wren_get_h_frames(vm &wren.VM) {
    vm.set_slot_double(0, wren_get_object[Sprite](vm).h_frames)
}

fn sprite_wren_set_h_frames(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.h_frames = int(vm.get_slot_double(1))
}

fn sprite_wren_get_v_frames(vm &wren.VM) {
    vm.set_slot_double(0, wren_get_object[Sprite](vm).v_frames)
}

fn sprite_wren_set_v_frames(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.v_frames = int(vm.get_slot_double(1))
}

fn sprite_wren_get_current_frame(vm &wren.VM) {
    vm.set_slot_double(0, wren_get_object[Sprite](vm).current_frame)
}

fn sprite_wren_set_current_frame(vm &wren.VM) {
    mut s := wren_get_object[Sprite](vm)
    s.current_frame = int(vm.get_slot_double(1))
}

pub fn sprite_wren_bind_method(signature string) wren.ForeignMethodFn {
    return match signature {
        'centered'           { sprite_wren_get_centered }
        'centered=(_)'       { sprite_wren_set_centered }
        'offset'             { sprite_wren_get_offset }
        'offset=(_)'         { sprite_wren_set_offset }
        'textureId=(_)'      { sprite_wren_set_texture_id }
        'shaderId=(_)'       { sprite_wren_set_shader_id }
        'hFrames'            { sprite_wren_get_h_frames }
        'hFrames=(_)'        { sprite_wren_set_h_frames }
        'vFrames'            { sprite_wren_get_v_frames }
        'vFrames=(_)'        { sprite_wren_set_v_frames }
        'currentFrame'       { sprite_wren_get_current_frame }
        'currentFrame=(_)'   { sprite_wren_set_current_frame }
        // Node handlers work here because Sprite embeds Node at offset zero —
        // the recovered &Node pointer is valid for the leading Node fields.
        else                 { node_wren_bind_method(signature) }
    }
}