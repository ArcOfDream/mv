module core

import sync

// StringEntry stores an interned string owned by the StringNameMap.
// Entries persist for the lifetime of the map -- there is no per-StringName
// refcounting because the map is the sole owner. This avoids the complexity
// of reference-counted value types in V (which doesn't support custom
// destructors for structs with raw pointer fields).
struct StringEntry {
	val string
}

// StringName is a lightweight handle to an interned string stored in a
// StringNameMap. It is safe to copy by value -- all copies point to the
// same StringEntry, which lives as long as the owning map.
//
// StringName is primarily used by InputMap for action name lookups,
// where O(1) pointer comparison replaces string hashing.
pub struct StringName {
pub:
	ptr &StringEntry
}

@[heap]
pub struct StringNameMap {
mut:
	table map[string]&StringEntry
	lock  sync.RwMutex
}

pub fn (a StringName) == (b StringName) bool {
	return a.ptr == b.ptr
}

pub fn (sn StringName) str() string {
	return sn.ptr.val
}

// new returns a StringName for the given string, interning it if needed.
// The returned handle is valid for the lifetime of the map.
pub fn (mut s StringNameMap) new(val string) StringName {
	s.lock.rlock()

	if entry := s.table[val] {
		s.lock.runlock()
		return StringName{entry}
	}

	s.lock.runlock()

	// full lock for insertion
	s.lock.lock()
	defer { s.lock.unlock() }

	// double-check after lock acquisition
	if entry := s.table[val] {
		return StringName{entry}
	}

	entry := &StringEntry{val}
	s.table[val] = entry

	return StringName{entry}
}
