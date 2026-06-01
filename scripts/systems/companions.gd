extends Node
## Companions (autoload) — manages the ally. Auto-spawns one CompanionNode into the World scene (skipped
## during the --demo screenshot run so it stays clean); [K] dismisses / re-summons it at the player.
## Tracks assist kills. Touches no existing node.

signal changed

const WORLD_SCENE := "res://scenes/world.tscn"

var assists := 0
var _companion: CompanionNode = null
var _seeded: Node = null
var _dismissed := false


func _enter_tree() -> void:
	if not InputMap.has_action(&"companion"):
		InputMap.add_action(&"companion")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_K
		InputMap.action_add_event(&"companion", e)


func _process(_delta: float) -> void:
	if "--demo" in OS.get_cmdline_user_args():
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		return
	if scene != _seeded:
		_seeded = scene
		_dismissed = false
		_spawn(scene)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"companion"):
		toggle()


func is_active() -> bool:
	return is_instance_valid(_companion)


func toggle() -> void:
	if is_active():
		_companion.queue_free()
		_companion = null
		_dismissed = true
	else:
		var scene := get_tree().current_scene
		if scene and scene.scene_file_path == WORLD_SCENE:
			_dismissed = false
			_spawn(scene)
	changed.emit()


func _spawn(scene: Node) -> void:
	if is_instance_valid(_companion) or _dismissed:
		return
	var c := CompanionNode.new()
	scene.add_child(c)
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player:
		c.global_position = player.global_position + Vector3(1.5, 0, 1.5)
	else:
		c.position = Vector3(1.5, 0, 1.5)
	_companion = c
	changed.emit()


func register_assist() -> void:
	assists += 1
	changed.emit()
