extends CanvasLayer
## DifficultyHUD (autoload) — a small top-center readout (below the weather label): the day, tier name,
## and current multiplier, tinted by tier. Reactive to the Difficulty autoload; own CanvasLayer.

var _label: Label


func _ready() -> void:
	layer = 17
	_build()
	Difficulty.changed.connect(func(_d, _m): _refresh())
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 70
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)


func _refresh() -> void:
	if _label == null:
		return
	_label.text = "DIFFICULTY:  Day %d — %s  x%.2f" % [Difficulty.day(), Difficulty.tier_name(), Difficulty.multiplier()]
	var d := Difficulty.day()
	var col := Color(0.6, 0.9, 0.6)
	if d >= 4:
		col = Color(1, 0.4, 0.4)
	elif d == 3:
		col = Color(1, 0.6, 0.3)
	elif d == 2:
		col = Color(0.95, 0.85, 0.4)
	_label.add_theme_color_override("font_color", col)
