extends Node
## ZombieGlow (autoload) — when global Tension is high, zombies (group "dummy") glow red; the glow fades
## as the threat subsides. Attaches a translucent emissive shell to each zombie once (World scene only,
## so the headless test dummies stay untouched), then modulates every shell's energy/alpha by
## Tension.level01() each frame. Additive — adds a child + reads Tension; never edits dummy.gd. Passive.

const WORLD_SCENE := "res://scenes/world.tscn"

@export var max_energy := 2.5
@export var max_alpha := 0.32

var _glow := {}        # dummy instance_id -> StandardMaterial3D
var _scene: Node = null


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		_glow.clear()
		_scene = scene
		return
	if scene != _scene:
		_scene = scene
		_glow.clear()
	_scan(scene)
	_apply(Tension.level01())


func _scan(_scene: Node) -> void:
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			var id := z.get_instance_id()
			if not _glow.has(id):
				_glow[id] = _attach_glow(z)


func _apply(lvl: float) -> void:
	var alive := {}
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if is_instance_valid(z):
			alive[z.get_instance_id()] = true
	for id in _glow.keys():
		if not alive.has(id):
			_glow.erase(id)
		elif _glow[id]:
			var m: StandardMaterial3D = _glow[id]
			m.emission_energy_multiplier = lvl * max_energy
			m.albedo_color.a = lvl * max_alpha


func _attach_glow(z: Node3D) -> StandardMaterial3D:
	var shell := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.6
	sph.height = 1.6
	shell.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.15, 0.1, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.15, 0.1)
	mat.emission_energy_multiplier = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell.material_override = mat
	shell.position = Vector3(0, 1.0, 0)
	z.add_child(shell)
	return mat
