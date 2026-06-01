extends CanvasLayer
## InteractPrompt (autoload) — a single centered prompt above the bottom edge ("[E]  Pick up  …"),
## on its own CanvasLayer so it never touches the existing HUD (scenes/hud.tscn). Shown/hidden only
## by the Interaction autoload.

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 18
	_build()
	hide_prompt()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_top = -98
	_panel.offset_bottom = -64
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.62)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	_panel.add_theme_stylebox_override("panel", sb)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_panel.add_child(_label)


func show_prompt(text: String) -> void:
	if _label:
		_label.text = text
	if _panel:
		_panel.visible = true


func hide_prompt() -> void:
	if _panel:
		_panel.visible = false
