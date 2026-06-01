extends Node
## Interaction (autoload) — distance-based "press [E] to grab" world-loot system. Each frame it finds
## the nearest WorldPickup (group "pickup") to the player (group "player") within `reach` and asks
## InteractPrompt to show a prompt; [E] grabs it into the Inventory. It also seeds a handful of demo
## pickups into the World scene the first time it runs there (gated by scene_file_path) so the system
## is visible without editing world.tscn. Pure addition — registers its own [E] action, touches no
## existing node. Pauses with the tree (so it idles while the bag is open).

@export var reach := 2.8

var _target: WorldPickup = null
var _seeded_scene: Node = null

const WORLD_SCENE := "res://scenes/world.tscn"
const DEMO_LOOT := [
	{ "id": &"ammo_9mm", "amount": 12, "pos": Vector3(1.8, 0.5, -1.4) },
	{ "id": &"herb_green", "amount": 1, "pos": Vector3(-1.8, 0.5, -1.4) },
	{ "id": &"scrap", "amount": 3, "pos": Vector3(2.4, 0.5, 1.6) },
	{ "id": &"gem_blue", "amount": 1, "pos": Vector3(-2.4, 0.5, 1.6) },
	{ "id": &"ration", "amount": 1, "pos": Vector3(0.0, 0.5, 2.2) },
]


func _enter_tree() -> void:
	if not InputMap.has_action(&"interact"):
		InputMap.add_action(&"interact")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_E
		InputMap.action_add_event(&"interact", e)


func _process(_delta: float) -> void:
	_maybe_seed_demo()
	_update_target()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and is_instance_valid(_target):
		_target.interact()
		_set_target(null)


func current_target() -> WorldPickup:
	return _target


func _update_target() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		_set_target(null)
		return
	var nearest: WorldPickup = null
	var best := reach * reach
	for p in get_tree().get_nodes_in_group(&"pickup"):
		if p is WorldPickup and is_instance_valid(p):
			var d := player.global_position.distance_squared_to((p as Node3D).global_position)
			if d <= best:
				best = d
				nearest = p
	_set_target(nearest)


func _set_target(t: WorldPickup) -> void:
	if t == _target:
		return
	_target = t
	if t != null:
		InteractPrompt.show_prompt("[E]  Pick up  " + t.get_label())
	else:
		InteractPrompt.hide_prompt()


func _maybe_seed_demo() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded_scene:
		return
	_seeded_scene = scene
	if scene.scene_file_path != WORLD_SCENE:
		return   # only seed the demo level, never the test/inspect scenes
	for entry in DEMO_LOOT:
		var pk := WorldPickup.new()
		pk.item_id = entry["id"]
		pk.amount = entry["amount"]
		pk.position = entry["pos"]
		scene.add_child(pk)
