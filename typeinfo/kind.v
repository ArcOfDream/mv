module typeinfo

pub enum TypeKind {
	primitive // leaf types registered by builtins.v - int, f32, string, etc.
	value     // POD-ish struct embedded inline - Vec2, Color, Rect2
	resource  // ResHandle[T] - serialized as a path string, resolved via manager
	node      // INode subtype - serialized as a subtree with type tag + properties
}
