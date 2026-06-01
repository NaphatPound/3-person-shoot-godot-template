extends Node3D
class_name StoragePoint
## A safe-room item box in the world. Self-builds a chest marker + billboard label and joins group
## "storage" so StorageUI detects proximity. No logic of its own.

func _ready() -> void:
	add_to_group(&"storage")

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.6, 0.6)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.32, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.22, 0.12)
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.3, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "STORAGE  [G]"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.15, 0)
	label.pixel_size = 0.007
	label.outline_size = 8
	add_child(label)
