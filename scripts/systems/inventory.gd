extends Node
## Inventory (autoload) — the player's slot-based bag, RE-style: a fixed number of slots, items stack
## up to their max_stack. Pure data + signals; UI and gameplay listen rather than reach inside.
## Currency/trading deliberately lives in the (separate) merchant system, not here, to avoid overlap.
##
## API: add(id, n) -> leftover · remove(id, n) -> bool · has(id, n) · count_of(id) · get_slots()
## Each slot is either null or a Dictionary { "id": StringName, "count": int }.

signal changed                                   ## any mutation — repaint the UI
signal item_added(id: StringName, count: int)
signal item_removed(id: StringName, count: int)
signal full(id: StringName, overflow: int)       ## couldn't fit `overflow` of `id`

@export var capacity: int = 12                   ## number of slots (the "case" size)

var _slots: Array = []
var _granted := false


func _ready() -> void:
	_slots.resize(capacity)
	_grant_starter_loadout()


func _grant_starter_loadout() -> void:
	if _granted:
		return
	_granted = true
	add(&"handgun", 1)
	add(&"ammo_9mm", 30)
	add(&"herb_green", 2)
	add(&"ration", 1)


## Add `count` of `id`. Returns how many did NOT fit (0 = everything fit).
func add(id: StringName, count: int = 1) -> int:
	if count <= 0 or not ItemDB.has(id):
		return count
	var item: Item = ItemDB.get_item(id)
	var remaining := count
	# 1) top up existing stacks first
	if item.is_stackable():
		for i in _slots.size():
			var s = _slots[i]
			if s != null and s["id"] == id and s["count"] < item.max_stack:
				var moved := mini(item.max_stack - s["count"], remaining)
				s["count"] += moved
				remaining -= moved
				if remaining <= 0:
					break
	# 2) spill into empty slots
	while remaining > 0:
		var idx := _first_empty()
		if idx == -1:
			break
		var put := mini(item.max_stack, remaining)
		_slots[idx] = { "id": id, "count": put }
		remaining -= put
	var added := count - remaining
	if added > 0:
		item_added.emit(id, added)
		changed.emit()
	if remaining > 0:
		full.emit(id, remaining)
	return remaining


## Remove `count` of `id`. Returns true only if the full amount was removed.
func remove(id: StringName, count: int = 1) -> bool:
	if count <= 0:
		return true
	if count_of(id) < count:
		return false
	var remaining := count
	for i in _slots.size():
		var s = _slots[i]
		if s != null and s["id"] == id:
			var taken := mini(s["count"], remaining)
			s["count"] -= taken
			remaining -= taken
			if s["count"] <= 0:
				_slots[i] = null
			if remaining <= 0:
				break
	item_removed.emit(id, count)
	changed.emit()
	return true


func count_of(id: StringName) -> int:
	var n := 0
	for s in _slots:
		if s != null and s["id"] == id:
			n += s["count"]
	return n


func has(id: StringName, count: int = 1) -> bool:
	return count_of(id) >= count


func used_slots() -> int:
	var n := 0
	for s in _slots:
		if s != null:
			n += 1
	return n


func get_slots() -> Array:
	return _slots


func _first_empty() -> int:
	for i in _slots.size():
		if _slots[i] == null:
			return i
	return -1
