extends Node
## Perks (autoload) — a light skill tree. Earn 1 Skill Point per achievement unlocked (listens to
## Stats.achievement_unlocked); spend SP to unlock permanent passive perks. Each perk applies its effect
## ONCE by nudging a SAFE exported knob on an existing autoload — deliberately ones Difficulty does NOT
## rescale each day (bag capacity, stamina regen, max health, noise decay, heal potency), so there is no
## conflict. Additive runtime tuning; edits no source. PerksUI ([P]) shows it.

signal changed
signal sp_gained(total: int)

const PERKS := [
	{ "id": &"p_pockets", "name": "Deep Pockets", "desc": "+4 inventory slots.", "cost": 2 },
	{ "id": &"p_hands", "name": "Fast Hands", "desc": "Stamina regenerates 50% faster.", "cost": 1 },
	{ "id": &"p_tough", "name": "Tough", "desc": "+25 max health (and heal up).", "cost": 2 },
	{ "id": &"p_quiet", "name": "Light Step", "desc": "Noise fades 50% faster.", "cost": 1 },
	{ "id": &"p_medic", "name": "Field Medic", "desc": "Healing items restore +25.", "cost": 1 },
]

var sp := 0
var _unlocked := {}


func _ready() -> void:
	for p in PERKS:
		_unlocked[p["id"]] = false
	Stats.achievement_unlocked.connect(_on_achievement)


func _on_achievement(_id: StringName, _title: String) -> void:
	sp += 1
	sp_gained.emit(sp)
	changed.emit()


func is_unlocked(id: StringName) -> bool:
	return _unlocked.get(id, false)


func cost_of(id: StringName) -> int:
	for p in PERKS:
		if p["id"] == id:
			return int(p["cost"])
	return 0


func unlock(id: StringName) -> bool:
	if _unlocked.get(id, true):
		return false
	var cost := cost_of(id)
	if sp < cost:
		return false
	sp -= cost
	_unlocked[id] = true
	_apply(id)
	changed.emit()
	return true


func _apply(id: StringName) -> void:
	match id:
		&"p_pockets":
			Inventory.capacity += 4
			Inventory._slots.resize(Inventory.capacity)
			Inventory.changed.emit()
		&"p_hands":
			Stamina.regen_rate *= 1.5
		&"p_tough":
			SurvivalStats.max_health += 25.0
			SurvivalStats.health = SurvivalStats.max_health
			SurvivalStats.stats_changed.emit(SurvivalStats.hunger, SurvivalStats.health)
		&"p_quiet":
			NoiseMeter.decay *= 1.5
		&"p_medic":
			SurvivalStats.health_per_heal += 25.0
