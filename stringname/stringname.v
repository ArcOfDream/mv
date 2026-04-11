module stringname

import sync

struct StringEntry {
mut:
	val   string
	count int
}

pub struct StringName {
pub:
	ptr &StringEntry
}

// free decrements the count
pub fn (sn &StringName) free() {
	mut e := sn.ptr
	e.count--
}

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

pub fn (mut s StringNameMap) new(val string) StringName {
	s.lock.rlock()

	if val in s.table {
		if mut entry := s.table[val] {
			entry.count++
			s.lock.runlock()
			return StringName{entry}
		}
	}

	s.lock.runlock()

	// doing a full lock if not found
	s.lock.lock()
	defer { s.lock.unlock() }

	// making sure to prevent race conditions
	if val in s.table {
		if mut entry := s.table[val] {
			entry.count++
			return StringName{entry}
		}
	}

	entry := &StringEntry{val, 1}
	s.table[val] = entry

	return StringName{entry}
}

pub fn (mut s StringNameMap) cleanup() {
	s.lock.lock()
	defer { s.lock.unlock() }

	for _, k in s.table {
		if k.count == 0 {
			s.table.delete(k.val)
		}
	}
}
