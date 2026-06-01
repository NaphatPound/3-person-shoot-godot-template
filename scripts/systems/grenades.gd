extends Node
## Grenades (autoload) — throw a grenade with [N], consuming a Frag Grenade item (aimed along the camera
## forward). Registers the Grenade into ItemDB and makes it obtainable by APPENDING to the Merchant stock
## + a Crafting recipe (additive, public vars). Tracks blast kills. Touches no existing node.

signal changed

var kills := 0


func _enter_tree() -> void:
	if not InputMap.has_action(&"throw_grenade"):
		InputMap.add_action(&"throw_grenade")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_N
		InputMap.action_add_event(&"throw_grenade", e)


func _ready() -> void:
	ItemDB.register(Item.make(&"grenade", "Frag Grenade", Item.Category.MATERIAL, 9, 130, "Throw to blast a cluster of zombies."))
	Merchant.stock.append({ "id": &"grenade", "price": 160 })
	Crafting.recipes.append({
		"id": &"r_grenade", "name": "Frag Grenade",
		"inputs": { &"gunpowder": 2, &"scrap": 2 }, "out": &"grenade", "count": 1,
	})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"throw_grenade"):
		throw()


func held() -> int:
	return Inventory.count_of(&"grenade")


func throw() -> bool:
	var scene := get_tree().current_scene
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if scene == null or player == null or not Inventory.has(&"grenade", 1):
		changed.emit()
		return false
	Inventory.remove(&"grenade", 1)
	var g := GrenadeNode.new()
	scene.add_child(g)
	var dir := -player.global_transform.basis.z
	var cam := get_viewport().get_camera_3d()
	if cam:
		dir = -cam.global_transform.basis.z
	g.throw_from(player.global_position + Vector3.UP * 1.4, dir)
	changed.emit()
	return true


func register_kills(n: int) -> void:
	if n > 0:
		kills += n
		changed.emit()
