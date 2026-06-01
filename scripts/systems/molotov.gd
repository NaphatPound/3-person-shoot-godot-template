extends Node3D
class_name MolotovNode
## A thrown molotov. Arcs under gravity; on landing or fuse end it spawns a lingering FireZoneNode at the
## impact point and frees itself. (Frag grenade = instant blast; molotov = area denial over time.)

@export var gravity := 18.0
@export var fuse := 2.5

var velocity := Vector3.ZERO
var _spent := false


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.11
	s.height = 0.22
	mesh.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.35, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.4, 0.1)
	mat.emission_energy_multiplier = 1.0
	mesh.material_override = mat
	add_child(mesh)


func throw_from(pos: Vector3, dir: Vector3) -> void:
	global_position = pos
	var flat := dir
	flat.y = 0.0
	if flat.length() > 0.01:
		flat = flat.normalized()
	velocity = flat * 8.0 + Vector3.UP * 4.0


func _process(delta: float) -> void:
	if _spent:
		return
	velocity.y -= gravity * delta
	global_position += velocity * delta
	fuse -= delta
	if global_position.y <= 0.05 or fuse <= 0.0:
		_ignite()


func _ignite() -> void:
	_spent = true
	var parent := get_parent()
	if parent:
		var fire := FireZoneNode.new()
		parent.add_child(fire)
		fire.global_position = Vector3(global_position.x, 0.05, global_position.z)
	queue_free()
