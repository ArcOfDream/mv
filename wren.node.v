module mv

import wren

@[inline]
fn wren_get_node(vm &wren.VM) &Node {
    return unsafe { &Node(vm.get_slot_foreign(0)) }
}

//fn node_wren_allocate(vm &wren.VM) {
//    raw := vm.set_slot_new_foreign(0, 0, sizeof(voidptr))
//    app := unsafe { &App(vm.get_user_data()) }
//    node := &Node{
//        node_name: vm.get_slot_string(1)
//        app:       app
//    }
    
//    unsafe { 
//    	mut ptr := &&Node(raw)
//    	*ptr = node
//    }
//}

fn node_wren_allocate(vm &wren.VM) {
    // tell Wren to allocate enough space for the WHOLE struct
    raw := vm.set_slot_new_foreign(0, 0, sizeof(Node))
    
    app := unsafe { &App(vm.get_user_data()) }
    
    // cast the raw memory block directly to a Node pointer
    mut node := unsafe { &Node(raw) }
    
    // initialize fields directly in the Wren-managed memory
    node.node_name = vm.get_slot_string(1)
    node.app = app
    node.wren_handle = vm.get_slot_handle(0)
}

fn node_wren_finalize(_data voidptr) {}

pub fn node_wren_class_methods() wren.ForeignClassMethods {
    return wren.ForeignClassMethods{
        allocate: node_wren_allocate
        finalize: node_wren_finalize
    }
}

// name

fn node_wren_get_name(vm &wren.VM) {
    vm.set_slot_string(0, wren_get_object[Node](vm).name())
}

// pos  (Vec2)

fn node_wren_get_pos(vm &wren.VM) {
    pos := wren_get_object[Node](vm).pos   // copy value before slot 0 is overwritten
    wren_push_vec2(vm, 0, 1, pos)
}

fn node_wren_set_pos(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    n.set_pos(*wren_get_vec2(vm, 1))
}

// scale  (Vec2)

fn node_wren_get_scale(vm &wren.VM) {
    scale := wren_get_object[Node](vm).scale
    wren_push_vec2(vm, 0, 1, scale)
}

fn node_wren_set_scale(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    n.set_scale(*wren_get_vec2(vm, 1))
}

// angle (scalar doubles)

fn node_wren_get_angle_deg(vm &wren.VM) {
    vm.set_slot_double(0, wren_get_object[Node](vm).get_angle_deg())
}

fn node_wren_set_angle_deg(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    n.set_angle_deg(f32(vm.get_slot_double(1)))
}

fn node_wren_get_angle_rad(vm &wren.VM) {
    vm.set_slot_double(0, wren_get_object[Node](vm).get_angle_rad())
}

fn node_wren_set_angle_rad(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    n.set_angle_rad(f32(vm.get_slot_double(1)))
}

// global transforms

fn node_wren_get_global_pos(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    pos := n.get_global_pos()      // mut receiver — copy before overwriting slot 0
    wren_push_vec2(vm, 0, 1, pos)
}

fn node_wren_get_global_scale(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    scale := n.get_global_scale()
    wren_push_vec2(vm, 0, 1, scale)
}

fn node_wren_get_global_angle_deg(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    vm.set_slot_double(0, n.get_global_angle_deg())
}

fn node_wren_get_global_angle_rad(vm &wren.VM) {
    mut n := wren_get_object[Node](vm)
    vm.set_slot_double(0, n.get_global_angle_rad())
}

// addChild

fn node_wren_add_child(vm &wren.VM) {
    mut parent := wren_get_object[Node](vm)
    mut child := unsafe { &Node(vm.get_slot_foreign(1)) }
    parent.add_child(mut child)
}

// Bind callback (called from the top-level dispatcher)

pub fn node_wren_bind_method(signature string) wren.ForeignMethodFn {
    return match signature {
        'name'           { node_wren_get_name }
        'pos'            { node_wren_get_pos }
        'pos=(_)'        { node_wren_set_pos }
        'scale'          { node_wren_get_scale }
        'scale=(_)'      { node_wren_set_scale }
        'angleDeg'       { node_wren_get_angle_deg }
        'angleDeg=(_)'   { node_wren_set_angle_deg }
        'angleRad'       { node_wren_get_angle_rad }
        'angleRad=(_)'   { node_wren_set_angle_rad }
        'globalPos'      { node_wren_get_global_pos }
        'globalScale'    { node_wren_get_global_scale }
        'globalAngleDeg' { node_wren_get_global_angle_deg }
        'globalAngleRad' { node_wren_get_global_angle_rad }
        'addChild(_)'    { node_wren_add_child }
        else             { wren_nothing }
    }
}

