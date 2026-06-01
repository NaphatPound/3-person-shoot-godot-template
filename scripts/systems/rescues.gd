extends Node
## Rescues (autoload) — find & rescue survivors. Seeds a few SurvivorNodes into the World scene
## (scene_file_path gate). Reaching one ([E], handled by the existing Interaction system) rescues them
## for a gold reward — which also lifts the score via gold_earned. Tracks the rescued count. Touches no
## existing node.

signal changed
signal rescued_one(reward: int)

const WORLD_SCENE := "res://scenes/world.tscn"
const SPOTS := [Vector3(-6, 0, -4), Vector3(6, 0, 4), Vector3(-2, 0, 7)]

@export var reward := 150

var rescued := 0
var _seeded: Node = null


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded:
		return
	_seeded = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	for p in SPOTS:
		var sv := SurvivorNode.new()
		scene.add_child(sv)
		sv.position = p


func rescue(node: Node) -> void:
	rescued += 1
	Currency.add(reward)
	rescued_one.emit(reward)
	changed.emit()
	if is_instance_valid(node):
		node.queue_free()
