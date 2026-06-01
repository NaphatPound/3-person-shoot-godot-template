extends CanvasLayer
## CraftingUI (autoload) — toggle [C]; pauses the game. Lists recipes (inputs -> output) with a Craft
## button that's disabled when materials are short. Built in code, registers its own [C] action, touches
## no existing node. PROCESS_MODE_ALWAYS + re-asserts pause so it co-exists with the other screens.

var _open := false
var _root: Control
var _list: VBoxContainer
var _status: Label
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	if not InputMap.has_action(&"craft"):
		InputMap.add_action(&"craft")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_C
		InputMap.action_add_event(&"craft", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 47
	_build()
	_root.visible = false
	Crafting.changed.connect(func(): if _open: _refresh())
	Inventory.changed.connect(func(): if _open: _refresh())


func _process(_delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"craft"):
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
	panel.custom_minimum_size = Vector2(600, 0)
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
	title.text = "CRAFTING"
	vb.add_child(title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	vb.add_child(_list)

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	vb.add_child(_status)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[C] / [Esc] close"
	vb.add_child(hint)


func _refresh() -> void:
	if not _open:
		return
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for r in Crafting.get_recipes():
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(440, 0)
		lbl.text = _io_text(r)
		row.add_child(lbl)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(110, 0)
		btn.text = "Craft"
		btn.disabled = not Crafting.can_craft(r)
		btn.pressed.connect(_on_craft.bind(r))
		row.add_child(btn)
		_list.add_child(row)


func _on_craft(r: Dictionary) -> void:
	if Crafting.craft(r):
		_status.text = "Crafted %s." % r["name"]
	else:
		_status.text = "Can't craft %s — missing materials or full bag." % r["name"]
	_refresh()


func _io_text(r: Dictionary) -> String:
	var ins := []
	for id in r["inputs"]:
		var it: Item = ItemDB.get_item(id)
		ins.append("%d %s" % [int(r["inputs"][id]), it.name if it else String(id)])
	var out: Item = ItemDB.get_item(r["out"])
	var out_name := out.name if out else String(r["out"])
	return "%s   ->   %s x%d" % [" + ".join(ins), out_name, int(r["count"])]
