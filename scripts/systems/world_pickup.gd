extends Node3D
class_name WorldPickup
## A lootable item lying in the world ("คาบของ"). Set `item_id` + `amount` (in the editor or in code);
## it self-builds a spinning emissive marker + a floating billboard label and joins group "pickup" so
## the Interaction autoload can find it. interact() moves the items into the Inventory, leaving any that
## don't fit (full bag) on the ground. Reusable: drop one into any scene, or let Interaction seed them.

signal picked(id: StringName, count: int)

@export var item_id: StringName = &"scrap"
@export var amount: int = 1
@export var spin_speed := 1.5

var _label: Label3D


func _ready() -> void:
	add_to_group(&"pickup")
	_build_visual()
	_refresh_label()


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 0.35, 0.35)
	mesh.mesh = box
	var col := _color_for(item_id)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.2, 0)
	add_child(mesh)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 0.78, 0)
	_label.pixel_size = 0.006
	_label.outline_size = 8
	add_child(_label)


## Display name + count, used by the marker label and the interaction prompt.
func get_label() -> String:
	var item: Item = ItemDB.get_item(item_id)
	var nm := item.name if item else String(item_id)
	return "%s x%d" % [nm, amount] if amount > 1 else nm


func _refresh_label() -> void:
	if _label:
		_label.text = get_label()


func interact() -> void:
	var leftover := Inventory.add(item_id, amount)
	var taken := amount - leftover
	if taken > 0:
		picked.emit(item_id, taken)
	amount = leftover
	if amount <= 0:
		queue_free()
	else:
		_refresh_label()   # bag was full — leave the remainder on the ground


func _color_for(id: StringName) -> Color:
	var item: Item = ItemDB.get_item(id)
	if item == null:
		return Color(0.7, 0.7, 0.7)
	match item.category:
		Item.Category.WEAPON: return Color(0.9, 0.55, 0.2)
		Item.Category.AMMO: return Color(0.8, 0.8, 0.4)
		Item.Category.HEAL: return Color(0.3, 0.9, 0.45)
		Item.Category.FOOD: return Color(0.85, 0.6, 0.3)
		Item.Category.MATERIAL: return Color(0.6, 0.6, 0.7)
		Item.Category.VALUABLE: return Color(0.35, 0.65, 1.0)
		_: return Color(0.7, 0.7, 0.7)
