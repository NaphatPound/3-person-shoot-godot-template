extends Node
## SavePoints (autoload) — RE-style typewriter save points. Seeds one into the World scene; interacting
## ([E], via the existing Interaction system) saves the game through SaveSystem's public API, which also
## triggers SaveExtra and the "GAME SAVED" toast. Tracks uses. Touches no existing node.

signal used

const WORLD_SCENE := "res://scenes/world.tscn"
const POS := Vector3(-4.0, 0.0, -2.0)

var uses := 0
var _seeded: Node = null


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded:
		return
	_seeded = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	var sp := SavePointNode.new()
	scene.add_child(sp)
	sp.position = POS


func save_here() -> bool:
	var okk := SaveSystem.save_game()
	if okk:
		uses += 1
		used.emit()
	return okk
