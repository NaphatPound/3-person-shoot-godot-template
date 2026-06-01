extends CanvasLayer
## NotesUI (autoload) — shows a collected lore note (title + body + progress), pauses; closes on [Esc].
## (Closes only on Esc, not [E], so the same key-press that opened it can't instantly close it.) Built in
## code; PROCESS_MODE_ALWAYS + re-asserts pause. Touches no existing node.

var _open := false
var _root: Control
var _title: Label
var _body: Label
var _count: Label
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 51
	_build()
	_root.visible = false
	Notes.opened.connect(_on_opened)


func _process(_delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func _on_opened(title: String, body: String) -> void:
	_title.text = title
	_body.text = body
	_count.text = "Note %d of %d" % [Notes.collected, Notes.total()]
	_set_open(true)


func _set_open(v: bool) -> void:
	_open = v
	_root.visible = v
	if v:
		_saved_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
	else:
		get_tree().paused = false
		Input.mouse_mode = _saved_mouse


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	vb.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(470, 0)
	vb.add_child(_body)

	_count = Label.new()
	_count.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	vb.add_child(_count)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[Esc] close"
	vb.add_child(hint)
