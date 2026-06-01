extends Node
## Difficulty (autoload) — ramps the game up as days pass. Polls DayNight.day; when a new day starts it
## scales a few SAFE, exported tuning knobs on existing autoloads (Horde wave cap + wave intervals,
## SurvivalStats hunger drain) RELATIVE to their captured base values. This is additive runtime tuning
## via public properties — it tweaks balance, it does not edit or break those systems. Exposes
## multiplier()/enemy_scale()/tier_name() hooks + a HUD readout.

signal changed(day: int, multiplier: float)

@export var per_day := 0.22         ## difficulty added per survived day
@export var max_multiplier := 3.0

var _day := 0
var _mult := 1.0
# captured base values, so scaling stays relative to the originals
var _b_alive := 12
var _b_base_int := 18.0
var _b_night_int := 9.0
var _b_hunger := 0.6


func _ready() -> void:
	_b_alive = Horde.alive_cap
	_b_base_int = Horde.base_interval
	_b_night_int = Horde.night_interval
	_b_hunger = SurvivalStats.hunger_drain_per_sec
	_apply(maxi(1, DayNight.day))


func _process(_delta: float) -> void:
	if DayNight.day != _day:
		_apply(DayNight.day)


func _apply(day: int) -> void:
	_day = day
	_mult = minf(max_multiplier, 1.0 + float(day - 1) * per_day)
	# more & faster zombies
	Horde.alive_cap = _b_alive + (day - 1) * 2
	Horde.base_interval = maxf(6.0, _b_base_int - float(day - 1) * 1.5)
	Horde.night_interval = maxf(3.0, _b_night_int - float(day - 1) * 0.8)
	# hunger bites harder
	SurvivalStats.hunger_drain_per_sec = _b_hunger * _mult
	changed.emit(_day, _mult)


func day() -> int:
	return _day


func multiplier() -> float:
	return _mult


func enemy_scale() -> float:
	return _mult


func tier_name() -> String:
	if _day <= 1:
		return "CALM"
	elif _day == 2:
		return "RISING"
	elif _day == 3:
		return "TENSE"
	elif _day == 4:
		return "DIRE"
	return "NIGHTMARE"
