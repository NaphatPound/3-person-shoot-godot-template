extends CanvasLayer
## AmmoHUD (autoload) — magazine / reserve counter (bottom-right, above the controls strip) on its own
## CanvasLayer so it never touches the existing HUD. Reactive to the Ammo autoload; turns red on empty,
## amber while reloading.

var _ammo_label: Label
var _hint: Label


func _ready() -> void:
	layer = 21
	_build()
	Ammo.changed.connect(_refresh)
	Ammo.reload_started.connect(_refresh)
	Ammo.reloaded.connect(_refresh)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -230
	panel.offset_top = -96
	panel.offset_right = -16
	panel.offset_bottom = -40
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.5)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	_ammo_label = Label.new()
	_ammo_label.add_theme_font_size_override("font_size", 28)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_ammo_label)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_hint)


func _refresh() -> void:
	if _ammo_label == null:
		return
	_ammo_label.text = "%d / %d" % [Ammo.magazine, Ammo.reserve()]
	if Ammo.is_reloading():
		_hint.text = "RELOADING..."
		_hint.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
		_ammo_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif Ammo.magazine == 0:
		_hint.text = "EMPTY   [R]"
		_hint.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		_ammo_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		_hint.text = "[R] Reload"
		_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		_ammo_label.add_theme_color_override("font_color", Color(1, 1, 1))
