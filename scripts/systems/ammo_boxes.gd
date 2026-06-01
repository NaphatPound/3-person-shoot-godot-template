extends Node
## AmmoBoxes (autoload) — dedicated ammo resupply crates. Seeds a couple of AmmoBoxNodes into the World
## scene (scene_file_path gate). Grabbing one ([E], via Interaction) dumps a chunk of handgun ammo into
## the Inventory. Tracks how many were collected. Touches no existing node.

signal collected_box(amount: int)

const WORLD_SCENE := "res://scenes/world.tscn"
const SPOTS := [Vector3(6, 0, -2), Vector3(-6, 0, 3)]

@export var amount := 30

var collected := 0
var _seeded: Node = null


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded:
		return
	_seeded = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	for p in SPOTS:
		var b := AmmoBoxNode.new()
		scene.add_child(b)
		b.position = p


func collect(node) -> void:
	Inventory.add(&"ammo_9mm", amount)
	collected += 1
	collected_box.emit(amount)
	if is_instance_valid(node):
		node.queue_free()
