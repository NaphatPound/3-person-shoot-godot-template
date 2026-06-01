extends Node
## DayNight (autoload) — a looping time-of-day clock. `t` runs 0..1 over `day_length` real seconds and
## wraps, counting up `day`. Emits time_changed / phase_changed (DAY/DUSK/NIGHT/DAWN). Drives the night
## tint (WorldClockHUD) and the horde intensity (Horde). Pure data; touches no existing node.

signal time_changed(t: float)
signal phase_changed(phase: int)

enum Phase { DAY, DUSK, NIGHT, DAWN }

@export var day_length := 120.0     ## real seconds for one full day-night cycle
@export var start_t := 0.25         ## begin at morning

var t := 0.25
var day := 1
var _phase := Phase.DAY


func _ready() -> void:
	t = start_t
	_phase = _phase_for(t)


func _process(delta: float) -> void:
	if day_length <= 0.0:
		return
	t += delta / day_length
	while t >= 1.0:
		t -= 1.0
		day += 1
	time_changed.emit(t)
	var p := _phase_for(t)
	if p != _phase:
		_phase = p
		phase_changed.emit(p)


func _phase_for(time: float) -> int:
	if time < 0.2 or time >= 0.85:
		return Phase.NIGHT
	elif time < 0.3:
		return Phase.DAWN
	elif time < 0.75:
		return Phase.DAY
	else:
		return Phase.DUSK


func phase() -> int:
	return _phase


func phase_name() -> String:
	match _phase:
		Phase.DAY: return "DAY"
		Phase.DUSK: return "DUSK"
		Phase.NIGHT: return "NIGHT"
		Phase.DAWN: return "DAWN"
	return "?"


func is_night() -> bool:
	return _phase == Phase.NIGHT


## 0 at bright noon -> 1 at deep midnight; used for the screen tint.
func darkness() -> float:
	var d := absf(t - 0.5) * 2.0
	return clampf(smoothstep(0.35, 0.95, d), 0.0, 1.0)


func clock_text() -> String:
	var minutes := int(round(t * 24.0 * 60.0))
	var hh := (minutes / 60) % 24
	var mm := minutes % 60
	return "Day %d   %02d:%02d" % [day, hh, mm]
