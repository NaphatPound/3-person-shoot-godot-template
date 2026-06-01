extends CanvasLayer
## FlashlightHUD (autoload) — a small bottom-left readout (above the infection meter): light on/off +
## battery % + spare Battery count + the [L] hint. Reactive to Flashlight + Inventory. Own CanvasLayer.

var _label: Label


func _ready() -> void:
	layer = 20
	_build()
	Flashlight.changed.connect(_refresh)
	Inventory.changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label.offset_left = 18
	_label.offset_right = 320
	_label.offset_top = -134
	_label.offset_bottom = -110
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)


func _refresh(_a = null) -> void:
	if _label == null:
		return
	var st := "ON" if Flashlight.on else "OFF"
	_label.text = "[L] Light: %s  %d%%   ·   Battery x%d" % [st, int(round(Flashlight.battery)), Inventory.count_of(&"battery")]
	var col := Color(1, 1, 1, 0.55)
	if Flashlight.battery <= 20.0:
		col = Color(1, 0.4, 0.4)
	elif Flashlight.on:
		col = Color(1, 0.95, 0.6)
	_label.add_theme_color_override("font_color", col)
