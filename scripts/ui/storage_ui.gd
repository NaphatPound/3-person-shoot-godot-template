extends CanvasLayer
## StorageUI (autoload) — RE-style item box. Near a StoragePoint (group "storage") a "[G] Storage" hint
## shows; [G] opens a BAG | STORAGE screen (pauses) to move items across one at a time. Built in code,
## own [G] action, seeds one StoragePoint into the World scene (scene_file_path gate). PROCESS_MODE_ALWAYS
## + re-asserts pause so it co-exists with the other menus. Touches no existing node.

@export var reach := 3.2
const WORLD_SCENE := "res://scenes/world.tscn"

var _open := false
var _root: Control
var _hint: Label
var _shop: Control
var _bag_list: VBoxContainer
var _store_list: VBoxContainer
var _status: Label
var _saved_mouse := Input.MOUSE_MODE_VISIBLE
var _seeded: Node = null


func _enter_tree() -> void:
	if not InputMap.has_action(&"storage"):
		InputMap.add_action(&"storage")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_G
		InputMap.action_add_event(&"storage", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 48
	_build()
	_shop.visible = false
	_hint.visible = false
	Storage.changed.connect(func(): if _open: _refresh())
	Inventory.changed.connect(func(): if _open: _refresh())


func _process(_delta: float) -> void:
	_maybe_seed()
	if _open:
		if not get_tree().paused:
			get_tree().paused = true
		return
	if get_tree().paused:
		_hint.visible = false
		return
	_hint.visible = _point_in_range() != null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"storage"):
		if _open:
			_set_open(false)
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and _point_in_range() != null:
			_set_open(true)
			get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func _point_in_range() -> Node3D:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return null
	for m in get_tree().get_nodes_in_group(&"storage"):
		if m is Node3D and is_instance_valid(m):
			if player.global_position.distance_to((m as Node3D).global_position) <= reach:
				return m
	return null


func _set_open(v: bool) -> void:
	_open = v
	_shop.visible = v
	if v:
		_hint.visible = false
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
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	_hint.text = "[G]  Open Storage"
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -132
	_hint.offset_bottom = -108
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hint)

	_shop = Control.new()
	_shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_shop)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 460)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "ITEM BOX"
	vb.add_child(title)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)
	cols.add_child(_make_column("BAG", true))
	cols.add_child(_make_column("STORAGE", false))

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	vb.add_child(_status)

	var hint2 := Label.new()
	hint2.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint2.text = "[G] / [Esc] close"
	vb.add_child(hint2)


func _make_column(caption: String, is_bag: bool) -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(290, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := Label.new()
	h.add_theme_font_size_override("font_size", 18)
	h.text = caption
	col.add_child(h)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	col.add_child(list)
	if is_bag:
		_bag_list = list
	else:
		_store_list = list
	return col


func _refresh() -> void:
	if not _open:
		return
	for c in _bag_list.get_children():
		_bag_list.remove_child(c)
		c.queue_free()
	var seen := {}
	for slot in Inventory.get_slots():
		if slot == null:
			continue
		var id: StringName = slot["id"]
		if seen.has(id):
			continue
		seen[id] = true
		_bag_list.add_child(_row(id, Inventory.count_of(id), "Deposit  >", _on_deposit))

	for c in _store_list.get_children():
		_store_list.remove_child(c)
		c.queue_free()
	for e in Storage.entries():
		_store_list.add_child(_row(e["id"], e["count"], "<  Withdraw", _on_withdraw))


func _row(id: StringName, count: int, btn_text: String, handler: Callable) -> Control:
	var row := HBoxContainer.new()
	var it: Item = ItemDB.get_item(id)
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(175, 0)
	lbl.clip_text = true
	lbl.text = "%s x%d" % [it.name if it else String(id), count]
	row.add_child(lbl)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 0)
	btn.text = btn_text
	btn.pressed.connect(handler.bind(id))
	row.add_child(btn)
	return row


func _on_deposit(id: StringName) -> void:
	if Inventory.has(id, 1):
		Inventory.remove(id, 1)
		if Storage.store(id, 1) > 0:
			Inventory.add(id, 1)   # box full -> refund
			_status.text = "Storage is full."
		else:
			_status.text = "Deposited %s." % _name(id)
	_refresh()


func _on_withdraw(id: StringName) -> void:
	if Storage.count_of(id) >= 1 and Storage.take(id, 1) > 0:
		if Inventory.add(id, 1) > 0:
			Storage.store(id, 1)   # bag full -> refund
			_status.text = "Your bag is full."
		else:
			_status.text = "Withdrew %s." % _name(id)
	_refresh()


func _name(id: StringName) -> String:
	var it: Item = ItemDB.get_item(id)
	return it.name if it else String(id)


func _maybe_seed() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded:
		return
	_seeded = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	var p := StoragePoint.new()
	p.position = Vector3(4.0, 0.0, 1.0)
	scene.add_child(p)
