extends WorldPickup
class_name SavePointNode
## An RE-style typewriter / save point. EXTENDS WorldPickup so the Interaction system ([E]) detects it;
## interacting saves the game (does not consume/free itself, so you can save repeatedly). Groups
## "pickup" + "savepoint".

func _ready() -> void:
	add_to_group(&"pickup")
	add_to_group(&"savepoint")
	spin_speed = 0.0

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.4, 0.5)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.25)
	mat.metallic = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.18, 0.25)
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.45, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "TYPEWRITER  [E]"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.1, 0)
	label.pixel_size = 0.006
	label.modulate = Color(0.8, 0.85, 1.0)
	label.outline_size = 8
	add_child(label)


func get_label() -> String:
	return "Save (Typewriter)"


func interact() -> void:
	SavePoints.save_here()
