extends Node
## Radio (autoload) — periodic flavor / hint broadcasts that react to game state (night, horde size,
## infection, noise). Atmospheric world-building + soft hints. Emits broadcast(text); RadioHUD shows it.
## Reads existing autoloads; touches no existing node. Passive / key-free.

signal broadcast(text: String)

@export var min_interval := 22.0
@export var max_interval := 42.0

var _timer := 12.0

const FLAVOR := [
	"...this is Echo-3, anyone still out there? Over.",
	"Reports of looters near the old market. Stay sharp.",
	"They say the merchant trades fair if you bring valuables.",
	"Keep your bag light and your aim lighter.",
	"Rumor: a safe room to the northwest. Unconfirmed.",
]


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(min_interval, max_interval)
		broadcast.emit(_pick())


func _pick() -> String:
	if DayNight.is_night():
		return "[NIGHT] Movement everywhere after dark — find a light, find a wall."
	if Horde.alive() >= 8:
		return "WARNING: a large group is converging on your position!"
	if Infection.level >= 60.0:
		return "Medical advisory: infection critical — find an antidote NOW."
	if NoiseMeter.is_loud():
		return "You're making a racket — they can hear you out there."
	return FLAVOR[randi() % FLAVOR.size()]


func say(text: String) -> void:
	broadcast.emit(text)
