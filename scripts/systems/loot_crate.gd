extends WorldPickup
class_name LootCrateNode
## A locked loot crate. EXTENDS WorldPickup so the existing Interaction system ([E]) detects it with no
## changes, but opening requires a Lockpick item (consumed). On open it grants its preset `loot`. Set
## `loot` before adding it to a scene. Overrides the pickup visual/label/interact.

var loot: Array = [ { "id": &"ammo_9mm", "amount": 10 } ]


func _ready() -> void:
	add_to_group(&"pickup")
	spin_speed = 0.0          # crates don't spin like loose loot
	_build_crate_visual()


func get_label() -> String:
	return "Locked Crate (needs Lockpick)"


func interact() -> void:
	if not Inventory.has(&"lockpick", 1):
		Crates.report_locked()
		return
	Inventory.remove(&"lockpick", 1)
	for entry in loot:
		Inventory.add(entry["id"], int(entry["amount"]))
	Crates.report_opened()
	queue_free()


func _build_crate_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.6, 0.7)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.32, 0.38)
	mat.metallic = 0.6
	mat.roughness = 0.4
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.3, 0)
	add_child(mesh)

	var label := Label3D.new()
	label.text = "LOCKED"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.95, 0)
	label.pixel_size = 0.006
	label.modulate = Color(1, 0.7, 0.4)
	label.outline_size = 8
	add_child(label)
