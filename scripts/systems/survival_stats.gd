extends Node
## SurvivalStats (autoload) — RE-style survival meters that tick in real time.
## Hunger drains continuously; once it hits 0 the character is STARVING and Health bleeds down.
## Eat FOOD items from the Inventory with [F] to restore hunger, use HEAL items with [H] to restore
## health (and recover from death). Fully self-contained: owns its own hunger/health values (there is
## no pre-existing health system to hook), registers its own input, and never touches the
## player / existing HUD / InventoryUI. Pauses with the tree, so time stops while the bag is open.

signal stats_changed(hunger: float, health: float)
signal starving_changed(is_starving: bool)
signal died

@export var max_hunger := 100.0
@export var max_health := 100.0
@export var hunger_drain_per_sec := 0.6     ## ~167 s from full to starving
@export var starve_damage_per_sec := 2.0    ## health lost per second while starving
@export var hunger_per_food := 45.0         ## hunger restored per FOOD item eaten
@export var health_per_heal := 50.0         ## health restored per HEAL item used

var hunger := 100.0
var health := 100.0
var _starving := false
var _alive := true


func _enter_tree() -> void:
	_ensure_action(&"eat", KEY_F)
	_ensure_action(&"heal", KEY_H)


func _ready() -> void:
	hunger = max_hunger
	health = max_health
	stats_changed.emit(hunger, health)


func _process(delta: float) -> void:
	if not _alive:
		return
	hunger = maxf(0.0, hunger - hunger_drain_per_sec * delta)
	var starving := hunger <= 0.0
	if starving:
		health = maxf(0.0, health - starve_damage_per_sec * delta)
		if health <= 0.0:
			_set_alive(false)
	if starving != _starving:
		_starving = starving
		starving_changed.emit(starving)
	stats_changed.emit(hunger, health)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"eat"):
		eat()
	elif event.is_action_pressed(&"heal"):
		heal()


## Eat the first FOOD item in the bag. Returns true if something was eaten.
func eat() -> bool:
	return _consume(Item.Category.FOOD, hunger_per_food, true)


## Use the first HEAL item in the bag. Returns true if something was used.
func heal() -> bool:
	return _consume(Item.Category.HEAL, health_per_heal, false)


func _consume(cat: int, amount: float, is_food: bool) -> bool:
	for slot in Inventory.get_slots():
		if slot == null:
			continue
		var item: Item = ItemDB.get_item(slot["id"])
		if item and item.category == cat:
			if Inventory.remove(item.id, 1):
				if is_food:
					hunger = minf(max_hunger, hunger + amount)
				else:
					health = minf(max_health, health + amount)
				if health > 0.0:
					_set_alive(true)
				stats_changed.emit(hunger, health)
				return true
	return false


func add_hunger(v: float) -> void:
	hunger = clampf(hunger + v, 0.0, max_hunger)
	stats_changed.emit(hunger, health)


func add_health(v: float) -> void:
	health = clampf(health + v, 0.0, max_health)
	if health <= 0.0:
		_set_alive(false)
	else:
		_set_alive(true)
	stats_changed.emit(hunger, health)


func is_starving() -> bool:
	return _starving


func is_alive() -> bool:
	return _alive


func _set_alive(v: bool) -> void:
	if v == _alive:
		return
	_alive = v
	if not v:
		died.emit()


func _ensure_action(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var e := InputEventKey.new()
		e.physical_keycode = code
		InputMap.action_add_event(action, e)
