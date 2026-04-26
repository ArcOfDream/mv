module main

import mv.core { Curve, CurvePoint, Vec2 }
import raylib { Color, Rectangle }
import mv.serde
import mv.typeinfo

// --- test structs ---

struct ScalarThing {
pub mut:
	pos      Vec2      @[export]
	tint     Color     @[export]
	bounds   Rectangle @[export]
	speed    f32       @[export]
	internal int
}

struct ArrayThing {
pub mut:
	points []CurvePoint @[export]
}

struct AliasedThing {
pub mut:
	position Vec2 @[export: 'pos']
}

// --- registry ---

fn test_registry_lookup_registered_type() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)
	assert reg.lookup('Vec2') or { panic('Vec2 not registered') } != unsafe { nil }
	assert reg.lookup('Color') or { panic('Color not registered') } != unsafe { nil }
	assert reg.lookup('Rectangle') or { panic('Rectangle not registered') } != unsafe { nil }
}

fn test_registry_lookup_missing_type() {
	mut reg := typeinfo.TypeRegistry.new()
	if _ := reg.lookup('NonExistent') {
		assert false, 'NonExistent should not be registered'
	}
}

fn test_registry_core_types_registered() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)
	typeinfo.register_core_types(mut reg)
	assert reg.lookup('Curve') or { panic('Curve not registered') } != unsafe { nil }
	assert reg.lookup('BakedCurve') or { panic('BakedCurve not registered') } != unsafe { nil }
	assert reg.lookup('CurvePoint') or { panic('CurvePoint not registered') } != unsafe { nil }
}

// --- scalar field round-trip ---

fn test_scalar_struct_round_trip() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)
	typeinfo.register_core_types(mut reg)

	original := ScalarThing{
		pos:      Vec2{3.0, 7.0}
		tint:     Color{255, 0, 128, 255}
		bounds:   Rectangle{1.0, 2.0, 64.0, 32.0}
		speed:    1.5
		internal: 999
	}

	mut enc := typeinfo.JsonEncoder.new()
	serde.write_struct(&original, reg, mut enc)!
	json := enc.to_string()

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := ScalarThing{}
	serde.read_struct(mut restored, reg, mut dec)!

	assert restored.pos.x == original.pos.x
	assert restored.pos.y == original.pos.y
	assert restored.tint.r == original.tint.r
	assert restored.tint.g == original.tint.g
	assert restored.tint.b == original.tint.b
	assert restored.tint.a == original.tint.a
	assert restored.bounds.x == original.bounds.x
	assert restored.bounds.width == original.bounds.width
	assert restored.speed == original.speed
}

fn test_unexported_field_not_serialized() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)

	original := ScalarThing{
		pos:      Vec2{1.0, 2.0}
		tint:     Color{255, 255, 255, 255}
		bounds:   Rectangle{0, 0, 10, 10}
		speed:    1.0
		internal: 42
	}

	mut enc := typeinfo.JsonEncoder.new()
	serde.write_struct(&original, reg, mut enc)!
	json := enc.to_string()

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := ScalarThing{}
	serde.read_struct(mut restored, reg, mut dec)!

	assert restored.internal == 0
}

fn test_missing_key_keeps_default() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)

	// only 'pos' is in JSON, 'speed' is absent
	json := '{"pos":{"x":5.0,"y":6.0}}'
	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := ScalarThing{
		speed: 99.0
	}
	serde.read_struct(mut restored, reg, mut dec)!

	assert restored.pos.x == 5.0
	assert restored.speed == 99.0
}

fn test_export_alias_used_as_key() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)

	original := AliasedThing{
		position: Vec2{1.0, 2.0}
	}
	mut enc := typeinfo.JsonEncoder.new()
	serde.write_struct(&original, reg, mut enc)!
	json := enc.to_string()

	assert json.contains('"pos"')
	assert !json.contains('"position"')

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := AliasedThing{}
	serde.read_struct(mut restored, reg, mut dec)!
	assert restored.position.x == 1.0
	assert restored.position.y == 2.0
}

// --- array field round-trip ---

fn test_array_field_round_trip() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)
	typeinfo.register_core_types(mut reg)

	original := ArrayThing{
		points: [
			CurvePoint{
				pos:       Vec2{0.0, 0.0}
				tangent_l: 1.0
				tangent_r: 1.0
			},
			CurvePoint{
				pos:       Vec2{0.5, 0.5}
				tangent_l: 0.5
				tangent_r: 0.5
			},
			CurvePoint{
				pos:       Vec2{1.0, 1.0}
				tangent_l: 1.0
				tangent_r: 1.0
			},
		]
	}

	mut enc := typeinfo.JsonEncoder.new()
	serde.write_struct(&original, reg, mut enc)!
	json := enc.to_string()

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := ArrayThing{}
	serde.read_struct(mut restored, reg, mut dec)!

	assert restored.points.len == original.points.len
	for i, p in original.points {
		r := restored.points[i]
		assert r.pos.x == p.pos.x
		assert r.pos.y == p.pos.y
		assert r.tangent_l == p.tangent_l
		assert r.tangent_r == p.tangent_r
	}
}

fn test_empty_array_field_round_trip() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)
	typeinfo.register_core_types(mut reg)

	original := ArrayThing{
		points: []
	}

	mut enc := typeinfo.JsonEncoder.new()
	serde.write_struct(&original, reg, mut enc)!
	json := enc.to_string()

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := ArrayThing{}
	serde.read_struct(mut restored, reg, mut dec)!

	assert restored.points.len == 0
}

// --- Curve round-trip via registry hook ---

fn test_curve_round_trip() {
	mut reg := typeinfo.TypeRegistry.new()
	typeinfo.register_builtins(mut reg)
	typeinfo.register_engine_types(mut reg)
	typeinfo.register_core_types(mut reg)

	original := Curve.linear()

	mut enc := typeinfo.JsonEncoder.new()
	hook := reg.lookup('Curve') or { panic('Curve not registered') }
	wfn := hook.write_json or { panic('Curve has no write_json') }
	wfn(voidptr(&original), mut enc)!
	json := enc.to_string()

	mut dec := typeinfo.JsonDecoder.parse(json)!
	mut restored := Curve{}
	rfn := hook.read_json or { panic('Curve has no read_json') }
	rfn(mut dec, voidptr(&restored))!

	assert restored.points.len == original.points.len
	for i, p in original.points {
		r := restored.points[i]
		assert r.pos.x == p.pos.x
		assert r.pos.y == p.pos.y
		assert r.tangent_l == p.tangent_l
		assert r.tangent_r == p.tangent_r
	}
	assert restored.min_value == original.min_value
	assert restored.max_value == original.max_value
}
