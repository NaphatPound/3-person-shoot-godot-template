extends CanvasLayer
## ScoreHUD (autoload) — a small top-left readout (below the noise bar): current score + best. Reactive
## to the Score autoload; own CanvasLayer; touches no existing node.

var _label: Label


func _ready() -> void:
	layer = 20
	_build()
	Score.changed.connect(_on_changed)
	_on_changed(Score.current, Score.high)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.offset_left = 18
	_label.offset_top = 210
	_label.offset_right = 288
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	root.add_child(_label)


func _on_changed(cur: int, hi: int) -> void:
	if _label:
		_label.text = "Score  %d   ·   Best  %d" % [cur, hi]
