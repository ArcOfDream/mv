module typeinfo

import v.reflection

// short_type_name strips the module prefix from a V comptime T.name.
// T.name for imported types returns the qualified form (e.g. 'core.Vec2' or
// 'mv.core.Vec2'), while reflection.get_type returns just 'Vec2'. stripping
// to the last component keeps both sides of the registry consistent.
@[inline]
fn short_type_name(full string) string {
	return full.all_after_last('.')
}

pub struct ValueOpts {
pub:
	write_json ?WriteJsonFn
	read_json  ?ReadJsonFn
	write_bin  ?WriteBinFn
	read_bin   ?ReadBinFn
	// if true, default memcpy writer/reader of sizeof(T) bytes is installed
	// when write_bin/read_bin are nil. silent-memcpy is opt-in, not default.
	pod bool
}

pub struct ResourceOpts {
pub:
	// write_json is auto-generated (reads the handle's path via the manager),
	// so users only provide the read side - which needs to know *which*
	// manager to acquire from. that's supplied by a typed wrapper at the
	// engine.scene layer, not here.
	read_json  ?ReadJsonFn
	read_bin   ?ReadBinFn
	write_json ?WriteJsonFn // override if the default path-lookup isn't enough
	write_bin  ?WriteBinFn
}

pub struct NodeOpts {
pub:
	construct ?ConstructFn
	// nodes don't usually have custom write/read - the field walker handles
	// exports. hooks are here for escape hatches (e.g. a node with non-exportable
	// runtime state that still needs persisting).
	write_json ?WriteJsonFn
	read_json  ?ReadJsonFn
}

pub struct TypeRegistry {
pub mut:
	types map[string]&TypeInfo
}

pub fn TypeRegistry.new() &TypeRegistry {
	return &TypeRegistry{
		types: map[string]&TypeInfo{}
	}
}

pub fn (mut r TypeRegistry) register_value[T](opts ValueOpts) &TypeInfo {
	size := int(sizeof(T))
	name := short_type_name(T.name)
	mut info := &TypeInfo{
		name:       name
		size:       size
		kind:       .value
		write_json: opts.write_json
		read_json:  opts.read_json
		write_bin:  opts.write_bin
		read_bin:   opts.read_bin
	}
	if opts.pod && info.write_bin == none {
		info.write_bin = memcpy_writer(size)
	}
	if opts.pod && info.read_bin == none {
		info.read_bin = memcpy_reader(size)
	}
	r.types[name] = info
	return info
}

pub fn (mut r TypeRegistry) register_primitive[T](opts ValueOpts) &TypeInfo {
	// behaviorally identical to register_value; the kind tag is the only
	// difference. kept as a separate method so builtins.v reads self-documenting.
	mut info := r.register_value[T](opts)
	info.kind = .primitive
	return info
}

pub fn (mut r TypeRegistry) register_resource[T](opts ResourceOpts) &TypeInfo {
	name := short_type_name(T.name)
	info := &TypeInfo{
		name:       name
		size:       int(sizeof(T))
		kind:       .resource
		write_json: opts.write_json
		read_json:  opts.read_json
		write_bin:  opts.write_bin
		read_bin:   opts.read_bin
	}
	r.types[name] = info
	return info
}

pub fn (mut r TypeRegistry) register_node[T](opts NodeOpts) &TypeInfo {
	name := short_type_name(T.name)
	info := &TypeInfo{
		name:       name
		size:       int(sizeof(T))
		kind:       .node
		construct:  opts.construct
		write_json: opts.write_json
		read_json:  opts.read_json
	}
	r.types[name] = info
	return info
}

pub fn (r &TypeRegistry) lookup(name string) ?&TypeInfo {
	return r.types[name] or { return none }
}

// resolve a V comptime type index to the registry's string key. used by the
// field walker in serde.
//
// NOTE: this requires v.reflection at runtime
// TODO: check if field.typ.name works at comptime
pub fn name_of(type_idx int) string {
	t := reflection.get_type(type_idx) or { return '<unknown>' }
	return t.name
}

// --- memcpy defaults for POD value types ---

fn memcpy_writer(size int) WriteBinFn {
	return fn [size] (src voidptr, mut enc BinEncoder) ! {
		// BinEncoder.write_raw is defined in binary.v
		enc.write_raw(src, size)!
	}
}

fn memcpy_reader(size int) ReadBinFn {
	return fn [size] (mut dec BinDecoder, dst voidptr) ! {
		dec.read_raw(dst, size)!
	}
}
