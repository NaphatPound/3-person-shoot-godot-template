extends Node3D
class_name BloodstainNode
## A flat blood decal that fades out over `duration` then frees itself. Purely visual.

@export var radius := 0.6
@export var duration := 12.0

var _t := 0.0
var _mat: StandardMaterial3D


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.02
	mesh.mesh = cyl
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.4, 0.03, 0.03, 0.75)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.roughness = 1.0
	mesh.material_override = _mat
	add_child(mesh)


func _process(delta: float) -> void:
	_t += delta
	if _mat:
		_mat.albedo_color.a = lerpf(0.75, 0.0, clampf(_t / duration, 0.0, 1.0))
	if _t >= duration:
		queue_free()
