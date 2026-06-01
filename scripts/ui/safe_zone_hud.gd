extends CanvasLayer
## SafeZoneHUD (autoload) — a centered "+ SAFE ZONE — recovering" indicator shown only while the player
## is inside a safe room. Reactive to SafeZones; own CanvasLayer; touches no existing node.

var _label: Label


func _ready() -> void:
	layer = 22
	_build()
	_label.visible = false
	SafeZones.inside_changed.connect(_on_inside)
	_label.visible = SafeZones.is_inside()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 274
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = "+ SAFE ZONE — recovering"
	root.add_child(_label)


func _on_inside(inside: bool) -> void:
	if _label:
		_label.visible = inside
