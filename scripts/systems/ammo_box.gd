extends WorldPickup
class_name AmmoBoxNode
## A dedicated ammo resupply crate. EXTENDS WorldPickup so the Interaction system ([E]) detects it;
## grabbing it dumps a chunk of handgun ammo into the Inventory. Groups "pickup" + "ammobox".

func _ready() -> void:
	add_to_group(&"pickup")
	add_to_group(&"ammobox")
	spin_speed = 0.0

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.35, 0.7)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.45, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.35, 0.12)
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.3, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "AMMO BOX  [E]"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.95, 0)
	label.pixel_size = 0.006
	label.modulate = Color(0.7, 0.95, 0.5)
	label.outline_size = 8
	add_child(label)


func get_label() -> String:
	return "Ammo Box"


func interact() -> void:
	AmmoBoxes.collect(self)
