extends StaticBody3D
class_name BarricadeNode
## A placed barrier with its own HP. Physically blocks (collision layer 1). Zombies (group "dummy")
## within claw_range chew it down over time; at 0 HP it breaks and reports to Barricades. repair() restores
## HP. Self-builds a collider + mesh + a billboard HP label; joins group "barricade".

@export var max_hp := 100.0
@export var claw_dps := 12.0
@export var claw_range := 1.6

var hp := 100.0
var _broken := false
var _label: Label3D


func _ready() -> void:
	add_to_group(&"barricade")
	hp = max_hp
	collision_layer = 1
	collision_mask = 0

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 1.2, 0.3)
	shape.shape = box
	shape.position = Vector3(0, 0.6, 0)
	add_child(shape)

	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 1.2, 0.3)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.36, 0.22)
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.6, 0)
	add_child(mesh)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 1.5, 0)
	_label.pixel_size = 0.006
	_label.outline_size = 8
	add_child(_label)
	_refresh_label()


func _process(delta: float) -> void:
	if _broken:
		return
	if _zombie_near():
		hp -= claw_dps * delta
		_refresh_label()
		if hp <= 0.0:
			_broken = true       # idempotent: queue_free is deferred, guard the extra frame
			Barricades.notify_broken()
			queue_free()


func _zombie_near() -> bool:
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			if global_position.distance_to((z as Node3D).global_position) <= claw_range:
				return true
	return false


func repair(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	_refresh_label()


func _refresh_label() -> void:
	if _label:
		_label.text = "BARRICADE  %d%%" % int(round(hp / max_hp * 100.0))
		var t := clampf(hp / max_hp, 0.0, 1.0)
		_label.modulate = Color(1.0, 0.4 + 0.5 * t, 0.4 + 0.5 * t)
