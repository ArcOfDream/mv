module engine

import mv.typeinfo

pub type SceneWriteFn = fn (src voidptr, app &App, mut enc typeinfo.JsonEncoder) !

pub type SceneReadFn = fn (mut dec typeinfo.JsonDecoder, dst voidptr, app &App) !

pub type SceneConstructFn = fn (name string, app &App) INode

pub struct SceneNodeReg {
pub:
	construct SceneConstructFn @[required]
	write     SceneWriteFn     @[required]
	read      SceneReadFn      @[required]
	inspect   ?SceneInspectFn
}

@[heap]
pub struct SceneRegistry {
pub mut:
	nodes map[string]SceneNodeReg
}

pub fn SceneRegistry.new() &SceneRegistry {
	return &SceneRegistry{}
}

pub fn (mut r SceneRegistry) register(type_name string, reg SceneNodeReg) {
	r.nodes[type_name] = reg
}
