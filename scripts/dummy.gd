class_name TargetDummy
extends StaticBody3D
## A shootable target. Lives on the "dummy" physics layer (4) and the "dummy" group; flashes red when
## the player's hit-scan ray calls on_hit().

@onready var _mesh: MeshInstance3D = $Mesh

var _mat: StandardMaterial3D
var _flash := 0.0
const BASE := Color(0.80, 0.76, 0.62)
const HIT := Color(1.0, 0.22, 0.22)


func _ready() -> void:
	add_to_group("dummy")
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = BASE
	if _mesh:
		_mesh.material_override = _mat


func on_hit() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - 2.5 * delta)
		_mat.albedo_color = BASE.lerp(HIT, _flash)
