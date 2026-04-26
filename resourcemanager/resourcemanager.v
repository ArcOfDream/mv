module resourcemanager

import sync.stdatomic { AtomicVal, new_atomic }

interface IResource {
	unload()
}

// -----------------------------------------------------------------------------
// Slot
// -----------------------------------------------------------------------------

struct Slot[T] {
mut:
	resource   T
	generation int
	is_active  bool
	refcount   &AtomicVal[u32] = unsafe { nil }
}

// Handle carries a back-pointer to the manager so clone/release/get can be
// methods on the handle itself, without the caller needing to thread the
// manager through every call site.
//
// zero-value handle (manager == nil, id == -1) is treated as "invalid" by
// all operations - clone/release/get become no-ops. this lets fields be
// default-initialized without a special sentinel.
pub struct Handle[T] {
mut:
	manager &ResourceManager[T] = unsafe { nil }
pub:
	id         int = -1
	generation int
}

pub fn (h Handle[T]) is_valid() bool {
	if h.manager == unsafe { nil } || h.id < 0 {
		return false
	}
	if h.id >= h.manager.slots.len {
		return false
	}
	slot := h.manager.slots[h.id]
	return slot.is_active && slot.generation == h.generation
}

pub fn (h Handle[T]) get() ?&T {
	if !h.is_valid() {
		return none
	}
	return &h.manager.slots[h.id].resource
}

// clone bumps the refcount and returns a new handle with the same identity.
// the returned handle is the caller's ownership; they must release it.
//
// silently returns the same (invalid) handle if called on an invalid one;
// this makes "clone a possibly-empty field" safe without manual checks.
pub fn (h Handle[T]) clone() Handle[T] {
	if !h.is_valid() {
		return h
	}
	mut slot := &h.manager.slots[h.id]
	slot.refcount.add(1)
	return h
}

// release decrements the refcount. when it hits zero, the slot's resource
// is unloaded and the slot is freed for reuse.
//
// invalid handles (zero, already-released, stale generation) are no-ops.
pub fn (mut h Handle[T]) release() {
	if !h.is_valid() {
		return
	}
	mut slot := &h.manager.slots[h.id]
	prev := slot.refcount.sub(1)
	if prev == 1 {
		h.manager.free_slot(h.id)
	}
}

@[heap]
pub struct ResourceManager[T] {
mut:
	slots        []Slot[T]
	free_indices []int
	names        map[string]int
}

fn (mut rm ResourceManager[T]) add(name string, res T) Handle[T] {
	mut idx := 0

	if rm.free_indices.len > 0 {
		idx = rm.free_indices.pop()
		rm.slots[idx].resource = res
		rm.slots[idx].is_active = true
		rm.slots[idx].generation++
		rm.slots[idx].refcount.store(1) // reuse existing atomic
	} else {
		idx = rm.slots.len
		rm.slots << Slot[T]{
			resource:   res
			generation: 0
			is_active:  true
			refcount:   new_atomic[u32](1) // allocate once per physical slot
		}
	}

	rm.names[name] = idx
	return Handle[T]{
		manager:    rm
		id:         idx
		generation: rm.slots[idx].generation
	}
}

// acquire_or_insert is the one internal entry point that all public load_*
// methods funnel through. on hit: bumps refcount, returns existing handle.
// on miss: calls `make` to produce the resource, inserts it, returns a
// fresh handle with refcount=1.
//
// `make` returns ?T so load failures propagate as none without the caller
// having to care about intermediate state.
fn (mut rm ResourceManager[T]) acquire_or_insert(name string, make fn () ?T) ?Handle[T] {
	if idx := rm.names[name] {
		mut slot := &rm.slots[idx]
		if slot.is_active {
			slot.refcount.add(1) // was: add_u32(&slot.refcount, 1)
			return Handle[T]{
				manager:    rm
				id:         idx
				generation: slot.generation
			}
		}
	}

	res := make() or { return none }
	return rm.add(name, res)
}

// free_slot is called from Handle.release() when refcount hits zero.
// also the single place where slot teardown happens - unload(name) routes
// through this too after the manual-eviction semantics are sorted out.
fn (mut rm ResourceManager[T]) free_slot(id int) {
	mut slot := &rm.slots[id]
	if !slot.is_active {
		return
	}
	slot.resource.unload()
	slot.is_active = false
	slot.generation++
	slot.refcount.store(0)
	rm.free_indices << id

	for name, stored_id in rm.names {
		if stored_id == id {
			rm.names.delete(name)
			break
		}
	}
}

pub fn (mut rm ResourceManager[T]) get_handle(name string) ?Handle[T] {
	idx := rm.names[name] or { return none }
	mut slot := &rm.slots[idx]
	if !slot.is_active {
		return none
	}
	slot.refcount.add(1)
	return Handle[T]{
		manager:    rm
		id:         idx
		generation: slot.generation
	}
}

// peek_handle is the non-bumping lookup - returns a handle that the caller
// must NOT release. used by debug tools, inspectors, and serialization
// write-paths (where we just need to stringify the resource's name, not
// take ownership).
pub fn (rm &ResourceManager[T]) peek_handle(name string) ?Handle[T] {
	idx := rm.names[name] or { return none }
	slot := rm.slots[idx]
	if !slot.is_active {
		return none
	}
	return Handle[T]{
		manager:    unsafe { rm }
		id:         idx
		generation: slot.generation
	}
}

// unload is kept for explicit "nuke this regardless of refs" semantics.
// clears refcount and drops the slot. any outstanding handles become
// invalid via the generation bump. this is an escape hatch - normal
// lifetime should use release.
pub fn (mut rm ResourceManager[T]) unload(name string) {
	idx := rm.names[name] or { return }
	rm.free_slot(idx)
}

pub fn (mut rm ResourceManager[T]) clear() {
	for i in 0 .. rm.slots.len {
		if rm.slots[i].is_active {
			rm.slots[i].resource.unload()
			rm.slots[i].is_active = false
			rm.slots[i].generation++
			rm.slots[i].refcount.store(0)
		}
	}
	rm.slots.clear()
	rm.names.clear()
	rm.free_indices.clear()
}

// name_of is a reverse lookup used by serialization write-paths.
// O(n) over names; adequate for scene save where it's called once per
// exported resource reference.
// TODO: add a slot->name cache if this becomes hot.
pub fn (rm &ResourceManager[T]) name_of(id int) ?string {
	for name, stored_id in rm.names {
		if stored_id == id {
			return name
		}
	}
	return none
}
