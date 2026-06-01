extends CanvasLayer
## RescueToast (autoload) — a brief upper-middle banner when a survivor is rescued. Own CanvasLayer,
## PROCESS_MODE_ALWAYS; touches no existing node.

var _label: Label
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 53
	_build()
	_label.visible = false
	Rescues.rescued_one.connect(_on_rescue)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 250
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)


func _on_rescue(reward: int) -> void:
	_label.text = "SURVIVOR RESCUED  +%dg" % reward
	_label.visible = true
	_t = 2.0


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_label.visible = false
