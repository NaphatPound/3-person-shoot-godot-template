extends CanvasLayer
## CratesToast (autoload) — a brief centered banner for crate feedback ("Locked — need a Lockpick" /
## "Crate opened!"). Own CanvasLayer, PROCESS_MODE_ALWAYS; reactive to Crates. Touches no existing node.

var _panel: PanelContainer
var _label: Label
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 55
	_build()
	_panel.visible = false
	Crates.locked_attempt.connect(func(): _show("Locked — you need a Lockpick"))
	Crates.changed.connect(func(): _show("Crate opened!"))


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_top = 184
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.72)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	_panel.add_child(_label)


func _show(text: String) -> void:
	_label.text = text
	_panel.visible = true
	_t = 2.0


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_panel.visible = false
