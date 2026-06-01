extends Node
## Extraction (autoload) — the win condition. Survive `arm_time` seconds, then the ExtractionZone OPENS;
## stand in it for `hold_time` seconds to ESCAPE (win → victory banner + pause). Seeds an ExtractionZone
## into the World scene (scene_file_path; skipped during --demo). Passive — no key. Touches nothing.

signal state_changed(state: int)
signal time_changed(remaining: float)
signal hold_changed(t: float)
signal extracted

enum State { WAITING, OPEN, EXTRACTED }

const WORLD_SCENE := "res://scenes/world.tscn"
const ZONE_POS := Vector3(0.0, 0.0, 6.0)

@export var arm_time := 120.0
@export var hold_time := 3.0
@export var zone_radius := 2.4

var state := State.WAITING
var _t := 0.0
var _hold := 0.0
var _zone: ExtractionZone = null
var _seeded: Node = null


func _process(delta: float) -> void:
	if "--demo" in OS.get_cmdline_user_args():
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		return
	if scene != _seeded:
		_seeded = scene
		_spawn_zone(scene)
		state = State.WAITING
		_t = 0.0
		_hold = 0.0
	tick(delta)


## The state machine, separated so it's testable without the World scene.
func tick(delta: float) -> void:
	match state:
		State.WAITING:
			_t += delta
			time_changed.emit(remaining())
			if _t >= arm_time:
				_open()
		State.OPEN:
			var p := get_tree().get_first_node_in_group(&"player") as Node3D
			if p and _zone and is_instance_valid(_zone) and p.global_position.distance_to(_zone.global_position) <= zone_radius:
				_hold += delta
			else:
				_hold = maxf(0.0, _hold - delta * 0.5)
			hold_changed.emit(_hold)
			if _hold >= hold_time:
				_extract()


func _spawn_zone(scene: Node) -> void:
	_zone = ExtractionZone.new()
	scene.add_child(_zone)
	_zone.global_position = ZONE_POS


func _open() -> void:
	state = State.OPEN
	if _zone and is_instance_valid(_zone):
		_zone.set_open(true)
	state_changed.emit(state)


func _extract() -> void:
	state = State.EXTRACTED
	state_changed.emit(state)
	extracted.emit()
	get_tree().paused = true


func remaining() -> float:
	return maxf(0.0, arm_time - _t)


func hold_t() -> float:
	return _hold


func state_name() -> String:
	match state:
		State.WAITING: return "WAITING"
		State.OPEN: return "OPEN"
		State.EXTRACTED: return "EXTRACTED"
	return "?"
