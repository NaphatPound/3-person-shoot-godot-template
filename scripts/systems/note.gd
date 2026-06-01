extends WorldPickup
class_name NoteNode
## A collectible lore document. EXTENDS WorldPickup so the Interaction system ([E]) detects it; reading it
## opens it in NotesUI. Set `title`/`body` before adding to a scene. Groups "pickup" + "note".

@export var title := "Note"
@export var body := ""


func _ready() -> void:
	add_to_group(&"pickup")
	add_to_group(&"note")
	spin_speed = 0.0

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.02, 0.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.88, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.48, 0.35)
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.5, 0)
	mesh.rotation_degrees = Vector3(0, 0, 8)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "NOTE  [E]"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	label.pixel_size = 0.006
	label.modulate = Color(1, 0.95, 0.7)
	label.outline_size = 8
	add_child(label)


func get_label() -> String:
	return "Read Note"


func interact() -> void:
	Notes.read(self)
