extends Node
## Variants (autoload) — promotes some freshly-spawned zombies into special variants (TANK = bigger,
## RUNNER = small) by scaling the node + adding a tint aura & billboard label at runtime (World scene
## only, so the headless hit-scan test is never touched). Purely additive — scales the node + adds child
## nodes; never edits dummy.gd. Visual variety + counts; reads group "dummy".

signal changed

enum Kind { TANK, RUNNER }

const WORLD_SCENE := "res://scenes/world.tscn"

@export var tank_chance := 0.22
@export var runner_chance := 0.22

var tanks := 0
var runners := 0
var _seen := {}
var _scene: Node = null


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != WORLD_SCENE:
		_seen.clear()
		_scene = scene
		return
	if scene != _scene:
		_scene = scene
		_seen.clear()
	_scan(scene)


func _scan(_scene: Node) -> void:
	var current := {}
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			var id := z.get_instance_id()
			current[id] = true
			if not _seen.has(id):
				_seen[id] = true
				_maybe_promote(z)
	for id in _seen.keys():
		if not current.has(id):
			_seen.erase(id)


func _maybe_promote(z: Node3D) -> void:
	var r := randf()
	if r < tank_chance:
		_promote(z, Kind.TANK)
	elif r < tank_chance + runner_chance:
		_promote(z, Kind.RUNNER)


func _promote(z: Node3D, kind: int) -> void:
	if z.is_in_group(&"tank") or z.is_in_group(&"runner"):
		return
	var col := Color.WHITE
	var text := ""
	if kind == Kind.TANK:
		z.scale = Vector3(1.4, 1.4, 1.4)
		z.add_to_group(&"tank")
		tanks += 1
		col = Color(1, 0.35, 0.3)
		text = "TANK"
	else:
		z.scale = Vector3(0.72, 0.72, 0.72)
		z.add_to_group(&"runner")
		runners += 1
		col = Color(1, 0.9, 0.35)
		text = "RUNNER"

	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.1, 0)
	label.pixel_size = 0.006
	label.modulate = col
	label.outline_size = 8
	z.add_child(label)

	var aura := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.55
	sph.height = 1.1
	aura.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.18)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura.material_override = mat
	aura.position = Vector3(0, 1.0, 0)
	z.add_child(aura)

	changed.emit()
