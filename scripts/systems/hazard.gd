extends Node3D
class_name HazardNode
## A toxic gas zone (the dangerous mirror of a safe room). Joins group "hazard". Visual only — the
## Hazards autoload checks the player's distance and applies damage / infection while inside.

func _ready() -> void:
	add_to_group(&"hazard")
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.8
	cyl.bottom_radius = 2.8
	cyl.height = 1.6
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.8, 0.2, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.7, 0.15)
	mat.emission_energy_multiplier = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.8, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "TOXIC"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.9, 0)
	label.pixel_size = 0.008
	label.modulate = Color(0.8, 1.0, 0.3)
	label.outline_size = 8
	add_child(label)
