class_name Gun
extends Node3D
## A simple procedural pistol built from a few boxes, plus a muzzle Marker3D and a muzzle-flash light.
## Designed to be parented to a BoneAttachment3D on the character's right hand. Local axes: the barrel
## points along +Z (the model's forward), the grip hangs down -Y. Swap this node for a real gun model
## later — just keep a child named "Muzzle".

var muzzle: Marker3D            # set in _build_mesh (created procedurally, so no @onready)

var _flash: OmniLight3D
var _flash_tween: Tween


func _ready() -> void:
	_build_mesh()


func _build_mesh() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.07, 0.07, 0.08)
	metal.metallic = 0.9
	metal.roughness = 0.35

	# slide / barrel body — long axis along +Z
	_box(Vector3(0.045, 0.075, 0.26), Vector3(0.0, 0.0, 0.10), metal)
	# lower frame
	_box(Vector3(0.04, 0.04, 0.16), Vector3(0.0, -0.055, 0.05), metal)
	# grip — angled down/back
	var grip := _box(Vector3(0.042, 0.13, 0.05), Vector3(0.0, -0.12, -0.04), metal)
	grip.rotation.x = deg_to_rad(-16.0)

	# muzzle point at the front of the barrel
	var m := Marker3D.new()
	m.name = "Muzzle"
	m.position = Vector3(0.0, 0.012, 0.24)
	add_child(m)
	muzzle = m

	# muzzle flash light (additive-looking warm pulse; energy starts at 0)
	_flash = OmniLight3D.new()
	_flash.name = "MuzzleFlash"
	_flash.light_color = Color(1.0, 0.85, 0.5)
	_flash.omni_range = 3.0
	_flash.light_energy = 0.0
	m.add_child(_flash)


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


## Kick the muzzle flash for a moment (one active tween at a time).
func flash() -> void:
	if _flash == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.light_energy = 4.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "light_energy", 0.0, 0.06)
