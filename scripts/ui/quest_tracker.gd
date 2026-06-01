extends CanvasLayer
## QuestTracker (autoload) — an always-on compact quest list (top-right, below the F3 debug block) plus
## a full Quest Log toggled with [J] (pauses). Reactive to the Quests autoload; builds its UI in code,
## registers its own [J] action, touches no existing node. PROCESS_MODE_ALWAYS + re-asserts pause so it
## co-exists with the inventory / merchant / weapon screens.

var _open := false
var _tracker_panel: PanelContainer
var _tracker_list: VBoxContainer
var _log_root: Control
var _log_list: VBoxContainer
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	if not InputMap.has_action(&"quest_log"):
		InputMap.add_action(&"quest_log")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_J
		InputMap.action_add_event(&"quest_log", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 19
	_build()
	_log_root.visible = false
	Quests.changed.connect(_refresh_tracker)
	Quests.quest_completed.connect(func(_id): _refresh_tracker())
	_refresh_tracker()


func _process(_delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quest_log"):
		if _open or not get_tree().paused:
			_set_open(not _open)
			get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func _set_open(v: bool) -> void:
	_open = v
	_log_root.visible = v
	if v:
		_saved_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_log()
		get_tree().paused = true
	else:
		get_tree().paused = false
		Input.mouse_mode = _saved_mouse


func _build() -> void:
	# --- compact always-on tracker (top-right, below the debug block) ---
	var troot := Control.new()
	troot.set_anchors_preset(Control.PRESET_FULL_RECT)
	troot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(troot)

	_tracker_panel = PanelContainer.new()
	_tracker_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tracker_panel.offset_left = -280
	_tracker_panel.offset_top = 168
	_tracker_panel.offset_right = -12
	_tracker_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tracker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	_tracker_panel.add_theme_stylebox_override("panel", sb)
	troot.add_child(_tracker_panel)

	_tracker_list = VBoxContainer.new()
	_tracker_list.add_theme_constant_override("separation", 3)
	_tracker_panel.add_child(_tracker_list)

	# --- full quest-log overlay ---
	_log_root = Control.new()
	_log_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_log_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
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
	title.text = "QUEST LOG"
	vb.add_child(title)

	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 9)
	vb.add_child(_log_list)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[J] / [Esc] close"
	vb.add_child(hint)


func _refresh_tracker() -> void:
	if _tracker_list == null:
		return
	for c in _tracker_list.get_children():
		_tracker_list.remove_child(c)
		c.queue_free()

	var head := Label.new()
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	head.text = "QUESTS   [J]"
	_tracker_list.add_child(head)

	var active := Quests.active_defs()
	if active.is_empty():
		var l := Label.new()
		l.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6))
		l.text = "All quests complete!"
		_tracker_list.add_child(l)
		return
	for d in active:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 13)
		l.text = "- %s  %d/%d" % [d["title"], Quests.progress_of(d["id"]), Quests.target_of(d)]
		_tracker_list.add_child(l)


func _refresh_log() -> void:
	if _log_list == null:
		return
	for c in _log_list.get_children():
		_log_list.remove_child(c)
		c.queue_free()
	for d in Quests.all_defs():
		var done: bool = Quests.is_done(d["id"])
		var row := VBoxContainer.new()
		var t := Label.new()
		t.add_theme_font_size_override("font_size", 17)
		var status := "   (DONE)" if done else "   %d/%d" % [Quests.progress_of(d["id"]), Quests.target_of(d)]
		t.text = ("[x] " if done else "[ ] ") + d["title"] + status
		t.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6) if done else Color(1, 1, 1))
		row.add_child(t)
		var desc := Label.new()
		desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		desc.text = "     %s   Reward: %s" % [d["desc"], _reward_text(d)]
		row.add_child(desc)
		_log_list.add_child(row)


func _reward_text(d: Dictionary) -> String:
	var parts := []
	if d.has("gold"):
		parts.append("%d gold" % int(d["gold"]))
	if d.has("item"):
		var item: Item = ItemDB.get_item(d["item"])
		var nm := item.name if item else String(d["item"])
		parts.append("%s x%d" % [nm, int(d.get("count", 1))])
	return ", ".join(parts) if not parts.is_empty() else "-"
