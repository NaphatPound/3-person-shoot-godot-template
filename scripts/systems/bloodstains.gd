extends Node
## Bloodstains (autoload) — atmosphere. Polls group "dummy" (World scene only); when a tracked zombie
## vanishes (killed/freed by traps, grenades, fire, the ally, ...) it drops a fading blood decal at its
## last position. Capped + oldest-recycled. Pure additive polling — no system emits anything new, and it
## touches no existing node. Key-free.

const WORLD_SCENE := "res://scenes/world.tscn"

@export var max_stains := 30

var _known := {}        # instance_id -> last Vector3 position
var _stains := []
var _scene: Node = null


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		_known.clear()
		_scene = scene
		return
	if scene != _scene:
		_scene = scene
		_known.clear()      # new World instance — don't blood-spam the reset
	_scan(scene)


## Separated for testability: detect deaths since the last call and drop stains.
func _scan(scene: Node) -> void:
	var current := {}
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			current[z.get_instance_id()] = (z as Node3D).global_position
	for id in _known:
		if not current.has(id):
			_spawn_stain(scene, _known[id])
	_known = current


func _spawn_stain(scene: Node, pos: Vector3) -> void:
	_stains = _stains.filter(func(s): return is_instance_valid(s))
	if _stains.size() >= max_stains:
		var oldest = _stains.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var st := BloodstainNode.new()
	scene.add_child(st)
	st.global_position = Vector3(pos.x, 0.03, pos.z)
	_stains.append(st)
