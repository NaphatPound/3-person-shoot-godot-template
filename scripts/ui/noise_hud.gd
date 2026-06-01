extends CanvasLayer
## NoiseHUD (autoload) — a noise/aggro bar at top-left (below the companion line). Reddens + shows
## [LOUD] past the threshold. Reactive to the Noise autoload; own CanvasLayer; touches no existing node.

var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	layer = 20
	_build()
	NoiseMeter.changed.connect(_on_changed)
	_on_changed(NoiseMeter.level)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.offset_left = 18
	box.offset_top = 176
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
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(220, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.7, 0.3)
	fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", bg)
	box.add_child(_bar)


func _on_changed(level: float) -> void:
	var loud := NoiseMeter.is_loud()
	if _bar:
		_bar.value = level
		_bar.modulate = Color(1, 0.55, 0.55) if loud else Color(1, 1, 1)
	if _label:
		_label.text = "NOISE" + ("   [LOUD]" if loud else "")
		_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4) if loud else Color(1, 1, 1, 0.8))
