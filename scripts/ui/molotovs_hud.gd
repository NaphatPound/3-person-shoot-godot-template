extends CanvasLayer
## MolotovsHUD (autoload) — a small bottom-right readout (above the grenade line): held molotovs + the
## [Q] hint + burn kills. Reactive to Molotovs + Inventory. Own CanvasLayer; touches no existing node.

var _label: Label


func _ready() -> void:
	layer = 21
	_build()
	Molotovs.changed.connect(_refresh)
	Inventory.changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.offset_left = -300
	_label.offset_right = -16
	_label.offset_top = -208
	_label.offset_bottom = -184
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", Color(1, 0.55, 0.35))
	root.add_child(_label)


func _refresh(_a = null) -> void:
	if _label:
		_label.text = "[Q] Molotov x%d   ·   Burned %d" % [Molotovs.held(), Molotovs.kills]
