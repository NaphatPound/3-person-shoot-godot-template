extends Node
## Hazards (autoload) — toxic gas zones (the dangerous mirror of SafeZones). While the player stands in a
## HazardNode (group "hazard"), health drains and infection rises via the public SurvivalStats /
## Infection APIs. Seeds a couple into the World scene (scene_file_path gate). Reads player position;
## touches no existing node. Passive.

signal inside_changed(inside: bool)

const WORLD_SCENE := "res://scenes/world.tscn"
const SPOTS := [Vector3(7, 0, -6), Vector3(-7, 0, 6)]

@export var damage := 6.0
@export var infect_rate := 8.0
@export var radius := 2.8

var inside := false
var _seeded: Node = null


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene != _seeded and scene.scene_file_path == WORLD_SCENE:
		_seeded = scene
		for p in SPOTS:
			var hz := HazardNode.new()
			scene.add_child(hz)
			hz.global_position = p

	var was := inside
	inside = _player_in_hazard()
	if inside:
		SurvivalStats.add_health(-damage * delta)
		if Infection.level < 100.0:
			Infection.level = minf(100.0, Infection.level + infect_rate * delta)
			Infection.changed.emit(Infection.level)
	if inside != was:
		inside_changed.emit(inside)


func _player_in_hazard() -> bool:
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	if p == null:
		return false
	for hz in get_tree().get_nodes_in_group(&"hazard"):
		if hz is Node3D and is_instance_valid(hz):
			if p.global_position.distance_to((hz as Node3D).global_position) <= radius:
				return true
	return false


func is_inside() -> bool:
	return inside
