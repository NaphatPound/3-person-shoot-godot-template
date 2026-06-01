extends Node
## Events (autoload) — random world events on a timer (World scene only; skipped during --demo). Fires
## SUPPLY_DROP (a loot cluster via WorldPickup), HORDE_SURGE (a ring of extra zombies via dummy.tscn) or
## CACHE (high-value loot), and announces each. Reuses the existing pickup + dummy scenes; touches no
## existing node. Key-free / passive.

signal event_fired(text: String)
signal changed

const WORLD_SCENE := "res://scenes/world.tscn"
const DUMMY := "res://scenes/dummy.tscn"

@export var min_interval := 30.0
@export var max_interval := 55.0

var count := 0
var _timer := 20.0
var _dummy_ps: PackedScene = null


func _ready() -> void:
	_dummy_ps = load(DUMMY) as PackedScene


func _process(delta: float) -> void:
	if "--demo" in OS.get_cmdline_user_args():
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(min_interval, max_interval)
		_fire(scene)


func _fire(scene: Node) -> void:
	if scene == null:
		return
	count += 1
	match randi() % 3:
		0: _supply_drop(scene)
		1: _horde_surge(scene)
		2: _cache(scene)
	changed.emit()


## manual trigger (testing / future scripting)
func trigger(scene: Node = null) -> void:
	_fire(scene if scene else get_tree().current_scene)


func _supply_drop(scene: Node) -> void:
	var base := _rand_spot()
	_spawn_pickup(scene, &"ammo_9mm", 14, base)
	_spawn_pickup(scene, &"scrap", 3, base + Vector3(0.8, 0, 0))
	_spawn_pickup(scene, &"herb_green", 1, base + Vector3(-0.8, 0, 0))
	event_fired.emit("SUPPLY DROP — grab the crate!")


func _horde_surge(scene: Node) -> void:
	if _dummy_ps == null:
		event_fired.emit("HORDE SURGE!")
		return
	var n := 4 + randi() % 3
	for i in n:
		var ang := TAU * float(i) / float(n)
		var z := _dummy_ps.instantiate() as Node3D
		scene.add_child(z)
		z.position = Vector3(cos(ang) * 6.0, 0.0, sin(ang) * 6.0)
	event_fired.emit("HORDE SURGE — incoming!")


func _cache(scene: Node) -> void:
	var base := _rand_spot()
	_spawn_pickup(scene, &"gem_blue", 1, base)
	_spawn_pickup(scene, &"scrap", 5, base + Vector3(0.7, 0, 0))
	event_fired.emit("HIDDEN CACHE found!")


func _spawn_pickup(scene: Node, id: StringName, amount: int, pos: Vector3) -> void:
	var p := WorldPickup.new()
	p.item_id = id
	p.amount = amount
	scene.add_child(p)
	p.position = pos


func _rand_spot() -> Vector3:
	return Vector3(randf_range(-8.0, 8.0), 0.5, randf_range(-8.0, 8.0))
