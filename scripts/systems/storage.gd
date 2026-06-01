extends Node
## Storage (autoload) — a safe-room stash, separate from the 12-slot Inventory: a larger box the player
## deposits loot into / withdraws from at a StoragePoint. Holds id->count with a cap on distinct stacks.
## Pure data + a `changed` signal; the StorageUI moves items across using Inventory's public API.

signal changed

@export var max_stacks := 40        ## distinct item kinds the box can hold

var _items: Dictionary = {}         # StringName -> int


func count_of(id: StringName) -> int:
	return _items.get(id, 0)


func kinds() -> int:
	return _items.size()


func entries() -> Array:
	var out := []
	for id in _items:
		out.append({ "id": id, "count": _items[id] })
	return out


## Store n of id. Returns the amount that did NOT fit (no slot for a new kind).
func store(id: StringName, n: int = 1) -> int:
	if n <= 0:
		return n
	if not _items.has(id):
		if _items.size() >= max_stacks:
			return n
		_items[id] = 0
	_items[id] += n
	changed.emit()
	return 0


## Take up to n of id. Returns how many were actually taken.
func take(id: StringName, n: int = 1) -> int:
	var have: int = _items.get(id, 0)
	var taken := mini(have, maxi(0, n))
	if taken <= 0:
		return 0
	_items[id] = have - taken
	if _items[id] <= 0:
		_items.erase(id)
	changed.emit()
	return taken
