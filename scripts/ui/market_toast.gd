extends CanvasLayer
## MarketToast (autoload) — a brief upper-middle banner when the Market drifts prices on a new day.
## Own CanvasLayer, PROCESS_MODE_ALWAYS; touches no existing node.

var _panel: PanelContainer
var _label: Label
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 54
	_build()
	_panel.visible = false
	Market.drifted.connect(_on_drift)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_top = 158
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.05, 0.72)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.6))
	_panel.add_child(_label)


func _on_drift(day: int) -> void:
	if day <= 1:
		return                    # skip the start-of-game apply
	_label.text = "MARKET PRICES SHIFTED · Day %d" % day
	_panel.visible = true
	_t = 2.5


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_panel.visible = false
