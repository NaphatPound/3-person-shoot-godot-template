extends CanvasLayer
## InventoryUI (autoload) — an RE4-style "attaché case" overlay, built entirely in code so it sits on
## top of ANY scene without editing the existing HUD or world scenes. Toggle with [I] or [Tab]; the
## game pauses while it's open (this node uses PROCESS_MODE_ALWAYS so it keeps running under pause).
## It registers its own input action, so scripts/game_input.gd is left untouched.

const COLS := 4
const SLOT := Vector2(104, 104)

var _root: Control
var _grid: GridContainer
var _title: Label
var _detail: Label
var _open := false
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	# Register [I]/[Tab] without touching the GameInput autoload.
	if not InputMap.has_action(&"toggle_inventory"):
		InputMap.add_action(&"toggle_inventory")
		for code in [KEY_I, KEY_TAB]:
			var e := InputEventKey.new()
			e.physical_keycode = code
			InputMap.action_add_event(&"toggle_inventory", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build_ui()
	_root.visible = false
	if Inventory.has_signal("changed"):
		Inventory.changed.connect(_refresh)


func _build_ui() -> void:
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
	panel.custom_minimum_size = Vector2(COLS * SLOT.x + 90, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	vb.add_child(_title)

	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(_grid)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(0, 72)
	vb.add_child(_detail)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.text = "[I] / [Tab] close    ·    click an item to inspect"
	vb.add_child(hint)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_inventory"):
		_set_open(not _open)
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func _set_open(v: bool) -> void:
	if v == _open:
		return
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


func _refresh() -> void:
	if not _open or _grid == null:
		return
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var slots := Inventory.get_slots()
	_title.text = "INVENTORY    %d / %d" % [Inventory.used_slots(), slots.size()]
	for i in slots.size():
		_grid.add_child(_make_slot(slots[i]))
	_detail.text = ""


func _make_slot(slot) -> Control:
	var b := Button.new()
	b.custom_minimum_size = SLOT
	b.clip_text = true
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(5)
	if slot == null:
		sb.bg_color = Color(1, 1, 1, 0.05)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("disabled", sb)
		b.disabled = true
		return b
	var item: Item = ItemDB.get_item(slot["id"])
	sb.bg_color = _cat_color(item.category).darkened(0.35)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb.duplicate())
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_color_override("font_color", Color.WHITE)
	var label := item.name
	if slot["count"] > 1:
		label += "\nx%d" % slot["count"]
	b.text = label
	b.pressed.connect(_show_detail.bind(item, slot["count"]))
	return b


func _show_detail(item: Item, count: int) -> void:
	_detail.text = "%s  (x%d)\n%s\nTrade value: %d" % [item.name, count, item.description, item.value]


func _cat_color(cat: int) -> Color:
	match cat:
		Item.Category.WEAPON: return Color(0.85, 0.55, 0.2)
		Item.Category.AMMO: return Color(0.72, 0.72, 0.38)
		Item.Category.HEAL: return Color(0.3, 0.8, 0.45)
		Item.Category.FOOD: return Color(0.8, 0.6, 0.3)
		Item.Category.MATERIAL: return Color(0.6, 0.6, 0.66)
		Item.Category.KEY: return Color(0.82, 0.78, 0.3)
		Item.Category.VALUABLE: return Color(0.32, 0.6, 0.92)
		_: return Color(0.6, 0.6, 0.6)
