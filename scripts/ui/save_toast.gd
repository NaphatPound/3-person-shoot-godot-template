extends CanvasLayer
## SaveToast (autoload) — a brief centered-top "GAME SAVED / LOADED" banner driven by SaveSystem.
## Own CanvasLayer, PROCESS_MODE_ALWAYS (so it shows even if save is triggered from a paused menu).

var _panel: PanelContainer
var _label: Label
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_build()
	_panel.visible = false
	SaveSystem.saved.connect(func(): _show("GAME SAVED"))
	SaveSystem.loaded.connect(func(): _show("GAME LOADED"))
	SaveSystem.load_failed.connect(func(): _show("NO SAVE FOUND"))


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_top = 24
	_panel.offset_bottom = 60
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.8, 1, 0.85))
	_panel.add_child(_label)


func _show(text: String) -> void:
	_label.text = text
	_panel.visible = true
	_t = 1.6


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			_panel.visible = false
