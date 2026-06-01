extends Node
## Ammo (autoload) — magazine + reserve ammunition with reload, tying the Inventory (reserve = its count
## of ammo_9mm) to the Weapons system (magazine CAPACITY + RELOAD time). It hooks the player's `fired`
## signal to spend a loaded round, and GATES firing when empty by consuming the "attack" input in _input
## — additive: player.gd is never edited, and while there is ammo behaviour is byte-identical (the gate
## only triggers at 0 rounds and only once the mouse is captured, so first-click capture + the demo's
## direct fire() path are untouched). [R] reloads; the last shot auto-triggers a reload.

signal changed
signal reload_started
signal reloaded

const WEAPON := &"handgun"
const AMMO_ITEM := &"ammo_9mm"

var magazine := 0
var _reloading := false
var _reload_t := 0.0
var _player: Node = null


func _enter_tree() -> void:
	if not InputMap.has_action(&"reload"):
		InputMap.add_action(&"reload")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_R
		InputMap.action_add_event(&"reload", e)


func _ready() -> void:
	# load the first magazine out of the starting reserve
	var take := mini(capacity(), reserve())
	if take > 0:
		Inventory.remove(AMMO_ITEM, take)
		magazine = take
	changed.emit()


func capacity() -> int:
	return int(round(Weapons.get_stat(WEAPON, "capacity")))


func reserve() -> int:
	return Inventory.count_of(AMMO_ITEM)


func reload_time() -> float:
	return maxf(0.2, Weapons.get_stat(WEAPON, "reload"))


func is_reloading() -> bool:
	return _reloading


func can_fire() -> bool:
	return magazine > 0 and not _reloading


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var p := get_tree().get_first_node_in_group(&"player")
		if p and p.has_signal("fired") and not p.fired.is_connected(_on_fired):
			p.fired.connect(_on_fired)
			_player = p
	if _reloading:
		_reload_t -= delta
		if _reload_t <= 0.0:
			_finish_reload()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reload"):
		start_reload()
		return
	# block firing on an empty magazine (only in-game, i.e. mouse captured)
	if event.is_action_pressed(&"attack") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not can_fire():
		get_viewport().set_input_as_handled()
		start_reload()


func _on_fired() -> void:
	if magazine > 0:
		magazine -= 1
		changed.emit()
		if magazine == 0:
			start_reload()


func start_reload() -> void:
	if _reloading or magazine >= capacity() or reserve() <= 0:
		return
	_reloading = true
	_reload_t = reload_time()
	reload_started.emit()
	changed.emit()


func _finish_reload() -> void:
	_reloading = false
	var take := mini(capacity() - magazine, reserve())
	if take > 0:
		Inventory.remove(AMMO_ITEM, take)
		magazine += take
	reloaded.emit()
	changed.emit()
