extends Node
## Infection (autoload) — a zombie-infection meter (0..100). Standing within bite_radius of zombies
## (group "dummy") ramps it up ("exposure"); call bite() for a direct hit. At CRITICAL it bleeds health
## via the public SurvivalStats API. Cure with an Antidote ([V]). It registers the Antidote into ItemDB
## and makes it obtainable by APPENDING to the existing Merchant stock + a Crafting recipe (additive,
## public vars) — no existing source is edited.

signal changed(level: float)
signal stage_changed(stage: int)

enum Stage { CLEAN, EXPOSED, INFECTED, CRITICAL }

@export var bite_radius := 2.2
@export var exposure_rate := 9.0      ## infection per second per nearby zombie
@export var bite_amount := 18.0       ## per direct bite()
@export var critical_dps := 4.0       ## health per second lost while CRITICAL
@export var cure_amount := 70.0

var level := 0.0
var _stage := Stage.CLEAN
var _player: Node3D = null


func _enter_tree() -> void:
	if not InputMap.has_action(&"use_antidote"):
		InputMap.add_action(&"use_antidote")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_V
		InputMap.action_add_event(&"use_antidote", e)


func _ready() -> void:
	ItemDB.register(Item.make(&"antidote", "Antidote", Item.Category.HEAL, 9, 180, "Suppresses the zombie infection."))
	Merchant.stock.append({ "id": &"antidote", "price": 220 })
	Crafting.recipes.append({
		"id": &"r_antidote", "name": "Antidote",
		"inputs": { &"herb_mix": 1, &"scrap": 2 }, "out": &"antidote", "count": 1,
	})


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	var near := 0
	if _player:
		for z in get_tree().get_nodes_in_group(&"dummy"):
			if z is Node3D and _player.global_position.distance_to((z as Node3D).global_position) <= bite_radius:
				near += 1
	if near > 0:
		_add(exposure_rate * near * delta)
	if level >= 90.0:
		SurvivalStats.add_health(-critical_dps * delta)
	_update_stage()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"use_antidote"):
		cure()


func bite(amount := -1.0) -> void:
	_add(amount if amount > 0.0 else bite_amount)
	_update_stage()


func cure() -> bool:
	if not Inventory.has(&"antidote", 1):
		return false
	Inventory.remove(&"antidote", 1)
	_add(-cure_amount)
	_update_stage()
	return true


func stage() -> int:
	return _stage


func stage_name() -> String:
	match _stage:
		Stage.CLEAN: return "CLEAN"
		Stage.EXPOSED: return "EXPOSED"
		Stage.INFECTED: return "INFECTED"
		Stage.CRITICAL: return "CRITICAL"
	return "?"


func _add(v: float) -> void:
	var n := clampf(level + v, 0.0, 100.0)
	if not is_equal_approx(n, level):
		level = n
		changed.emit(level)


func _update_stage() -> void:
	var s := Stage.CLEAN
	if level >= 90.0:
		s = Stage.CRITICAL
	elif level >= 60.0:
		s = Stage.INFECTED
	elif level >= 25.0:
		s = Stage.EXPOSED
	if s != _stage:
		_stage = s
		stage_changed.emit(s)
