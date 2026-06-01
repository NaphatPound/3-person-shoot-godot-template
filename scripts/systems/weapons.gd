extends Node
## Weapons (autoload) — weapon upgrade & customization ("อัพเกรด/ตกแต่งปืน"). Tracks per-weapon upgrade
## levels (damage / capacity / fire_rate / reload) and equipped attachments, computes effective stats,
## and spends Currency gold + scrap (a MATERIAL item from the Inventory) to level up. Self-contained
## data layer: it does NOT modify the player/gun (so nothing breaks); the future ammo/reload system can
## read get_stat(...,"capacity"/"reload") and the player could optionally read "damage"/"fire_rate".

signal upgraded(weapon_id: StringName)
signal changed

const WEAPONS := {
	&"handgun": {
		"name": "SLS 60 Handgun",
		"base": { "damage": 25.0, "capacity": 10.0, "fire_rate": 3.0, "reload": 1.5 },
		"inc":  { "damage": 8.0,  "capacity": 4.0,  "fire_rate": 0.6, "reload": -0.18 },
		"max":  { "damage": 5,    "capacity": 5,    "fire_rate": 5,   "reload": 4 },
	},
}

const ATTACHMENTS := {
	&"laser":   { "name": "Laser Sight", "gold": 200 },
	&"ext_mag": { "name": "Extended Mag (+5 capacity)", "gold": 300, "capacity_bonus": 5.0 },
	&"stock":   { "name": "Tactical Stock", "gold": 250 },
}

var _levels: Dictionary = {}        # weapon_id -> { track: int }
var _attachments: Dictionary = {}   # weapon_id -> { key: bool }


func _ready() -> void:
	for wid in WEAPONS:
		_levels[wid] = { "damage": 0, "capacity": 0, "fire_rate": 0, "reload": 0 }
		_attachments[wid] = {}


func weapon_ids() -> Array:
	return WEAPONS.keys()


func weapon_name(weapon_id: StringName) -> String:
	return WEAPONS.get(weapon_id, {}).get("name", String(weapon_id))


func tracks() -> Array:
	return ["damage", "capacity", "fire_rate", "reload"]


func level_of(weapon_id: StringName, track: String) -> int:
	return _levels.get(weapon_id, {}).get(track, 0)


func max_level(weapon_id: StringName, track: String) -> int:
	return WEAPONS.get(weapon_id, {}).get("max", {}).get(track, 0)


## Effective stat value = base + level*increment (+ attachment bonuses).
func get_stat(weapon_id: StringName, track: String) -> float:
	if not WEAPONS.has(weapon_id):
		return 0.0
	var w = WEAPONS[weapon_id]
	var val: float = float(w["base"][track]) + float(w["inc"][track]) * level_of(weapon_id, track)
	if track == "capacity" and has_attachment(weapon_id, &"ext_mag"):
		val += float(ATTACHMENTS[&"ext_mag"]["capacity_bonus"])
	return val


func upgrade_cost(weapon_id: StringName, track: String) -> Dictionary:
	var lv := level_of(weapon_id, track)
	return { "gold": 80 * (lv + 1), "scrap": 1 + lv }


func can_upgrade(weapon_id: StringName, track: String) -> bool:
	if level_of(weapon_id, track) >= max_level(weapon_id, track):
		return false
	var c := upgrade_cost(weapon_id, track)
	return Currency.can_afford(c["gold"]) and Inventory.count_of(&"scrap") >= c["scrap"]


func upgrade(weapon_id: StringName, track: String) -> bool:
	if not can_upgrade(weapon_id, track):
		return false
	var c := upgrade_cost(weapon_id, track)
	Currency.spend(c["gold"])
	Inventory.remove(&"scrap", c["scrap"])
	_levels[weapon_id][track] += 1
	upgraded.emit(weapon_id)
	changed.emit()
	return true


func attachment_keys() -> Array:
	return ATTACHMENTS.keys()


func attachment_info(key: StringName) -> Dictionary:
	return ATTACHMENTS.get(key, {})


func has_attachment(weapon_id: StringName, key: StringName) -> bool:
	return _attachments.get(weapon_id, {}).get(key, false)


func buy_attachment(weapon_id: StringName, key: StringName) -> bool:
	if has_attachment(weapon_id, key) or not ATTACHMENTS.has(key):
		return false
	var gold: int = ATTACHMENTS[key]["gold"]
	if not Currency.can_afford(gold):
		return false
	Currency.spend(gold)
	_attachments[weapon_id][key] = true
	upgraded.emit(weapon_id)
	changed.emit()
	return true
