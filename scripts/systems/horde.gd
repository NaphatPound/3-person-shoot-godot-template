extends Node
## Horde (autoload) — a wave director. On a timer (shorter at night, from DayNight) it spawns a wave of
## zombies by reusing the existing dummy.tscn into the active World scene. Waves escalate; its own spawn
## count is capped and rotated (oldest freed) so it never floods. Only acts in the World scene
## (scene_file_path gate); seeds nothing elsewhere. Touches no existing node — the spawned dummies are
## ordinary hostiles, so combat + the quest "hunt" objective work on them for free.

signal wave_started(number: int, count: int)

const WORLD_SCENE := "res://scenes/world.tscn"
const DUMMY := "res://scenes/dummy.tscn"

@export var base_interval := 18.0     ## seconds between waves during the day
@export var night_interval := 9.0     ## faster at night
@export var alive_cap := 12           ## max concurrent horde-spawned zombies

var wave := 0
var _timer := 8.0
var _scene: Node = null
var _dummy_ps: PackedScene = null
var _spawned: Array = []
var _spread := 0


func _ready() -> void:
	_dummy_ps = load(DUMMY) as PackedScene


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		return
	_scene = scene
	_timer -= delta
	if _timer <= 0.0:
		_spawn_wave()
		_timer = night_interval if DayNight.is_night() else base_interval


## live horde-spawned zombies (excludes the scene's original dummies).
func alive() -> int:
	_spawned = _spawned.filter(func(d): return is_instance_valid(d))
	return _spawned.size()


func _spawn_wave() -> void:
	if _dummy_ps == null or _scene == null:
		return
	wave += 1
	var count := 2 + wave / 2
	if DayNight.is_night():
		count += 2
	for i in count:
		_spawn_one()
	wave_started.emit(wave, count)


func _spawn_one() -> void:
	_spawned = _spawned.filter(func(d): return is_instance_valid(d))
	if _spawned.size() >= alive_cap:
		var oldest = _spawned.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var z := _dummy_ps.instantiate() as Node3D
	# spread spawns around the arena using the golden angle (deterministic, no RNG)
	_spread += 1
	var ang := float(_spread) * 2.399963
	var r := 5.0 + float(_spread % 4)
	z.position = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
	_scene.add_child(z)
	_spawned.append(z)
