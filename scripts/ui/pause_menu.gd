extends CanvasLayer
## PauseMenu (autoload) — [F2] toggles a centered pause menu (Resume / Save / Load / Quit) and pauses the
## tree. Save/Load call SaveSystem's public API (so they also trigger SaveExtra). Built in code; own [F2]
## action; PROCESS_MODE_ALWAYS + re-asserts pause. Touches no existing node.

var _open := false
var _root: Control
var _status: Label
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	if not InputMap.has_action(&"pause_menu"):
		InputMap.add_action(&"pause_menu")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_F2
		InputMap.action_add_event(&"pause_menu", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 58
	_build()
	_root.visible = false


func _process(_delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		toggle()
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open


func toggle() -> void:
	_set_open(not _open)


func _set_open(v: bool) -> void:
	_open = v
	_root.visible = v
	if v:
		_saved_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_status.text = ""
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
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	vb.add_child(_make_btn("Resume", _on_resume))
	vb.add_child(_make_btn("Save Game  [F5]", _on_save))
	vb.add_child(_make_btn("Load Game  [F9]", _on_load))
	vb.add_child(_make_btn("Quit to Desktop", _on_quit))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color(0.8, 1, 0.85))
	vb.add_child(_status)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[F2] / [Esc] close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)


func _make_btn(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 36)
	b.pressed.connect(handler)
	return b


func _on_resume() -> void:
	_set_open(false)


func _on_save() -> void:
	_status.text = "Game saved." if SaveSystem.save_game() else "Save failed."


func _on_load() -> void:
	_status.text = "Game loaded." if SaveSystem.load_game() else "No save found."


func _on_quit() -> void:
	get_tree().quit()
