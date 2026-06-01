extends Node
## Crates (autoload) — locked loot crates. Registers a Lockpick item (buyable/craftable), grants a
## starter Lockpick, and seeds a couple of LootCrateNodes into the World scene (scene_file_path gate).
## Opening a crate ([E], handled by the existing Interaction system) consumes a Lockpick. Tracks opens.
## Touches no existing node.

signal changed
signal locked_attempt

const WORLD_SCENE := "res://scenes/world.tscn"

const CRATES := [
	{ "pos": Vector3(3.0, 0.3, -1.0), "loot": [ { "id": &"gem_blue", "amount": 1 }, { "id": &"ammo_9mm", "amount": 12 } ] },
	{ "pos": Vector3(-3.0, 0.3, 2.5), "loot": [ { "id": &"herb_green", "amount": 2 }, { "id": &"scrap", "amount": 4 } ] },
]

var opened := 0
var _seeded: Node = null


func _ready() -> void:
	ItemDB.register(Item.make(&"lockpick", "Lockpick", Item.Category.MATERIAL, 9, 60, "Opens a locked crate. Consumed on use."))
	Merchant.stock.append({ "id": &"lockpick", "price": 80 })
	Crafting.recipes.append({
		"id": &"r_lockpick", "name": "Lockpick",
		"inputs": { &"scrap": 2 }, "out": &"lockpick", "count": 1,
	})
	Inventory.add(&"lockpick", 1)   # a starter pick so a crate can be opened right away


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded:
		return
	_seeded = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	for c in CRATES:
		var crate := LootCrateNode.new()
		crate.loot = c["loot"]
		scene.add_child(crate)
		crate.position = c["pos"]


func report_opened() -> void:
	opened += 1
	changed.emit()


func report_locked() -> void:
	locked_attempt.emit()


func lockpicks() -> int:
	return Inventory.count_of(&"lockpick")
