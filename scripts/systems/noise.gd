extends Node
## Noise (autoload) — how much attention the player is drawing. Firing adds a burst; sprinting/walking
## add over time; it decays when quiet. Exposes level01()/is_loud()/aggro() as hooks (a future Horde
## tweak could spawn toward a loud player). Reads movement input + the Stamina autoload + the player's
## fired signal; modifies nothing.

signal changed(level: float)

@export var fire_noise := 22.0
@export var sprint_noise := 18.0     ## per second
@export var walk_noise := 6.0        ## per second
@export var decay := 14.0            ## per second
@export var loud_threshold := 60.0

const MOVE_ACTIONS := [&"move_forward", &"move_back", &"move_left", &"move_right"]

var level := 0.0
var _player: Node = null


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var p := get_tree().get_first_node_in_group(&"player")
		if p and p.has_signal("fired") and not p.fired.is_connected(_on_fired):
			p.fired.connect(_on_fired)
			_player = p

	var add := 0.0
	if _is_sprinting():
		add = sprint_noise
	elif _is_moving():
		add = walk_noise
	level = clampf(level + (add - decay) * delta, 0.0, 100.0)
	changed.emit(level)


func _on_fired() -> void:
	level = clampf(level + fire_noise, 0.0, 100.0)
	changed.emit(level)


func _is_sprinting() -> bool:
	return Stamina.is_sprinting()


func _is_moving() -> bool:
	for a in MOVE_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


func level01() -> float:
	return level / 100.0


func is_loud() -> bool:
	return level >= loud_threshold


## Hook: approximate aggro radius (metres) scaling with current noise.
func aggro() -> float:
	return 4.0 + level01() * 14.0
