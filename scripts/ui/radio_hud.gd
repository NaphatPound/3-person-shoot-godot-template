extends CanvasLayer
## RadioHUD (autoload) — a bottom-center ticker showing the latest Radio broadcast for a few seconds.
## Own CanvasLayer; touches no existing node.

var _label: Label
var _t := 0.0


func _ready() -> void:
	layer = 16
	_build()
	_label.visible = false
	Radio.broadcast.connect(_on_broadcast)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_top = -54
	_label.offset_bottom = -34
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.7, 0.95, 0.8))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)


func _on_broadcast(text: String) -> void:
	_label.text = "[RADIO]  " + text
	_label.visible = true
	_t = 6.0


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_label.visible = false
