extends Node
## Barricades (autoload) — place barriers ([Z]) and repair the nearest one ([X], costs 1 scrap).
## Registers a Barricade Kit item and makes it obtainable by APPENDING to the Merchant stock + a Crafting
## recipe (additive, public vars). Tracks how many broke. Touches no existing node.

signal changed

@export var repair_reach := 3.0
@export var repair_amount := 40.0

var broken := 0


func _enter_tree() -> void:
	_ensure(&"place_barricade", KEY_Z)
	_ensure(&"repair_barricade", KEY_X)


func _ready() -> void:
	ItemDB.register(Item.make(&"barricade", "Barricade Kit", Item.Category.MATERIAL, 9, 110, "Deploy a barrier that blocks and absorbs zombie attacks."))
	Merchant.stock.append({ "id": &"barricade", "price": 140 })
	Crafting.recipes.append({
		"id": &"r_barricade", "name": "Barricade Kit",
		"inputs": { &"scrap": 4 }, "out": &"barricade", "count": 1,
	})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"place_barricade"):
		place()
	elif event.is_action_pressed(&"repair_barricade"):
		repair_nearest()


func place() -> bool:
	var scene := get_tree().current_scene
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if scene == null or player == null or not Inventory.has(&"barricade", 1):
		changed.emit()
		return false
	Inventory.remove(&"barricade", 1)
	var b := BarricadeNode.new()
	scene.add_child(b)
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() > 0.01:
		fwd = fwd.normalized()
	b.global_position = player.global_position + fwd * 1.6
	b.global_position.y = 0.0
	b.rotation.y = atan2(fwd.x, fwd.z)
	changed.emit()
	return true


func repair_nearest() -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null or not Inventory.has(&"scrap", 1):
		return false
	var best: BarricadeNode = null
	var bd := repair_reach * repair_reach
	for b in get_tree().get_nodes_in_group(&"barricade"):
		if b is BarricadeNode and is_instance_valid(b):
			var d := player.global_position.distance_squared_to((b as Node3D).global_position)
			if d <= bd:
				bd = d
				best = b
	if best == null:
		return false
	Inventory.remove(&"scrap", 1)
	best.repair(repair_amount)
	changed.emit()
	return true


func standing() -> int:
	return get_tree().get_nodes_in_group(&"barricade").size()


func held() -> int:
	return Inventory.count_of(&"barricade")


func notify_broken() -> void:
	broken += 1
	changed.emit()


func _ensure(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var e := InputEventKey.new()
		e.physical_keycode = code
		InputMap.action_add_event(action, e)
