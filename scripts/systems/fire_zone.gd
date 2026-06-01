extends Node3D
class_name FireZoneNode
## A lingering fire patch (spawned by a Molotov). Persists `duration` seconds; zombies (group "dummy")
## standing in it accumulate burn time and die once they've burned `burn_time`. Reports kills to Molotovs.
## Area-denial — distinct from the frag grenade's instant blast.

@export var radius := 2.6
@export var duration := 6.0
@export var burn_time := 1.2

var _burn := {}        # dummy instance_id -> seconds spent in the fire
var _life := 0.0
var _mat: StandardMaterial3D


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.1
	mesh.mesh = cyl
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(1, 0.45, 0.1, 0.55)
	_mat.emission_enabled = true
	_mat.emission = Color(1, 0.4, 0.08)
	_mat.emission_energy_multiplier = 3.0
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = _mat
	mesh.position = Vector3(0, 0.06, 0)
	add_child(mesh)


func _process(delta: float) -> void:
	_life += delta
	if _mat:
		_mat.emission_energy_multiplier = 2.5 + sin(_life * 18.0)
	var r2 := radius * radius
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			if global_position.distance_squared_to((z as Node3D).global_position) <= r2:
				var id := z.get_instance_id()
				_burn[id] = float(_burn.get(id, 0.0)) + delta
				if _burn[id] >= burn_time:
					if z.has_method("on_hit"):
						z.on_hit()
					z.queue_free()
					_burn.erase(id)
					Molotovs.register_kill()
	if _life >= duration:
		queue_free()
