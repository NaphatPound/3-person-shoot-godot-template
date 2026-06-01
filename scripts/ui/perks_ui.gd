extends CanvasLayer
## PerksUI (autoload) — [P] toggles a perks panel (pauses). Shows Skill Points and each perk with its
## cost and an Unlock button (OWNED once bought). Pops a toast when an SP is earned. Built in code; own
## [P] action; PROCESS_MODE_ALWAYS + re-asserts pause. Touches no existing node.

var _open := false
var _root: Control
var _sp_label: Label
var _list: VBoxContainer
var _toast: Label
var _toast_t := 0.0
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	if not InputMap.has_action(&"perks"):
		InputMap.add_action(&"perks")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_P
		InputMap.action_add_event(&"perks", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 49
	_build()
	_root.visible = false
	Perks.changed.connect(func(): if _open: _refresh())
	Perks.sp_gained.connect(func(_t): _show_toast("Skill Point earned!"))


func _process(delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"perks"):
		if _open or not get_tree().paused:
			_set_open(not _open)
			get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func _set_open(v: bool) -> void:
	_open = v
	_root.visible = v
	if v:
		_saved_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh()
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
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "PERKS"
	vb.add_child(title)

	_sp_label = Label.new()
	_sp_label.add_theme_font_size_override("font_size", 18)
	_sp_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	vb.add_child(_sp_label)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	vb.add_child(_list)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[P] / [Esc] close   ·   earn Skill Points from achievements"
	vb.add_child(hint)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 110
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	_toast.visible = false
	add_child(_toast)


func _refresh() -> void:
	if not _open:
		return
	_sp_label.text = "Skill Points:  %d" % Perks.sp
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for p in Perks.PERKS:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(400, 0)
		lbl.text = "%s  —  %s" % [p["name"], p["desc"]]
		row.add_child(lbl)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 0)
		if Perks.is_unlocked(p["id"]):
			btn.text = "OWNED"
			btn.disabled = true
		else:
			btn.text = "Unlock (%d)" % int(p["cost"])
			btn.disabled = Perks.sp < int(p["cost"])
			btn.pressed.connect(_on_unlock.bind(p["id"]))
		row.add_child(btn)
		_list.add_child(row)


func _on_unlock(id: StringName) -> void:
	Perks.unlock(id)
	_refresh()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_t = 2.0
