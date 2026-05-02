module engine

import mv.typeinfo
import core { Vec2 }
import raylib as rl
import physics

pub fn register_builtin_nodes(mut r SceneRegistry, app &App) {
	r.register('Node', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := &Node{
				app:       unsafe { app }
				node_name: name
				scale:     Vec2{1, 1}
			}
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {}
	})

	r.register('DrawLayer', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := DrawLayer.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {}
	})

	r.register('Sprite', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := Sprite.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			s := unsafe { &Sprite(src) }
			enc.key('tint')
			write_color_scene(s.tint, mut enc)!
			enc.key('h_frames')
			enc.write_i64(i64(s.h_frames))!
			enc.key('v_frames')
			enc.write_i64(i64(s.v_frames))!
			enc.key('flip_h')
			enc.write_bool(s.flip_h)!
			enc.key('flip_v')
			enc.write_bool(s.flip_v)!
			enc.key('current_frame')
			enc.write_i64(i64(s.current_frame))!
			enc.key('centered')
			enc.write_bool(s.get_centered())!
			enc.key('offset')
			write_vec2_scene(s.get_offset(), mut enc)!
			enc.key('texture')
			enc.write_string(s.get_texture_id() or { '' })!
			enc.key('shader')
			enc.write_string(s.get_shader_id() or { '' })!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut s := unsafe { &Sprite(dst) }
			dec.seek_key('tint') or {}
			s.tint = read_color_scene(mut dec) or { rl.white }
			dec.seek_key('h_frames') or {}
			s.h_frames = int(dec.read_i64() or { 1 })
			dec.seek_key('v_frames') or {}
			s.v_frames = int(dec.read_i64() or { 1 })
			dec.seek_key('flip_h') or {}
			s.flip_h = dec.read_bool() or { false }
			dec.seek_key('flip_v') or {}
			s.flip_v = dec.read_bool() or { false }
			dec.seek_key('current_frame') or {}
			s.current_frame = int(dec.read_i64() or { 0 })
			dec.seek_key('centered') or {}
			s.set_centered(dec.read_bool() or { true })
			dec.seek_key('offset') or {}
			s.set_offset(read_vec2_scene(mut dec) or { Vec2{} })
			dec.seek_key('texture') or {}
			tex_id := dec.read_string() or { '' }
			if tex_id != '' {
				s.set_texture_id(tex_id) or {}
			}
			dec.seek_key('shader') or {}
			shader_id := dec.read_string() or { '' }
			if shader_id != '' {
				s.set_shader_id(shader_id) or {}
			}
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut s := unsafe { &Sprite(node_ptr) }
			mut changed := false

			mut tr := f32(s.tint.r)
			mut tg := f32(s.tint.g)
			mut tb := f32(s.tint.b)
			mut ta := f32(s.tint.a)
			mut tc := false
			if ctx.row_f32('tint.r', &tr) {
				tc = true
			}
			if ctx.row_f32('tint.g', &tg) {
				tc = true
			}
			if ctx.row_f32('tint.b', &tb) {
				tc = true
			}
			if ctx.row_f32('tint.a', &ta) {
				tc = true
			}
			if tc {
				s.tint = rl.Color{u8(tr), u8(tg), u8(tb), u8(ta)}
				changed = true
			}

			if ctx.row_int('h_frames', &s.h_frames) {
				if s.h_frames < 1 {
					s.h_frames = 1
				}
				changed = true
			}
			if ctx.row_int('v_frames', &s.v_frames) {
				if s.v_frames < 1 {
					s.v_frames = 1
				}
				changed = true
			}
			if ctx.row_bool('flip_h', &s.flip_h) {
				changed = true
			}
			if ctx.row_bool('flip_v', &s.flip_v) {
				changed = true
			}
			if ctx.row_int('frame', &s.current_frame) {
				changed = true
			}

			mut centered := s.get_centered()
			if ctx.row_bool('centered', &centered) {
				s.set_centered(centered)
				changed = true
			}

			mut offset := s.get_offset()
			if ctx.row_vec2('offset', &offset) {
				s.set_offset(offset)
				changed = true
			}

			old_tex := s.get_texture_id() or { '' }
			new_tex := ctx.row_resource('texture', old_tex, 'texture')
			if new_tex != old_tex {
				s.set_texture_id(new_tex) or {}
				changed = true
			}

			old_shd := s.get_shader_id() or { '' }
			new_shd := ctx.row_resource('shader', old_shd, 'shader')
			if new_shd != old_shd {
				s.set_shader_id(new_shd) or {}
				changed = true
			}

			return changed
		})
	})

	r.register('Timer', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := Timer.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			t := unsafe { &Timer(src) }
			enc.key('wait_time')
			enc.write_f64(f64(t.wait_time))!
			enc.key('one_shot')
			enc.write_bool(t.one_shot)!
			enc.key('autostart')
			enc.write_bool(t.autostart)!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut t := unsafe { &Timer(dst) }
			dec.seek_key('wait_time') or {}
			t.wait_time = f32(dec.read_f64() or { 1.0 })
			dec.seek_key('one_shot') or {}
			t.one_shot = dec.read_bool() or { true }
			dec.seek_key('autostart') or {}
			t.autostart = dec.read_bool() or { false }
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut t := unsafe { &Timer(node_ptr) }
			mut changed := false
			if ctx.row_f32('wait_time', &t.wait_time) {
				changed = true
			}
			if ctx.row_bool('one_shot', &t.one_shot) {
				changed = true
			}
			if ctx.row_bool('autostart', &t.autostart) {
				changed = true
			}
			return changed
		})
	})

	r.register('CameraNode', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := CameraNode.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			c := unsafe { &CameraNode(src) }
			enc.key('smoothing_enabled')
			enc.write_bool(c.smoothing_enabled)!
			enc.key('smoothing_speed')
			enc.write_f64(f64(c.smoothing_speed))!
			enc.key('limit_enabled')
			enc.write_bool(c.limit_enabled)!
			enc.key('limit_left')
			enc.write_f64(f64(c.limit_left))!
			enc.key('limit_right')
			enc.write_f64(f64(c.limit_right))!
			enc.key('limit_top')
			enc.write_f64(f64(c.limit_top))!
			enc.key('limit_bottom')
			enc.write_f64(f64(c.limit_bottom))!
			enc.key('drag_enabled')
			enc.write_bool(c.drag_enabled)!
			enc.key('drag_horizontal')
			enc.write_f64(f64(c.drag_horizontal))!
			enc.key('drag_vertical')
			enc.write_f64(f64(c.drag_vertical))!
			enc.key('shake_magnitude')
			enc.write_f64(f64(c.shake_magnitude))!
			enc.key('shake_decay')
			enc.write_f64(f64(c.shake_decay))!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut c := unsafe { &CameraNode(dst) }
			dec.seek_key('smoothing_enabled') or {}
			c.smoothing_enabled = dec.read_bool() or { false }
			dec.seek_key('smoothing_speed') or {}
			c.smoothing_speed = f32(dec.read_f64() or { 5.0 })
			dec.seek_key('limit_enabled') or {}
			c.limit_enabled = dec.read_bool() or { false }
			dec.seek_key('limit_left') or {}
			c.limit_left = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('limit_right') or {}
			c.limit_right = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('limit_top') or {}
			c.limit_top = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('limit_bottom') or {}
			c.limit_bottom = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('drag_enabled') or {}
			c.drag_enabled = dec.read_bool() or { false }
			dec.seek_key('drag_horizontal') or {}
			c.drag_horizontal = f32(dec.read_f64() or { 0.2 })
			dec.seek_key('drag_vertical') or {}
			c.drag_vertical = f32(dec.read_f64() or { 0.2 })
			dec.seek_key('shake_magnitude') or {}
			c.shake_magnitude = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('shake_decay') or {}
			c.shake_decay = f32(dec.read_f64() or { 5.0 })
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut c := unsafe { &CameraNode(node_ptr) }
			mut changed := false
			if ctx.row_bool('smoothing', &c.smoothing_enabled) {
				changed = true
			}
			if ctx.row_f32('smooth_spd', &c.smoothing_speed) {
				changed = true
			}
			if ctx.row_bool('limit', &c.limit_enabled) {
				changed = true
			}
			if ctx.row_f32('limit_l', &c.limit_left) {
				changed = true
			}
			if ctx.row_f32('limit_r', &c.limit_right) {
				changed = true
			}
			if ctx.row_f32('limit_t', &c.limit_top) {
				changed = true
			}
			if ctx.row_f32('limit_b', &c.limit_bottom) {
				changed = true
			}
			if ctx.row_bool('drag', &c.drag_enabled) {
				changed = true
			}
			if ctx.row_f32('drag_h', &c.drag_horizontal) {
				changed = true
			}
			if ctx.row_f32('drag_v', &c.drag_vertical) {
				changed = true
			}
			if ctx.row_f32('shake_decay', &c.shake_decay) {
				changed = true
			}
			return changed
		})
	})

	r.register('PhysicsBody', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := PhysicsBody.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			b := unsafe { &PhysicsBody(src) }
			enc.key('body_type')
			enc.write_string(if b.body_type == .static_body { 'static_body' } else { 'kinematic' })!
			enc.key('shape')
			write_shape_scene(b.shape, mut enc)!
			enc.key('shape_offset')
			write_vec2_scene(b.shape_offset, mut enc)!
			enc.key('collision_layer')
			enc.write_i64(i64(b.collision_layer))!
			enc.key('collision_mask')
			enc.write_i64(i64(b.collision_mask))!
			enc.key('up_direction')
			write_vec2_scene(b.up_direction, mut enc)!
			enc.key('floor_max_angle')
			enc.write_f64(f64(b.floor_max_angle))!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut b := unsafe { &PhysicsBody(dst) }
			dec.seek_key('body_type') or {}
			bt_str := dec.read_string() or { 'kinematic' }
			b.body_type = if bt_str == 'static_body' {
				BodyType.static_body
			} else {
				BodyType.kinematic
			}
			dec.seek_key('shape') or {}
			b.shape = read_shape_scene(mut dec) or { physics.Shape(physics.AABB{}) }
			dec.seek_key('shape_offset') or {}
			b.shape_offset = read_vec2_scene(mut dec) or { Vec2{} }
			dec.seek_key('collision_layer') or {}
			b.collision_layer = u32(dec.read_i64() or { 1 })
			dec.seek_key('collision_mask') or {}
			b.collision_mask = u32(dec.read_i64() or { 1 })
			dec.seek_key('up_direction') or {}
			b.up_direction = read_vec2_scene(mut dec) or { Vec2{0, -1} }
			dec.seek_key('floor_max_angle') or {}
			b.floor_max_angle = f32(dec.read_f64() or { 0.785398 })
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut b := unsafe { &PhysicsBody(node_ptr) }
			mut changed := false
			bt_idx := if b.body_type == .static_body { 0 } else { 1 }
			new_bt := ctx.row_enum_btn('body_type', ['Static', 'Kinematic'], bt_idx)
			if new_bt != bt_idx {
				b.body_type = if new_bt == 0 { BodyType.static_body } else { BodyType.kinematic }
				changed = true
			}
			shape_idx := match b.shape {
				physics.AABB { 0 }
				physics.Circle { 1 }
				physics.Capsule { 2 }
				else { 0 }
			}
			new_si := ctx.row_enum_btn('shape', ['AABB', 'Circle', 'Capsule'], shape_idx)
			if new_si != shape_idx {
				b.shape = match new_si {
					1 { physics.Shape(physics.Circle{}) }
					2 { physics.Shape(physics.Capsule{}) }
					else { physics.Shape(physics.AABB{}) }
				}
				changed = true
			}
			match mut b.shape {
				physics.AABB {
					mut mn_x := b.shape.min.x
					mut mn_y := b.shape.min.y
					mut mx_x := b.shape.max.x
					mut mx_y := b.shape.max.y
					if ctx.row_f32('min.x', &mn_x) {
						b.shape.min.x = mn_x
						changed = true
					}
					if ctx.row_f32('min.y', &mn_y) {
						b.shape.min.y = mn_y
						changed = true
					}
					if ctx.row_f32('max.x', &mx_x) {
						b.shape.max.x = mx_x
						changed = true
					}
					if ctx.row_f32('max.y', &mx_y) {
						b.shape.max.y = mx_y
						changed = true
					}
				}
				physics.Circle {
					mut cp_x := b.shape.p.x
					mut cp_y := b.shape.p.y
					mut cr := b.shape.r
					if ctx.row_f32('p.x', &cp_x) {
						b.shape.p.x = cp_x
						changed = true
					}
					if ctx.row_f32('p.y', &cp_y) {
						b.shape.p.y = cp_y
						changed = true
					}
					if ctx.row_f32('r', &cr) {
						b.shape.r = cr
						changed = true
					}
				}
				physics.Capsule {
					mut ca_x := b.shape.a.x
					mut ca_y := b.shape.a.y
					mut cb_x := b.shape.b.x
					mut cb_y := b.shape.b.y
					mut cr := b.shape.r
					if ctx.row_f32('a.x', &ca_x) {
						b.shape.a.x = ca_x
						changed = true
					}
					if ctx.row_f32('a.y', &ca_y) {
						b.shape.a.y = ca_y
						changed = true
					}
					if ctx.row_f32('b.x', &cb_x) {
						b.shape.b.x = cb_x
						changed = true
					}
					if ctx.row_f32('b.y', &cb_y) {
						b.shape.b.y = cb_y
						changed = true
					}
					if ctx.row_f32('r', &cr) {
						b.shape.r = cr
						changed = true
					}
				}
				else {}
			}
			if ctx.row_vec2('shape_off', &b.shape_offset) {
				changed = true
			}
			if ctx.row_bitfield('layer', &b.collision_layer, 8) {
				changed = true
			}
			if ctx.row_bitfield('mask', &b.collision_mask, 8) {
				changed = true
			}
			if ctx.row_vec2('up_dir', &b.up_direction) {
				changed = true
			}
			if ctx.row_f32('floor_ang', &b.floor_max_angle) {
				changed = true
			}
			return changed
		})
	})

	r.register('Line', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := Line.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			l := unsafe { &Line(src) }
			enc.key('width')
			enc.write_f64(f64(l.width))!
			enc.key('default_color')
			write_color_scene(l.default_color, mut enc)!
			enc.key('joint_mode')
			enc.write_i64(i64(l.joint_mode))!
			enc.key('cap_mode')
			enc.write_i64(i64(l.cap_mode))!
			enc.key('texture_mode')
			enc.write_i64(i64(l.texture_mode))!
			enc.key('closed')
			enc.write_bool(l.closed)!
			enc.key('texture')
			enc.write_string(l.get_texture_id() or { '' })!
			enc.key('points')
			enc.begin_array()!
			for p in l.points {
				write_vec2_scene(p, mut enc)!
			}
			enc.end_array()!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut l := unsafe { &Line(dst) }
			dec.seek_key('width') or {}
			l.width = f32(dec.read_f64() or { 4.0 })
			dec.seek_key('default_color') or {}
			l.default_color = read_color_scene(mut dec) or { rl.Color{255, 255, 255, 255} }
			dec.seek_key('joint_mode') or {}
			l.joint_mode = unsafe { LineJointMode(u8(dec.read_i64() or { 0 })) }
			dec.seek_key('cap_mode') or {}
			l.cap_mode = unsafe { LineCapMode(u8(dec.read_i64() or { 0 })) }
			dec.seek_key('texture_mode') or {}
			l.texture_mode = unsafe { LineTextureMode(u8(dec.read_i64() or { 0 })) }
			dec.seek_key('closed') or {}
			l.closed = dec.read_bool() or { false }
			dec.seek_key('texture') or {}
			tex_id := dec.read_string() or { '' }
			if tex_id != '' {
				l.set_texture_id(tex_id) or {}
			}
			dec.seek_key('points') or { return }
			dec.enter_array()!
			l.points = []Vec2{}
			for dec.has_next_element() {
				l.points << read_vec2_scene(mut dec)!
			}
			dec.exit_array()!
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut l := unsafe { &Line(node_ptr) }
			mut changed := false
			if ctx.row_f32('width', &l.width) {
				changed = true
			}
			if ctx.row_color('color', &l.default_color) {
				changed = true
			}
			joint_idx := int(l.joint_mode)
			new_joint := ctx.row_enum_btn('joint', ['Miter', 'Bevel', 'Round'], joint_idx)
			if new_joint != joint_idx {
				l.joint_mode = unsafe { LineJointMode(u8(new_joint)) }
				changed = true
			}
			cap_idx := int(l.cap_mode)
			new_cap := ctx.row_enum_btn('cap', ['Flat', 'Square', 'Round'], cap_idx)
			if new_cap != cap_idx {
				l.cap_mode = unsafe { LineCapMode(u8(new_cap)) }
				changed = true
			}
			tex_idx := int(l.texture_mode)
			new_tex_m := ctx.row_enum_btn('tex_mode', ['Stretch', 'Tile'], tex_idx)
			if new_tex_m != tex_idx {
				l.texture_mode = unsafe { LineTextureMode(u8(new_tex_m)) }
				changed = true
			}
			if ctx.row_bool('closed', &l.closed) {
				changed = true
			}
			old_tex := l.get_texture_id() or { '' }
			new_tex := ctx.row_resource('texture', old_tex, 'texture')
			if new_tex != old_tex {
				l.set_texture_id(new_tex) or {}
				changed = true
			}
			return changed
		})
	})

	r.register('Area2D', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := Area2D.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			a := unsafe { &Area2D(src) }
			enc.key('shape')
			write_shape_scene(a.shape, mut enc)!
			enc.key('shape_offset')
			write_vec2_scene(a.shape_offset, mut enc)!
			enc.key('collision_layer')
			enc.write_i64(i64(a.collision_layer))!
			enc.key('collision_mask')
			enc.write_i64(i64(a.collision_mask))!
			enc.key('monitoring')
			enc.write_bool(a.monitoring)!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut a := unsafe { &Area2D(dst) }
			dec.seek_key('shape') or {}
			a.shape = read_shape_scene(mut dec) or { physics.Shape(physics.AABB{}) }
			dec.seek_key('shape_offset') or {}
			a.shape_offset = read_vec2_scene(mut dec) or { Vec2{} }
			dec.seek_key('collision_layer') or {}
			a.collision_layer = u32(dec.read_i64() or { 1 })
			dec.seek_key('collision_mask') or {}
			a.collision_mask = u32(dec.read_i64() or { 1 })
			dec.seek_key('monitoring') or {}
			a.monitoring = dec.read_bool() or { true }
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut a := unsafe { &Area2D(node_ptr) }
			mut changed := false
			shape_idx := match a.shape {
				physics.AABB { 0 }
				physics.Circle { 1 }
				physics.Capsule { 2 }
				else { 0 }
			}
			new_si := ctx.row_enum_btn('shape', ['AABB', 'Circle', 'Capsule'], shape_idx)
			if new_si != shape_idx {
				a.shape = match new_si {
					1 { physics.Shape(physics.Circle{}) }
					2 { physics.Shape(physics.Capsule{}) }
					else { physics.Shape(physics.AABB{}) }
				}
				changed = true
			}
			match mut a.shape {
				physics.AABB {
					mut mn_x := a.shape.min.x
					mut mn_y := a.shape.min.y
					mut mx_x := a.shape.max.x
					mut mx_y := a.shape.max.y
					if ctx.row_f32('min.x', &mn_x) {
						a.shape.min.x = mn_x
						changed = true
					}
					if ctx.row_f32('min.y', &mn_y) {
						a.shape.min.y = mn_y
						changed = true
					}
					if ctx.row_f32('max.x', &mx_x) {
						a.shape.max.x = mx_x
						changed = true
					}
					if ctx.row_f32('max.y', &mx_y) {
						a.shape.max.y = mx_y
						changed = true
					}
				}
				physics.Circle {
					mut cp_x := a.shape.p.x
					mut cp_y := a.shape.p.y
					mut cr := a.shape.r
					if ctx.row_f32('p.x', &cp_x) {
						a.shape.p.x = cp_x
						changed = true
					}
					if ctx.row_f32('p.y', &cp_y) {
						a.shape.p.y = cp_y
						changed = true
					}
					if ctx.row_f32('r', &cr) {
						a.shape.r = cr
						changed = true
					}
				}
				physics.Capsule {
					mut ca_x := a.shape.a.x
					mut ca_y := a.shape.a.y
					mut cb_x := a.shape.b.x
					mut cb_y := a.shape.b.y
					mut cr := a.shape.r
					if ctx.row_f32('a.x', &ca_x) {
						a.shape.a.x = ca_x
						changed = true
					}
					if ctx.row_f32('a.y', &ca_y) {
						a.shape.a.y = ca_y
						changed = true
					}
					if ctx.row_f32('b.x', &cb_x) {
						a.shape.b.x = cb_x
						changed = true
					}
					if ctx.row_f32('b.y', &cb_y) {
						a.shape.b.y = cb_y
						changed = true
					}
					if ctx.row_f32('r', &cr) {
						a.shape.r = cr
						changed = true
					}
				}
				else {}
			}
			if ctx.row_vec2('shape_off', &a.shape_offset) {
				changed = true
			}
			if ctx.row_bitfield('layer', &a.collision_layer, 8) {
				changed = true
			}
			if ctx.row_bitfield('mask', &a.collision_mask, 8) {
				changed = true
			}
			if ctx.row_bool('monitoring', &a.monitoring) {
				changed = true
			}
			return changed
		})
	})

	r.register('StateMachine', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := StateMachine.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			_ = unsafe { &StateMachine(src) }
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			_ = unsafe { &StateMachine(dst) }
		}
	})

	r.register('ParticleEmitter', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := ParticleEmitter.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			e := unsafe { &ParticleEmitter(src) }
			enc.key('max_particles')
			enc.write_i64(i64(e.max_particles))!
			enc.key('emission_mode')
			enc.write_i64(i64(e.emission_mode))!
			enc.key('shape_kind')
			match e.shape {
				PointEmission { enc.write_string('point')! }
				CircleEmission { enc.write_string('circle')! }
				RectEmission { enc.write_string('rect')! }
				LineEmission { enc.write_string('line')! }
			}
			match e.shape {
				PointEmission {}
				CircleEmission {
					enc.key('shape_radius')
					enc.write_f64(f64(e.shape.radius))!
				}
				RectEmission {
					enc.key('shape_w')
					enc.write_f64(f64(e.shape.size.x))!
					enc.key('shape_h')
					enc.write_f64(f64(e.shape.size.y))!
				}
				LineEmission {
					enc.key('shape_len')
					enc.write_f64(f64(e.shape.length))!
					enc.key('shape_nx')
					enc.write_f64(f64(e.shape.normal.x))!
					enc.key('shape_ny')
					enc.write_f64(f64(e.shape.normal.y))!
				}
			}
			enc.key('emission_rate')
			enc.write_f64(f64(e.emission_rate))!
			enc.key('burst')
			enc.write_i64(i64(e.burst))!
			enc.key('one_shot')
			enc.write_bool(e.one_shot)!
			enc.key('autoplay')
			enc.write_bool(e.autoplay)!
			enc.key('lifetime_v')
			enc.write_f64(f64(e.lifetime.value))!
			enc.key('lifetime_r')
			enc.write_f64(f64(e.lifetime.randomness))!
			enc.key('speed_v')
			enc.write_f64(f64(e.initial_speed.value))!
			enc.key('speed_r')
			enc.write_f64(f64(e.initial_speed.randomness))!
			enc.key('scale_v')
			enc.write_f64(f64(e.scale_start.value))!
			enc.key('scale_r')
			enc.write_f64(f64(e.scale_start.randomness))!
			enc.key('rot_v')
			enc.write_f64(f64(e.rotation_start.value))!
			enc.key('rot_r')
			enc.write_f64(f64(e.rotation_start.randomness))!
			enc.key('angvel_v')
			enc.write_f64(f64(e.angular_vel.value))!
			enc.key('angvel_r')
			enc.write_f64(f64(e.angular_vel.randomness))!
			enc.key('dir')
			write_vec2_scene(e.direction, mut enc)!
			enc.key('spread')
			enc.write_f64(f64(e.spread))!
			enc.key('radial_v')
			enc.write_f64(f64(e.radial_accel.value))!
			enc.key('radial_r')
			enc.write_f64(f64(e.radial_accel.randomness))!
			enc.key('tang_v')
			enc.write_f64(f64(e.tangential_accel.value))!
			enc.key('tang_r')
			enc.write_f64(f64(e.tangential_accel.randomness))!
			enc.key('gravity')
			write_vec2_scene(e.gravity, mut enc)!
			enc.key('base_color')
			write_color_scene(e.base_color, mut enc)!
			enc.key('local_coords')
			enc.write_bool(e.local_coords)!
			enc.key('fixed_fps')
			enc.write_f64(f64(e.fixed_fps))!
			enc.key('preprocess')
			enc.write_f64(f64(e.preprocess))!
			enc.key('texture')
			enc.write_string(e.get_texture_id() or { '' })!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut e := unsafe { &ParticleEmitter(dst) }
			dec.seek_key('max_particles') or {}
			e.max_particles = int(dec.read_i64() or { 256 })
			dec.seek_key('emission_mode') or {}
			e.emission_mode = unsafe { EmissionMode(int(dec.read_i64() or { 0 })) }
			dec.seek_key('shape_kind') or {}
			sk := dec.read_string() or { 'point' }
			e.shape = match sk {
				'circle' {
					dec.seek_key('shape_radius') or {}
					r := f32(dec.read_f64() or { 32.0 })
					EmissionShape(CircleEmission{
						radius: r
					})
				}
				'rect' {
					dec.seek_key('shape_w') or {}
					w := f32(dec.read_f64() or { 32.0 })
					dec.seek_key('shape_h') or {}
					h := f32(dec.read_f64() or { 32.0 })
					EmissionShape(RectEmission{
						size: Vec2{w, h}
					})
				}
				'line' {
					dec.seek_key('shape_len') or {}
					ln := f32(dec.read_f64() or { 64.0 })
					dec.seek_key('shape_nx') or {}
					nx := f32(dec.read_f64() or { 0.0 })
					dec.seek_key('shape_ny') or {}
					ny := f32(dec.read_f64() or { -1.0 })
					EmissionShape(LineEmission{
						length: ln
						normal: Vec2{nx, ny}
					})
				}
				else {
					EmissionShape(PointEmission{})
				}
			}
			dec.seek_key('emission_rate') or {}
			e.emission_rate = f32(dec.read_f64() or { 20.0 })
			dec.seek_key('burst') or {}
			e.burst = int(dec.read_i64() or { 0 })
			dec.seek_key('one_shot') or {}
			e.one_shot = dec.read_bool() or { false }
			dec.seek_key('autoplay') or {}
			e.autoplay = dec.read_bool() or { true }
			dec.seek_key('lifetime_v') or {}
			e.lifetime.value = f32(dec.read_f64() or { 1.0 })
			dec.seek_key('lifetime_r') or {}
			e.lifetime.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('speed_v') or {}
			e.initial_speed.value = f32(dec.read_f64() or { 100.0 })
			dec.seek_key('speed_r') or {}
			e.initial_speed.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('scale_v') or {}
			e.scale_start.value = f32(dec.read_f64() or { 1.0 })
			dec.seek_key('scale_r') or {}
			e.scale_start.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('rot_v') or {}
			e.rotation_start.value = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('rot_r') or {}
			e.rotation_start.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('angvel_v') or {}
			e.angular_vel.value = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('angvel_r') or {}
			e.angular_vel.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('dir') or {}
			e.direction = read_vec2_scene(mut dec) or { Vec2{0, -1} }
			dec.seek_key('spread') or {}
			e.spread = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('radial_v') or {}
			e.radial_accel.value = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('radial_r') or {}
			e.radial_accel.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('tang_v') or {}
			e.tangential_accel.value = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('tang_r') or {}
			e.tangential_accel.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('gravity') or {}
			e.gravity = read_vec2_scene(mut dec) or { Vec2{} }
			dec.seek_key('base_color') or {}
			e.base_color = read_color_scene(mut dec) or { rl.white }
			dec.seek_key('local_coords') or {}
			e.local_coords = dec.read_bool() or { true }
			dec.seek_key('fixed_fps') or {}
			e.fixed_fps = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('preprocess') or {}
			e.preprocess = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('texture') or {}
			tex_id := dec.read_string() or { '' }
			if tex_id != '' {
				e.set_texture_id(tex_id) or {}
			}
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut e := unsafe { &ParticleEmitter(node_ptr) }
			mut changed := false
			if ctx.row_int('max_particles', &e.max_particles) {
				changed = true
			}
			em_idx := int(e.emission_mode)
			new_em := ctx.row_enum_btn('emit_mode', ['Volume', 'Surface', 'Directed'],
				em_idx)
			if new_em != em_idx {
				e.emission_mode = unsafe { EmissionMode(new_em) }
				changed = true
			}
			shape_idx := match e.shape {
				PointEmission { 0 }
				CircleEmission { 1 }
				RectEmission { 2 }
				LineEmission { 3 }
			}
			new_si := ctx.row_enum_btn('shape', ['Point', 'Circle', 'Rect', 'Line'], shape_idx)
			if new_si != shape_idx {
				e.shape = match new_si {
					1 { EmissionShape(CircleEmission{}) }
					2 { EmissionShape(RectEmission{}) }
					3 { EmissionShape(LineEmission{}) }
					else { EmissionShape(PointEmission{}) }
				}
				changed = true
			}
			match mut e.shape {
				PointEmission {}
				CircleEmission {
					mut r := e.shape.radius
					if ctx.row_f32('shape_r', &r) {
						e.shape.radius = r
						changed = true
					}
				}
				RectEmission {
					mut sx := e.shape.size.x
					mut sy := e.shape.size.y
					if ctx.row_f32('shape_w', &sx) {
						e.shape.size.x = sx
						changed = true
					}
					if ctx.row_f32('shape_h', &sy) {
						e.shape.size.y = sy
						changed = true
					}
				}
				LineEmission {
					mut ln := e.shape.length
					if ctx.row_f32('shape_len', &ln) {
						e.shape.length = ln
						changed = true
					}
					mut nrm := e.shape.normal
					if ctx.row_vec2('shape_nrm', &nrm) {
						e.shape.normal = nrm
						changed = true
					}
				}
			}
			if ctx.row_f32('rate', &e.emission_rate) {
				changed = true
			}
			if ctx.row_int('burst', &e.burst) {
				changed = true
			}
			if ctx.row_bool('one_shot', &e.one_shot) {
				changed = true
			}
			if ctx.row_bool('autoplay', &e.autoplay) {
				changed = true
			}
			if ctx.row_f32('lifetime.val', &e.lifetime.value) {
				changed = true
			}
			if ctx.row_f32('lifetime.rnd', &e.lifetime.randomness) {
				changed = true
			}
			if ctx.row_f32('speed.val', &e.initial_speed.value) {
				changed = true
			}
			if ctx.row_f32('speed.rnd', &e.initial_speed.randomness) {
				changed = true
			}
			if ctx.row_f32('scale.val', &e.scale_start.value) {
				changed = true
			}
			if ctx.row_f32('scale.rnd', &e.scale_start.randomness) {
				changed = true
			}
			if ctx.row_f32('rot.val', &e.rotation_start.value) {
				changed = true
			}
			if ctx.row_f32('rot.rnd', &e.rotation_start.randomness) {
				changed = true
			}
			if ctx.row_f32('angvel.val', &e.angular_vel.value) {
				changed = true
			}
			if ctx.row_f32('angvel.rnd', &e.angular_vel.randomness) {
				changed = true
			}
			if ctx.row_vec2('direction', &e.direction) {
				changed = true
			}
			if ctx.row_f32('spread', &e.spread) {
				changed = true
			}
			if ctx.row_f32('radial.val', &e.radial_accel.value) {
				changed = true
			}
			if ctx.row_f32('radial.rnd', &e.radial_accel.randomness) {
				changed = true
			}
			if ctx.row_f32('tang.val', &e.tangential_accel.value) {
				changed = true
			}
			if ctx.row_f32('tang.rnd', &e.tangential_accel.randomness) {
				changed = true
			}
			if ctx.row_vec2('gravity', &e.gravity) {
				changed = true
			}
			if ctx.row_color('color', &e.base_color) {
				changed = true
			}
			if ctx.row_bool('local_coords', &e.local_coords) {
				changed = true
			}
			if ctx.row_f32('fixed_fps', &e.fixed_fps) {
				changed = true
			}
			if ctx.row_f32('preprocess', &e.preprocess) {
				changed = true
			}
			old_tex := e.get_texture_id() or { '' }
			new_tex := ctx.row_resource('texture', old_tex, 'texture')
			if new_tex != old_tex {
				e.set_texture_id(new_tex) or {}
				changed = true
			}
			return changed
		})
	})

	r.register('Meter', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := Meter.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			m := unsafe { &Meter(src) }
			enc.key('value')
			enc.write_f64(f64(m.value))!
			enc.key('fill_mode')
			enc.write_i64(i64(m.fill_mode))!
			enc.key('screen_space')
			enc.write_bool(m.screen_space)!
			enc.key('size')
			write_vec2_scene(m.size, mut enc)!
			enc.key('tint')
			write_color_scene(m.tint, mut enc)!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut m := unsafe { &Meter(dst) }
			dec.seek_key('value') or {}
			m.value = f32(dec.read_f64() or { 1.0 })
			dec.seek_key('fill_mode') or {}
			m.fill_mode = unsafe { MeterFillMode(int(dec.read_i64() or { 0 })) }
			dec.seek_key('screen_space') or {}
			m.screen_space = dec.read_bool() or { true }
			dec.seek_key('size') or {}
			m.size = read_vec2_scene(mut dec) or { Vec2{} }
			dec.seek_key('tint') or {}
			m.tint = read_color_scene(mut dec) or { rl.white }
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut m := unsafe { &Meter(node_ptr) }
			mut changed := false
			if ctx.row_f32('value', &m.value) {
				changed = true
			}
			fm_idx := int(m.fill_mode)
			new_fm := ctx.row_enum_btn('fill_mode', ['L→R', 'R→L', 'T→B', 'B→T'],
				fm_idx)
			if new_fm != fm_idx {
				m.fill_mode = unsafe { MeterFillMode(new_fm) }
				changed = true
			}
			if ctx.row_bool('screen_space', &m.screen_space) {
				changed = true
			}
			if ctx.row_vec2('size', &m.size) {
				changed = true
			}
			if ctx.row_color('tint', &m.tint) {
				changed = true
			}
			return changed
		})
	})

	r.register('BurstEmitter', SceneNodeReg{
		construct: fn (name string, app &App) INode {
			mut n := BurstEmitter.instantiate(unsafe { app }, name)
			emit_notification(mut n, .init)
			return INode(n)
		}
		write:     fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) ! {
			e := unsafe { &BurstEmitter(src) }
			enc.key('num_particles')
			enc.write_i64(i64(e.num_particles))!
			enc.key('lifetime_v')
			enc.write_f64(f64(e.lifetime.value))!
			enc.key('lifetime_r')
			enc.write_f64(f64(e.lifetime.randomness))!
			enc.key('reverse')
			enc.write_bool(e.reverse)!
			enc.key('preprocess_amount')
			enc.write_f64(f64(e.preprocess_amount))!
			enc.key('repeat')
			enc.write_bool(e.repeat)!
			enc.key('autoplay')
			enc.write_bool(e.autoplay)!
			enc.key('image_scale')
			enc.write_f64(f64(e.image_scale))!
			enc.key('image_scale_rnd')
			enc.write_f64(f64(e.image_scale_randomness))!
			enc.key('base_color')
			write_color_scene(e.base_color, mut enc)!
			enc.key('blend_mode')
			enc.write_i64(i64(e.blend_mode))!
			enc.key('color_offset_high')
			enc.write_f64(f64(e.color_offset_high))!
			enc.key('color_offset_low')
			enc.write_f64(f64(e.color_offset_low))!
			enc.key('direction')
			write_vec2_scene(e.direction, mut enc)!
			enc.key('spread')
			enc.write_f64(f64(e.spread))!
			enc.key('center_conc')
			enc.write_f64(f64(e.center_concentration))!
			enc.key('dir_rot_v')
			enc.write_f64(f64(e.direction_rotation.value))!
			enc.key('dir_rot_r')
			enc.write_f64(f64(e.direction_rotation.randomness))!
			enc.key('start_radius')
			enc.write_f64(f64(e.start_radius))!
			enc.key('distance_v')
			enc.write_f64(f64(e.distance.value))!
			enc.key('distance_r')
			enc.write_f64(f64(e.distance.randomness))!
			enc.key('angle_v')
			enc.write_f64(f64(e.angle.value))!
			enc.key('angle_r')
			enc.write_f64(f64(e.angle.randomness))!
			enc.key('align_rot')
			enc.write_bool(e.align_sprite_rotation)!
			enc.key('rand_flip')
			enc.write_bool(e.randomly_flip_angle)!
			enc.key('offset')
			write_vec2_scene(e.offset, mut enc)!
			enc.key('local_coords')
			enc.write_bool(e.local_coords)!
			enc.key('texture')
			enc.write_string(e.get_texture_id() or { '' })!
			enc.key('gradient_texture')
			enc.write_string(e.get_gradient_texture_id() or { '' })!
		}
		read:      fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) ! {
			mut e := unsafe { &BurstEmitter(dst) }
			dec.seek_key('num_particles') or {}
			e.num_particles = int(dec.read_i64() or { 10 })
			dec.seek_key('lifetime_v') or {}
			e.lifetime.value = f32(dec.read_f64() or { 1.0 })
			dec.seek_key('lifetime_r') or {}
			e.lifetime.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('reverse') or {}
			e.reverse = dec.read_bool() or { false }
			dec.seek_key('preprocess_amount') or {}
			e.preprocess_amount = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('repeat') or {}
			e.repeat = dec.read_bool() or { false }
			dec.seek_key('autoplay') or {}
			e.autoplay = dec.read_bool() or { true }
			dec.seek_key('image_scale') or {}
			e.image_scale = f32(dec.read_f64() or { 1.0 })
			dec.seek_key('image_scale_rnd') or {}
			e.image_scale_randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('base_color') or {}
			e.base_color = read_color_scene(mut dec) or { rl.white }
			dec.seek_key('blend_mode') or {}
			e.blend_mode = unsafe { BlendMode(int(dec.read_i64() or { 0 })) }
			dec.seek_key('color_offset_high') or {}
			e.color_offset_high = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('color_offset_low') or {}
			e.color_offset_low = f32(dec.read_f64() or { -1.0 })
			dec.seek_key('direction') or {}
			e.direction = read_vec2_scene(mut dec) or { Vec2{1, 0} }
			dec.seek_key('spread') or {}
			e.spread = f32(dec.read_f64() or { 3.14159 })
			dec.seek_key('center_conc') or {}
			e.center_concentration = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('dir_rot_v') or {}
			e.direction_rotation.value = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('dir_rot_r') or {}
			e.direction_rotation.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('start_radius') or {}
			e.start_radius = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('distance_v') or {}
			e.distance.value = f32(dec.read_f64() or { 100.0 })
			dec.seek_key('distance_r') or {}
			e.distance.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('angle_v') or {}
			e.angle.value = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('angle_r') or {}
			e.angle.randomness = f32(dec.read_f64() or { 0.0 })
			dec.seek_key('align_rot') or {}
			e.align_sprite_rotation = dec.read_bool() or { true }
			dec.seek_key('rand_flip') or {}
			e.randomly_flip_angle = dec.read_bool() or { false }
			dec.seek_key('offset') or {}
			e.offset = read_vec2_scene(mut dec) or { Vec2{} }
			dec.seek_key('local_coords') or {}
			e.local_coords = dec.read_bool() or { true }
			dec.seek_key('texture') or {}
			tex_id := dec.read_string() or { '' }
			if tex_id != '' {
				e.set_texture_id(tex_id) or {}
			}
			dec.seek_key('gradient_texture') or {}
			gtex_id := dec.read_string() or { '' }
			if gtex_id != '' {
				e.set_gradient_texture_id(gtex_id) or {}
			}
		}
		inspect:   SceneInspectFn(fn (node_ptr voidptr, app &App, mut ctx IInspectCtx) bool {
			mut e := unsafe { &BurstEmitter(node_ptr) }
			mut changed := false
			if ctx.row_int('num_particles', &e.num_particles) {
				changed = true
			}
			if ctx.row_f32('lifetime.val', &e.lifetime.value) {
				changed = true
			}
			if ctx.row_f32('lifetime.rnd', &e.lifetime.randomness) {
				changed = true
			}
			if ctx.row_bool('reverse', &e.reverse) {
				changed = true
			}
			if ctx.row_f32('preprocess', &e.preprocess_amount) {
				changed = true
			}
			if ctx.row_bool('repeat', &e.repeat) {
				changed = true
			}
			if ctx.row_bool('autoplay', &e.autoplay) {
				changed = true
			}
			if ctx.row_f32('img_scale', &e.image_scale) {
				changed = true
			}
			if ctx.row_f32('img_scale_rnd', &e.image_scale_randomness) {
				changed = true
			}
			if ctx.row_color('color', &e.base_color) {
				changed = true
			}
			bm_idx := int(e.blend_mode)
			new_bm := ctx.row_enum_btn('blend', ['Mix', 'Add'], bm_idx)
			if new_bm != bm_idx {
				e.blend_mode = unsafe { BlendMode(new_bm) }
				changed = true
			}
			if ctx.row_f32('co_high', &e.color_offset_high) {
				changed = true
			}
			if ctx.row_f32('co_low', &e.color_offset_low) {
				changed = true
			}
			if ctx.row_vec2('direction', &e.direction) {
				changed = true
			}
			if ctx.row_f32('spread', &e.spread) {
				changed = true
			}
			if ctx.row_f32('center_conc', &e.center_concentration) {
				changed = true
			}
			if ctx.row_f32('dir_rot.val', &e.direction_rotation.value) {
				changed = true
			}
			if ctx.row_f32('dir_rot.rnd', &e.direction_rotation.randomness) {
				changed = true
			}
			if ctx.row_f32('start_radius', &e.start_radius) {
				changed = true
			}
			if ctx.row_f32('distance.val', &e.distance.value) {
				changed = true
			}
			if ctx.row_f32('distance.rnd', &e.distance.randomness) {
				changed = true
			}
			if ctx.row_f32('angle.val', &e.angle.value) {
				changed = true
			}
			if ctx.row_f32('angle.rnd', &e.angle.randomness) {
				changed = true
			}
			if ctx.row_bool('align_rot', &e.align_sprite_rotation) {
				changed = true
			}
			if ctx.row_bool('rand_flip', &e.randomly_flip_angle) {
				changed = true
			}
			if ctx.row_vec2('offset', &e.offset) {
				changed = true
			}
			if ctx.row_bool('local_coords', &e.local_coords) {
				changed = true
			}
			old_tex := e.get_texture_id() or { '' }
			new_tex := ctx.row_resource('texture', old_tex, 'texture')
			if new_tex != old_tex {
				e.set_texture_id(new_tex) or {}
				changed = true
			}
			old_gtex := e.get_gradient_texture_id() or { '' }
			new_gtex := ctx.row_resource('gradient_tex', old_gtex, 'texture')
			if new_gtex != old_gtex {
				e.set_gradient_texture_id(new_gtex) or {}
				changed = true
			}
			return changed
		})
	})
}
