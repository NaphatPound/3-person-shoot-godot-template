extends Node3D
class_name TrapNode
## An armed single-use trap. After a short arm delay it triggers on the first zombie (group "dummy")
## within trigger_radius: flashes it (on_hit), kills it (frees it), reports to the Traps autoload, then
## removes itself. Self-builds a small plate marker. Spawned by the Traps autoload.

@export var trigger_radius := 1.4
@export var arm_delay := 0.4

var _arm_t := 0.0
var _spent := false


func _ready() -> void:
	add_to_group(&"trap")
	_arm_t = arm_delay
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = trigger_radius * 0.6
	cyl.bottom_radius = trigger_radius * 0.6
	cyl.height = 0.08
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.5, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.4, 0.1)
	mat.emission_energy_multiplier = 0.5
	mesh.position = Vector3(0, 0.04, 0)
	mesh.material_override = mat
	add_child(mesh)


func _process(delta: float) -> void:
	if _spent:
		return
	if _arm_t > 0.0:
		_arm_t -= delta
		return
	var victim := _nearest_dummy()
	if victim != null:
		_trigger(victim)


func _nearest_dummy() -> Node3D:
	var best: Node3D = null
	var bd := trigger_radius * trigger_radius
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			var d := global_position.distance_squared_to((z as Node3D).global_position)
			if d <= bd:
				bd = d
				best = z
	return best


func _trigger(victim: Node3D) -> void:
	_spent = true
	if victim.has_method("on_hit"):
		victim.on_hit()
	Traps.register_kill()
	victim.queue_free()
	queue_free()
