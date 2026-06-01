extends Node
## Flashlight (autoload) — a toggleable spotlight ([L]) attached to the camera at runtime. Drains a
## battery while on; trickle-regens while off; auto-off when empty. A Battery item (buyable/craftable)
## instantly refills it (auto-used when you switch on with a dead battery). Adds a SpotLight3D as a child
## of the active camera — additive, edits no existing node. Most useful at NIGHT / in FOG.

signal changed

@export var drain := 7.0       ## battery/sec while on
@export var regen := 2.5       ## battery/sec while off (slow trickle)

var on := false
var battery := 100.0
var _light: SpotLight3D = null


func _enter_tree() -> void:
	if not InputMap.has_action(&"flashlight"):
		InputMap.add_action(&"flashlight")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_L
		InputMap.action_add_event(&"flashlight", e)


func _ready() -> void:
	ItemDB.register(Item.make(&"battery", "Battery", Item.Category.MATERIAL, 9, 40, "Recharges the flashlight."))
	Merchant.stock.append({ "id": &"battery", "price": 50 })
	Crafting.recipes.append({
		"id": &"r_battery", "name": "Battery",
		"inputs": { &"scrap": 2 }, "out": &"battery", "count": 1,
	})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"flashlight"):
		toggle()


func _process(delta: float) -> void:
	if _light == null or not is_instance_valid(_light):
		var cam := get_viewport().get_camera_3d()
		if cam:
			_light = SpotLight3D.new()
			_light.light_energy = 4.0
			_light.spot_range = 18.0
			_light.spot_angle = 35.0
			cam.add_child(_light)
	if on:
		battery = maxf(0.0, battery - drain * delta)
		if battery <= 0.0:
			on = false
	else:
		battery = minf(100.0, battery + regen * delta)
	if _light:
		_light.visible = on
	changed.emit()


func toggle() -> void:
	if on:
		on = false
	else:
		if battery <= 0.0 and not recharge():
			changed.emit()
			return
		on = true
	changed.emit()


func recharge() -> bool:
	if Inventory.has(&"battery", 1):
		Inventory.remove(&"battery", 1)
		battery = 100.0
		return true
	return false
