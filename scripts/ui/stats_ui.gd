extends CanvasLayer
## StatsUI (autoload) — [Y] toggles a stats + achievements panel (pauses). Shows live counters (incl.
## Traps.kills / Companions.assists) and each achievement locked/unlocked, and pops a brief toast when
## one unlocks. Built in code; own [Y] action; PROCESS_MODE_ALWAYS + re-asserts pause. Touches nothing.

var _open := false
var _root: Control
var _list: VBoxContainer
var _toast: Label
var _toast_t := 0.0
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	if not InputMap.has_action(&"stats"):
		InputMap.add_action(&"stats")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_Y
		InputMap.action_add_event(&"stats", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 49
	_build()
	_root.visible = false
	Stats.changed.connect(func(): if _open: _refresh())
	Stats.achievement_unlocked.connect(_on_unlock)


func _process(delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"stats"):
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
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "STATS & ACHIEVEMENTS"
	vb.add_child(title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	vb.add_child(_list)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[Y] / [Esc] close"
	vb.add_child(hint)

	# unlock toast (top-center, below the save toast)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 80
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	_toast.visible = false
	add_child(_toast)


func _refresh() -> void:
	if not _open:
		return
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_add_line("Shots fired:   %d" % Stats.get_stat("shots"))
	_add_line("Zombie hits:   %d" % Stats.get_stat("hits"))
	_add_line("Items gained:   %d" % Stats.get_stat("items"))
	_add_line("Gold earned:   %d" % Stats.get_stat("gold_earned"))
	_add_line("Quests done:   %d" % Stats.get_stat("quests"))
	_add_line("Items crafted:   %d" % Stats.get_stat("crafted"))
	_add_line("Trap kills:   %d      Ally assists:   %d" % [Traps.kills, Companions.assists])

	_list.add_child(HSeparator.new())
	var h := Label.new()
	h.add_theme_font_size_override("font_size", 16)
	h.text = "ACHIEVEMENTS  (%d/%d)" % [Stats.unlocked_count(), Stats.ACHIEVEMENTS.size()]
	_list.add_child(h)
	for a in Stats.ACHIEVEMENTS:
		var done: bool = Stats.is_unlocked(a["id"])
		var l := Label.new()
		l.text = ("[x] " if done else "[ ] ") + a["title"] + "  —  " + a["desc"]
		l.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6) if done else Color(1, 1, 1, 0.7))
		_list.add_child(l)


func _add_line(t: String) -> void:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 14)
	l.text = t
	_list.add_child(l)


func _on_unlock(_id: StringName, title: String) -> void:
	_toast.text = "Achievement unlocked:  " + title
	_toast.visible = true
	_toast_t = 2.5
