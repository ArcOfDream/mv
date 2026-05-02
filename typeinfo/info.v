module typeinfo

pub type WriteJsonFn = fn (src voidptr, mut enc JsonEncoder) !

pub type ReadJsonFn = fn (mut dec JsonDecoder, dst voidptr) !

pub type WriteBinFn = fn (src voidptr, mut enc BinEncoder) !

pub type ReadBinFn = fn (mut dec BinDecoder, dst voidptr) !

pub type ConstructFn = fn (name string) voidptr

pub struct TypeInfo {
pub mut:
	name string
	size int
	kind TypeKind

	write_json ?WriteJsonFn
	read_json  ?ReadJsonFn
	write_bin  ?WriteBinFn
	read_bin   ?ReadBinFn

	construct ?ConstructFn
}
