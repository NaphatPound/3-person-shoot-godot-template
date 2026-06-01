extends Node
## Stamina (autoload) — sprint energy (0..100). Holding [Shift] WHILE moving sprints: stamina drains and
## hunger burns a little faster (via the public SurvivalStats API). Releasing regenerates it after a
## short delay; hitting 0 causes exhaustion (no sprint until it recovers past recover_at). It can't
## change the player's speed without editing player.gd, so it exposes speed_scale()/is_sprinting() as a
## one-line integration hook (multiply into move_speed) — matching the template's documented extension
## points. Reads input only; touches no existing node.

signal changed(stamina: float)
signal sprint_changed(sprinting: bool)

@export var max_stamina := 100.0
@export var drain_rate := 28.0        ## stamina/sec while sprinting
@export var regen_rate := 18.0        ## stamina/sec while not sprinting
@export var regen_delay := 0.6        ## seconds after sprinting before regen kicks in
@export var recover_at := 30.0        ## exhausted -> can sprint again once stamina passes this
@export var sprint_speed_scale := 1.6 ## movement multiplier hook for the player
@export var sprint_hunger_rate := 1.2 ## extra hunger/sec while sprinting

const MOVE_ACTIONS := [&"move_forward", &"move_back", &"move_left", &"move_right"]

var stamina := 100.0
var _sprinting := false
var _exhausted := false
var _regen_cd := 0.0


func _enter_tree() -> void:
	if not InputMap.has_action(&"sprint"):
		InputMap.add_action(&"sprint")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_SHIFT
		InputMap.action_add_event(&"sprint", e)


func _process(delta: float) -> void:
	var want := _wants_sprint()
	_set_sprinting(want)
	if want:
		stamina = maxf(0.0, stamina - drain_rate * delta)
		SurvivalStats.add_hunger(-sprint_hunger_rate * delta)
		_regen_cd = regen_delay
		if stamina <= 0.0:
			_exhausted = true
	else:
		_regen_cd = maxf(0.0, _regen_cd - delta)
		if _regen_cd <= 0.0 and stamina < max_stamina:
			stamina = minf(max_stamina, stamina + regen_rate * delta)
		if _exhausted and stamina >= recover_at:
			_exhausted = false
	changed.emit(stamina)


func _wants_sprint() -> bool:
	if _exhausted or stamina <= 0.0:
		return false
	if not (InputMap.has_action(&"sprint") and Input.is_action_pressed(&"sprint")):
		return false
	return _is_moving()


func _is_moving() -> bool:
	for a in MOVE_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


func _set_sprinting(v: bool) -> void:
	if v != _sprinting:
		_sprinting = v
		sprint_changed.emit(v)


func is_sprinting() -> bool:
	return _sprinting


func is_exhausted() -> bool:
	return _exhausted


## Integration hook: multiply into the player's move speed (1.0 normal, sprint_speed_scale sprinting).
func speed_scale() -> float:
	return sprint_speed_scale if _sprinting else 1.0
