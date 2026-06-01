extends CanvasLayer
## AmmoBoxToast (autoload) — a brief "+N rounds" pop when an ammo box is grabbed. Own CanvasLayer,
## PROCESS_MODE_ALWAYS; touches no existing node.

var _label: Label
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 53
	_build()
	_label.visible = false
	AmmoBoxes.collected_box.connect(_on_collect)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 320
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.5))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)


func _on_collect(amount: int) -> void:
	_label.text = "+%d rounds" % amount
	_label.visible = true
	_t = 1.5


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_label.visible = false
