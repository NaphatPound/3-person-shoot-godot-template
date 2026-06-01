extends Node
## SafeZones (autoload) — RE-style safe rooms. While the player stands in a SafeZoneNode (group
## "safezone"), health regenerates and infection cleanses via the public SurvivalStats / Infection APIs.
## Seeds one zone into the World scene (scene_file_path gate). Reads player position; touches no existing
## node. Passive / key-free.

signal inside_changed(inside: bool)

const WORLD_SCENE := "res://scenes/world.tscn"
const ZONE_POS := Vector3(-6.0, 0.0, -6.0)

@export var heal_rate := 12.0
@export var cleanse_rate := 18.0
@export var radius := 3.0

var inside := false
var _seeded: Node = null


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene != _seeded and scene.scene_file_path == WORLD_SCENE:
		_seeded = scene
		var z := SafeZoneNode.new()
		scene.add_child(z)
		z.global_position = ZONE_POS

	var was := inside
	inside = _player_in_zone()
	if inside:
		SurvivalStats.add_health(heal_rate * delta)
		if Infection.level > 0.0:
			Infection.level = maxf(0.0, Infection.level - cleanse_rate * delta)
			Infection.changed.emit(Infection.level)
	if inside != was:
		inside_changed.emit(inside)


func _player_in_zone() -> bool:
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	if p == null:
		return false
	for z in get_tree().get_nodes_in_group(&"safezone"):
		if z is Node3D and is_instance_valid(z):
			if p.global_position.distance_to((z as Node3D).global_position) <= radius:
				return true
	return false


func is_inside() -> bool:
	return inside
