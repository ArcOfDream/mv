module resourcemanager

interface IResource {
	unload()
}

pub struct Handle[T] {
pub:
	id         int
	generation int
}

struct Slot[T] {
mut:
	resource   T
	generation int
	is_active  bool
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
	} else {
		idx = rm.slots.len
		rm.slots << Slot[T]{
			resource:   res
			generation: 0
			is_active:  true
		}
	}

	rm.names[name] = idx
	return Handle[T]{idx, rm.slots[idx].generation}
}

pub fn (rm &ResourceManager[T]) get(handle Handle[T]) ?T {
	if handle.id >= 0 && handle.id < rm.slots.len {
		slot := rm.slots[handle.id]
		if slot.is_active && slot.generation == handle.generation {
			return slot.resource
		}
	}

	return none
}

pub fn (rm ResourceManager[T]) get_handle(name string) ?Handle[T] {
	if idx := rm.names[name] {
		return Handle[T]{
			id:         idx
			generation: rm.slots[idx].generation
		}
	}

	return none
}

pub fn (mut rm ResourceManager[T]) unload(name string) {
	idx := rm.names[name] or { return }

	mut slot := &rm.slots[idx]
	if slot.is_active {
		slot.resource.unload()
		slot.is_active = false
		slot.generation++
		rm.free_indices << idx
		rm.names.delete(name)
	}
}

pub fn (mut rm ResourceManager[T]) clear() {
	for mut slot in rm.slots {
		if slot.is_active {
			slot.resource.unload()
			slot.is_active = false
			slot.generation++
		}
	}
	
	rm.slots.clear()
	rm.names.clear()
	rm.free_indices.clear()
}
