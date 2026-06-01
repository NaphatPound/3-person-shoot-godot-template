extends Node
## Molotovs (autoload) — throw a molotov with [Q] (consuming a Molotov item, aimed along the camera) to
## create a lingering fire zone. Registers the Molotov into ItemDB and makes it obtainable by APPENDING
## to the Merchant stock + a Crafting recipe (additive, public vars). Tracks burn kills. Touches nothing.

signal changed

var kills := 0


func _enter_tree() -> void:
	if not InputMap.has_action(&"throw_molotov"):
		InputMap.add_action(&"throw_molotov")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_Q
		InputMap.action_add_event(&"throw_molotov", e)


func _ready() -> void:
	ItemDB.register(Item.make(&"molotov", "Molotov", Item.Category.MATERIAL, 9, 110, "Throw to set a lingering fire that burns zombies."))
	Merchant.stock.append({ "id": &"molotov", "price": 140 })
	Crafting.recipes.append({
		"id": &"r_molotov", "name": "Molotov",
		"inputs": { &"gunpowder": 1, &"scrap": 1 }, "out": &"molotov", "count": 1,
	})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"throw_molotov"):
		throw()


func held() -> int:
	return Inventory.count_of(&"molotov")


func throw() -> bool:
	var scene := get_tree().current_scene
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if scene == null or player == null or not Inventory.has(&"molotov", 1):
		changed.emit()
		return false
	Inventory.remove(&"molotov", 1)
	var m := MolotovNode.new()
	scene.add_child(m)
	var dir := -player.global_transform.basis.z
	var cam := get_viewport().get_camera_3d()
	if cam:
		dir = -cam.global_transform.basis.z
	m.throw_from(player.global_position + Vector3.UP * 1.4, dir)
	changed.emit()
	return true


func register_kill() -> void:
	kills += 1
	changed.emit()
