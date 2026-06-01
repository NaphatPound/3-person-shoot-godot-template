extends CanvasLayer
## CompanionHUD (autoload) — a small top-left readout (below the stamina bar): ally on/off + assist
## kills + the [K] hint. Reactive to Companions. Own CanvasLayer; touches no existing node.

var _label: Label


func _ready() -> void:
	layer = 20
	_build()
	Companions.changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.offset_left = 18
	_label.offset_top = 154
	_label.offset_right = 268
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	root.add_child(_label)


func _refresh() -> void:
	if _label:
		_label.text = "[K] Ally: %s   ·   Assists %d" % ["ON" if Companions.is_active() else "OFF", Companions.assists]
