extends Node
## Traps (autoload) — place single-use traps that kill zombies. [T] drops a trap in front of the player,
## consuming a Trap Kit from the Inventory. Registers the Trap Kit into ItemDB and makes it obtainable by
## APPENDING to the Merchant stock + a Crafting recipe (additive, public vars). Tracks total kills.
## Touches no existing node.

signal changed

var kills := 0


func _enter_tree() -> void:
	if not InputMap.has_action(&"place_trap"):
		InputMap.add_action(&"place_trap")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_T
		InputMap.action_add_event(&"place_trap", e)


func _ready() -> void:
	ItemDB.register(Item.make(&"trap", "Trap Kit", Item.Category.MATERIAL, 9, 90, "Deploy to kill a zombie that wanders onto it."))
	Merchant.stock.append({ "id": &"trap", "price": 120 })
	Crafting.recipes.append({
		"id": &"r_trap", "name": "Trap Kit",
		"inputs": { &"scrap": 3, &"gunpowder": 1 }, "out": &"trap", "count": 1,
	})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"place_trap"):
		place()


func held() -> int:
	return Inventory.count_of(&"trap")


func place() -> bool:
	var scene := get_tree().current_scene
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if scene == null or player == null or not Inventory.has(&"trap", 1):
		changed.emit()
		return false
	Inventory.remove(&"trap", 1)
	var t := TrapNode.new()
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() > 0.01:
		fwd = fwd.normalized()
	t.position = player.global_position + fwd * 1.0
	t.position.y = 0.05
	scene.add_child(t)
	changed.emit()
	return true


func register_kill() -> void:
	kills += 1
	changed.emit()
