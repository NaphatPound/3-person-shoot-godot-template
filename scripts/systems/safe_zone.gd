extends Node3D
class_name SafeZoneNode
## An RE-style safe room: a green pad. Joins group "safezone". Visual only — the SafeZones autoload
## checks the player's distance and applies healing / infection cleanse while inside.

func _ready() -> void:
	add_to_group(&"safezone")
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.0
	cyl.bottom_radius = 3.0
	cyl.height = 0.1
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.5, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.4)
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.06, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "SAFE ZONE"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.6, 0)
	label.pixel_size = 0.008
	label.modulate = Color(0.5, 1.0, 0.7)
	label.outline_size = 8
	add_child(label)
