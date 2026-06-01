extends Node
## Tension (autoload) — a 0..1 threat level derived from existing systems (noise, nearby zombies, night,
## infection), eased over time. Drives the TensionFX danger vignette and exposes level01()/is_high()
## hooks (e.g. a future audio layer). Reads other autoloads + group "dummy"; touches no existing node.

signal changed(level: float)

@export var ease_speed := 0.8
@export var danger_range := 12.0
@export var zombies_for_max := 6        ## this many nearby zombies = full proximity threat

var level := 0.0
var _player: Node3D = null


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	level = move_toward(level, _target(), ease_speed * delta)
	changed.emit(level)


func _target() -> float:
	var noise := NoiseMeter.level01()
	var prox := _zombie_proximity()
	var night := 1.0 if DayNight.is_night() else 0.0
	var infect := Infection.level / 100.0
	return clampf(0.35 * noise + 0.30 * prox + 0.15 * night + 0.20 * infect, 0.0, 1.0)


func _zombie_proximity() -> float:
	if _player == null or not is_instance_valid(_player):
		return 0.0
	var n := 0
	var r2 := danger_range * danger_range
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			if _player.global_position.distance_squared_to((z as Node3D).global_position) <= r2:
				n += 1
	return clampf(float(n) / float(zombies_for_max), 0.0, 1.0)


func level01() -> float:
	return level


func is_high() -> bool:
	return level >= 0.66
