extends Node
## Weather (autoload) — cycles CLEAR/FOG/RAIN/STORM over time; `intensity` eases toward the active
## state's target. Drives the WeatherFX overlay and exposes gameplay hooks: state(), intensity(),
## fog_amount(), rain_amount(), visibility(). Pure data; touches no existing node. set_weather() forces a
## state (for triggers/testing); may tie to DayNight later.

signal weather_changed(state: int)
signal changed

enum State { CLEAR, FOG, RAIN, STORM }

@export var min_interval := 35.0
@export var max_interval := 70.0
@export var ease_speed := 0.4        ## intensity units/sec toward target

var state := State.CLEAR
var intensity := 0.0
var _target := 0.0
var _timer := 20.0


func _ready() -> void:
	_apply_target()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_pick_next()
	intensity = move_toward(intensity, _target, ease_speed * delta)
	changed.emit()


func _pick_next() -> void:
	_timer = randf_range(min_interval, max_interval)
	var choices := [State.CLEAR, State.CLEAR, State.FOG, State.RAIN, State.STORM]
	var next: int = choices[randi() % choices.size()]
	if next == state and next != State.CLEAR:
		next = State.CLEAR
	set_weather(next)


func set_weather(s: int) -> void:
	if s == state:
		return
	state = s
	_apply_target()
	weather_changed.emit(state)


func _apply_target() -> void:
	match state:
		State.CLEAR: _target = 0.0
		State.FOG: _target = 0.7
		State.RAIN: _target = 0.8
		State.STORM: _target = 1.0


func state_name() -> String:
	match state:
		State.CLEAR: return "CLEAR"
		State.FOG: return "FOG"
		State.RAIN: return "RAIN"
		State.STORM: return "STORM"
	return "?"


func fog_amount() -> float:
	if state == State.FOG:
		return intensity
	if state == State.STORM:
		return intensity * 0.5
	return 0.0


func rain_amount() -> float:
	if state == State.RAIN or state == State.STORM:
		return intensity
	return 0.0


func is_storm() -> bool:
	return state == State.STORM


## Gameplay hook: 1.0 = clear sight, lower in fog/storm.
func visibility() -> float:
	return clampf(1.0 - fog_amount() * 0.5 - rain_amount() * 0.2, 0.3, 1.0)
