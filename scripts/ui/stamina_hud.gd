extends CanvasLayer
## StaminaHUD (autoload) — a sprint-stamina bar at top-left, just below the survival bars. Label shows
## [SPRINT]/[EXHAUSTED]; the bar reddens when exhausted. Reactive to the Stamina autoload; own
## CanvasLayer; touches no existing node.

var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	layer = 20
	_build()
	Stamina.changed.connect(_on_changed)
	Stamina.sprint_changed.connect(func(_s): _refresh())
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.offset_left = 18
	box.offset_top = 116
	box.offset_right = 246
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	box.add_child(_label)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.value = 100.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(220, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.6, 0.9)
	fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", bg)
	box.add_child(_bar)


func _on_changed(s: float) -> void:
	if _bar:
		_bar.value = s
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	var t := "STAMINA"
	if Stamina.is_exhausted():
		t += "   [EXHAUSTED]"
	elif Stamina.is_sprinting():
		t += "   [SPRINT]"
	_label.text = t
	_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4) if Stamina.is_exhausted() else Color(1, 1, 1, 0.8))
	if _bar:
		_bar.modulate = Color(1, 0.55, 0.55) if Stamina.is_exhausted() else Color(1, 1, 1)
