extends Node
## ItemDB (autoload) — the single catalog of every item in the game, keyed by id.
## Every other system resolves item data through here, so adding/balancing items happens in one place.
## Must load BEFORE Inventory in the autoload order (Inventory queries it on _ready).

var _items: Dictionary = {}   # StringName -> Item


func _ready() -> void:
	_seed_defaults()


func register(item: Item) -> void:
	if item and item.id != &"":
		_items[item.id] = item


func has(id: StringName) -> bool:
	return _items.has(id)


func get_item(id: StringName) -> Item:
	return _items.get(id, null)


func all() -> Array:
	return _items.values()


## Starter catalog. Later systems (loot/merchant/quests) can register() more at runtime.
func _seed_defaults() -> void:
	var defs := [
		Item.make(&"handgun", "SLS 60 Handgun", Item.Category.WEAPON, 1, 1000, "A reliable sidearm. Your first line against the horde."),
		Item.make(&"ammo_9mm", "Handgun Ammo", Item.Category.AMMO, 99, 8, "9mm rounds. Never have enough."),
		Item.make(&"herb_green", "Green Herb", Item.Category.HEAL, 9, 120, "Restores health when consumed."),
		Item.make(&"ration", "Ration", Item.Category.FOOD, 9, 60, "Canned food. Quiets a growling stomach."),
		Item.make(&"scrap", "Scrap Metal", Item.Category.MATERIAL, 99, 15, "Salvage. Useful for upgrades and crafting."),
		Item.make(&"gem_blue", "Blue Gem", Item.Category.VALUABLE, 9, 500, "No use to you — but a merchant's eyes light up."),
	]
	for d in defs:
		register(d)
