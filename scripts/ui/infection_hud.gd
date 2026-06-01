extends Node
## InfectionHUD (autoload) — infection meter (bottom-left) + stage label + [V] hint, and a faint green
## "sickness" tint on layer -1 that grows with the level (darkens the 3D, not the UI). Reactive to the
## Infection autoload across two CanvasLayers; touches no existing node.

var _bar: ProgressBar
var _label: Label
var _tint: ColorRect


func _ready() -> void:
	_build()
	Infection.changed.connect(_on_changed)
	Infection.stage_changed.connect(func(_s): _refresh())
	_refresh()


func _build() -> void:
	var tl := CanvasLayer.new()
	tl.layer = -1
	add_child(tl)
	_tint = ColorRect.new()
	_tint.color = Color(0.2, 0.5, 0.2, 0.0)
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(_tint)

	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.offset_left = 18
	box.offset_top = -104
	box.offset_bottom = -42
	box.offset_right = 250
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	box.add_child(_label)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(220, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.75, 0.3)
	fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", bg)
	box.add_child(_bar)

	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.text = "[V] Antidote"
	box.add_child(hint)


func _on_changed(level: float) -> void:
	if _bar:
		_bar.value = level
	if _tint:
		_tint.color.a = (level / 100.0) * 0.18
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	_label.text = "INFECTION   [%s]" % Infection.stage_name()
	var col := Color(0.6, 0.9, 0.5)
	match Infection.stage():
		Infection.Stage.INFECTED:
			col = Color(0.9, 0.8, 0.3)
		Infection.Stage.CRITICAL:
			col = Color(1, 0.35, 0.35)
	_label.add_theme_color_override("font_color", col)
