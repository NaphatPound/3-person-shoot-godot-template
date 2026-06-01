extends Node3D
class_name ExtractionZone
## The escape pad. Dim/locked until Extraction opens it, then glows green ("GO!"). Joins group
## "extraction". Visual only — the Extraction autoload drives its state and checks the player's distance.

var _mat: StandardMaterial3D
var _label: Label3D


func _ready() -> void:
	add_to_group(&"extraction")
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.2
	cyl.height = 0.12
	mesh.mesh = cyl
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.3, 0.5, 0.4, 0.5)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = _mat
	mesh.position = Vector3(0, 0.07, 0)
	add_child(mesh)

	_label = Label3D.new()
	_label.text = "EXTRACTION (locked)"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 1.5, 0)
	_label.pixel_size = 0.007
	_label.outline_size = 8
	_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(_label)


func set_open(v: bool) -> void:
	if _mat:
		_mat.albedo_color = Color(0.3, 1.0, 0.4, 0.6) if v else Color(0.3, 0.5, 0.4, 0.5)
		_mat.emission_enabled = v
		_mat.emission = Color(0.2, 1.0, 0.4)
		_mat.emission_energy_multiplier = 2.0 if v else 0.0
	if _label:
		_label.text = "EXTRACTION — GO!" if v else "EXTRACTION (locked)"
		_label.modulate = Color(0.5, 1.0, 0.6) if v else Color(0.7, 0.7, 0.7)
