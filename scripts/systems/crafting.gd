extends Node
## Crafting (autoload) — combine materials/items from the Inventory into ammo, heals and intermediates
## via fixed recipes. Registers a couple of new craftable items into the EXISTING ItemDB (via its public
## register(), so no file is modified). Transactional: if the output can't fit the bag it refunds the
## inputs. CraftingUI drives it.

signal changed
signal crafted(out_id: StringName)

var recipes: Array = []


func _ready() -> void:
	# New craftable items added to the existing catalog (additive).
	ItemDB.register(Item.make(&"gunpowder", "Gunpowder", Item.Category.MATERIAL, 99, 20, "Refined from salvage — the basis of fresh ammo."))
	ItemDB.register(Item.make(&"herb_mix", "Mixed Herb", Item.Category.HEAL, 9, 260, "Two herbs combined; heals far more."))

	recipes = [
		{ "id": &"r_powder", "name": "Gunpowder",        "inputs": { &"scrap": 2 },                 "out": &"gunpowder",  "count": 1 },
		{ "id": &"r_ammo",   "name": "Handgun Ammo",     "inputs": { &"gunpowder": 1, &"scrap": 1 }, "out": &"ammo_9mm",   "count": 10 },
		{ "id": &"r_aid",    "name": "First Aid (Green Herb)", "inputs": { &"scrap": 3 },            "out": &"herb_green", "count": 1 },
		{ "id": &"r_mix",    "name": "Mixed Herb",        "inputs": { &"herb_green": 2 },             "out": &"herb_mix",   "count": 1 },
	]


func get_recipes() -> Array:
	return recipes


func recipe(id: StringName) -> Dictionary:
	for r in recipes:
		if r["id"] == id:
			return r
	return {}


func can_craft(r: Dictionary) -> bool:
	if r.is_empty():
		return false
	for id in r["inputs"]:
		if Inventory.count_of(id) < int(r["inputs"][id]):
			return false
	return true


func craft(r: Dictionary) -> bool:
	if not can_craft(r):
		return false
	for id in r["inputs"]:
		Inventory.remove(id, int(r["inputs"][id]))
	var leftover := Inventory.add(r["out"], int(r["count"]))
	if leftover > 0:
		# bag had no room for the result — undo cleanly
		Inventory.remove(r["out"], int(r["count"]) - leftover)
		for id in r["inputs"]:
			Inventory.add(id, int(r["inputs"][id]))
		return false
	crafted.emit(r["out"])
	changed.emit()
	return true
