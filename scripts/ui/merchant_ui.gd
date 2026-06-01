extends CanvasLayer
## MerchantUI (autoload) — RE4-style trader screen. Walk near a MerchantPoint (group "merchant") and a
## "[B] Trade" hint appears; [B] opens a BUY/SELL shop that pauses the game. Buy from the merchant's
## stock, sell any valued item from the bag. Builds its overlay + hint in code, registers its own [B]
## action, and seeds one merchant into the World scene (gated by scene_file_path). Touches no existing
## node. PROCESS_MODE_ALWAYS + re-asserts pause while open so it co-exists with the inventory screen.

@export var trade_range := 3.2

const WORLD_SCENE := "res://scenes/world.tscn"

var _open := false
var _root: Control
var _hint: Label
var _shop: Control
var _money_label: Label
var _buy_list: VBoxContainer
var _sell_list: VBoxContainer
var _status: Label
var _saved_mouse := Input.MOUSE_MODE_VISIBLE
var _seeded_scene: Node = null


func _enter_tree() -> void:
	if not InputMap.has_action(&"trade"):
		InputMap.add_action(&"trade")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_B
		InputMap.action_add_event(&"trade", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 45
	_build()
	_shop.visible = false
	_hint.visible = false
	Currency.changed.connect(func(_a): if _open: _refresh())


func _process(_delta: float) -> void:
	_maybe_seed()
	if _open:
		if not get_tree().paused:
			get_tree().paused = true     # keep the world frozen while trading
		return
	if get_tree().paused:
		_hint.visible = false            # another menu owns the pause
		return
	_hint.visible = _merchant_in_range() != null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"trade"):
		if _open:
			_set_open(false)
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and _merchant_in_range() != null:
			_set_open(true)
			get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()


func _merchant_in_range() -> Node3D:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return null
	for m in get_tree().get_nodes_in_group(&"merchant"):
		if m is Node3D and is_instance_valid(m):
			if player.global_position.distance_to((m as Node3D).global_position) <= trade_range:
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
	_hint.add_theme_color_override("font_color", Color(1, 1, 0.7))
	_hint.text = "[B]  Trade with Merchant"
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
	panel.custom_minimum_size = Vector2(640, 460)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.text = "MERCHANT"
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 22)
	_money_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	header.add_child(_money_label)
	vb.add_child(header)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)
	cols.add_child(_make_column("BUY", true))
	cols.add_child(_make_column("SELL", false))

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	vb.add_child(_status)

	var hint2 := Label.new()
	hint2.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint2.text = "[B] / [Esc] close"
	vb.add_child(hint2)


func _make_column(caption: String, is_buy: bool) -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(280, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := Label.new()
	h.add_theme_font_size_override("font_size", 18)
	h.text = caption
	col.add_child(h)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	col.add_child(list)
	if is_buy:
		_buy_list = list
	else:
		_sell_list = list
	return col


func _refresh() -> void:
	if not _open:
		return
	_money_label.text = "Gold: %d" % Currency.amount

	for c in _buy_list.get_children():
		_buy_list.remove_child(c)
		c.queue_free()
	for s in Merchant.get_stock():
		var item: Item = ItemDB.get_item(s["id"])
		if item == null:
			continue
		var price := Merchant.buy_price(s["id"])
		var b := Button.new()
		b.text = "%s   —   %d g" % [item.name, price]
		b.disabled = not Currency.can_afford(price)
		b.pressed.connect(_on_buy.bind(s["id"]))
		_buy_list.add_child(b)

	for c in _sell_list.get_children():
		_sell_list.remove_child(c)
		c.queue_free()
	var seen := {}
	for slot in Inventory.get_slots():
		if slot == null:
			continue
		var id: StringName = slot["id"]
		if seen.has(id):
			continue
		seen[id] = true
		var item: Item = ItemDB.get_item(id)
		if item == null or item.value <= 0:
			continue
		var b := Button.new()
		b.text = "%s x%d   —   %d g" % [item.name, Inventory.count_of(id), Merchant.sell_price(id)]
		b.pressed.connect(_on_sell.bind(id))
		_sell_list.add_child(b)


func _on_buy(id: StringName) -> void:
	var item: Item = ItemDB.get_item(id)
	if Merchant.buy(id):
		_status.text = "Bought %s." % item.name
	else:
		_status.text = "Can't buy %s — not enough gold or bag full." % item.name
	_refresh()


func _on_sell(id: StringName) -> void:
	var item: Item = ItemDB.get_item(id)
	var earned := Merchant.sell(id)
	if earned > 0:
		_status.text = "Sold %s for %d g." % [item.name, earned]
	else:
		_status.text = "Can't sell %s." % item.name
	_refresh()


func _maybe_seed() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded_scene:
		return
	_seeded_scene = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	var m := MerchantPoint.new()
	m.position = Vector3(-4.0, 0.0, 1.0)
	scene.add_child(m)
