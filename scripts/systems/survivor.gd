extends WorldPickup
class_name SurvivorNode
## A trapped survivor to rescue. EXTENDS WorldPickup so the Interaction system ([E]) detects it for free;
## reaching it rescues them for a gold reward (which also feeds the score via gold_earned). Overrides the
## visual/label/interact; joins groups "pickup" + "survivor".

func _ready() -> void:
	add_to_group(&"pickup")
	add_to_group(&"survivor")
	spin_speed = 0.0

	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.5
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.4
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.75, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "SURVIVOR  [E]"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.85, 0)
	label.pixel_size = 0.006
	label.modulate = Color(0.6, 0.9, 1.0)
	label.outline_size = 8
	add_child(label)


func get_label() -> String:
	return "Rescue Survivor"


func interact() -> void:
	Rescues.rescue(self)
