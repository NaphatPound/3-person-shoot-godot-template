extends Node
## Score (autoload) — a running survival score derived from existing stats (hits, gold earned, days
## survived, achievements, quests, headshots, kit/ally kills) and a persisted high score
## (user://highscore.json, also saved on extraction). Read-only over the other systems; persists only its
## own high score. ScoreHUD shows it.

signal changed(current: int, high: int)

const SAVE_PATH := "user://highscore.json"

var current := 0
var high := 0
var _last_saved := 0


func _ready() -> void:
	load_high()
	Extraction.extracted.connect(save_high)


func _process(_delta: float) -> void:
	current = _compute()
	if current > high:
		high = current
		if high - _last_saved >= 100:
			save_high()
	changed.emit(current, high)


func _compute() -> int:
	var s := 0.0
	s += Stats.get_stat("hits") * 10.0
	s += Stats.get_stat("gold_earned") * 0.1
	s += float(maxi(0, DayNight.day - 1)) * 200.0
	s += Stats.unlocked_count() * 100.0
	s += Stats.get_stat("quests") * 150.0
	s += Headshots.count * 25.0
	s += float(Traps.kills + Grenades.kills + Molotovs.kills + Companions.assists) * 15.0
	return int(round(s))


func save_high() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({ "high": high }))
	f.close()
	_last_saved = high
	return true


func load_high() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) == TYPE_DICTIONARY:
		high = int(d.get("high", 0))
		_last_saved = high
		return true
	return false
