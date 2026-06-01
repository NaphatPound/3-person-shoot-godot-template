extends Node3D
class_name MerchantPoint
## A spot in the world where the player can trade. Self-builds a marker capsule + a billboard label
## and joins group "merchant" so MerchantUI detects proximity. No logic of its own.

func _ready() -> void:
	add_to_group(&"merchant")

	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.7
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.2, 0.6)
	mat.emission_energy_multiplier = 0.45
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.85, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "MERCHANT  [B]"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.95, 0)
	label.pixel_size = 0.007
	label.outline_size = 8
	add_child(label)
