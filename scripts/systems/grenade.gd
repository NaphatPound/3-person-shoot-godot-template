extends Node3D
class_name GrenadeNode
## A thrown grenade. Arcs under gravity; detonates on landing or when the fuse ends, killing every zombie
## (group "dummy") within blast_radius (on_hit + free) and spawning a brief expanding blast FX. Reports
## kills to Grenades. Spawned + launched by the Grenades autoload.

@export var gravity := 18.0
@export var fuse := 2.0
@export var blast_radius := 3.5

var velocity := Vector3.ZERO
var _detonated := false


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	mesh.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.16, 0.12)
	mat.metallic = 0.4
	mesh.material_override = mat
	add_child(mesh)


func throw_from(pos: Vector3, dir: Vector3) -> void:
	global_position = pos
	var flat := dir
	flat.y = 0.0
	if flat.length() > 0.01:
		flat = flat.normalized()
	velocity = flat * 9.0 + Vector3.UP * 4.5


func _process(delta: float) -> void:
	if _detonated:
		return
	velocity.y -= gravity * delta
	global_position += velocity * delta
	fuse -= delta
	if global_position.y <= 0.05 or fuse <= 0.0:
		_detonate()


func _detonate() -> void:
	if _detonated:
		return
	_detonated = true
	var killed := 0
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			if global_position.distance_to((z as Node3D).global_position) <= blast_radius:
				if z.has_method("on_hit"):
					z.on_hit()
				z.queue_free()
				killed += 1
	Grenades.register_kills(killed)
	_spawn_blast()
	queue_free()


func _spawn_blast() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var fx := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	fx.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.6, 0.2, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.55, 0.15)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fx.material_override = mat
	parent.add_child(fx)
	fx.global_position = global_position
	fx.scale = Vector3.ONE * 0.2
	var tw := fx.create_tween().set_parallel(true)
	tw.tween_property(fx, "scale", Vector3.ONE * blast_radius, 0.35)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(fx.queue_free)
