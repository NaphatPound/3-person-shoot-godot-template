extends CanvasLayer
## WeaponUI (autoload) — RE4-style weapon tuning screen. Toggle with [U]; pauses the game. Shows the
## weapon's stats with their level and the gold+scrap cost of the next upgrade, plus buyable
## attachments. Spends via the Weapons autoload. Builds its overlay in code, registers its own [U]
## action, touches no existing node. PROCESS_MODE_ALWAYS + re-asserts pause so it co-exists with the
## inventory / merchant screens.

const WEAPON := &"handgun"

var _open := false
var _root: Control
var _money_label: Label
var _list: VBoxContainer
var _status: Label
var _saved_mouse := Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	if not InputMap.has_action(&"weapon_tune"):
		InputMap.add_action(&"weapon_tune")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_U
		InputMap.action_add_event(&"weapon_tune", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 46
	_build()
	_root.visible = false
	Weapons.changed.connect(func(): if _open: _refresh())
	Currency.changed.connect(func(_a): if _open: _refresh())


func _process(_delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"weapon_tune"):
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

	var header := HBoxContainer.new()
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "WEAPON TUNING — " + Weapons.weapon_name(WEAPON)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	vb.add_child(header)

	_money_label = Label.new()
	_money_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vb.add_child(_money_label)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 5)
	vb.add_child(_list)

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	vb.add_child(_status)

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[U] / [Esc] close"
	vb.add_child(hint)


func _refresh() -> void:
	if not _open:
		return
	_money_label.text = "Gold: %d      Scrap: %d" % [Currency.amount, Inventory.count_of(&"scrap")]
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for track in Weapons.tracks():
		_list.add_child(_make_track_row(track))
	_list.add_child(HSeparator.new())
	var atl := Label.new()
	atl.add_theme_font_size_override("font_size", 16)
	atl.text = "ATTACHMENTS"
	_list.add_child(atl)
	for key in Weapons.attachment_keys():
		_list.add_child(_make_attachment_row(key))


func _make_track_row(track: String) -> Control:
	var row := HBoxContainer.new()
	var lv := Weapons.level_of(WEAPON, track)
	var maxl := Weapons.max_level(WEAPON, track)
	var name_lbl := Label.new()
	name_lbl.custom_minimum_size = Vector2(330, 0)
	name_lbl.text = "%s   %s   (Lv %d/%d)" % [track.to_upper(), _fmt_stat(track, Weapons.get_stat(WEAPON, track)), lv, maxl]
	row.add_child(name_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 0)
	if lv >= maxl:
		btn.text = "MAX"
		btn.disabled = true
	else:
		var c := Weapons.upgrade_cost(WEAPON, track)
		btn.text = "Upgrade  %dg + %d scrap" % [c["gold"], c["scrap"]]
		btn.disabled = not Weapons.can_upgrade(WEAPON, track)
		btn.pressed.connect(_on_upgrade.bind(track))
	row.add_child(btn)
	return row


func _make_attachment_row(key: StringName) -> Control:
	var row := HBoxContainer.new()
	var info := Weapons.attachment_info(key)
	var name_lbl := Label.new()
	name_lbl.custom_minimum_size = Vector2(330, 0)
	name_lbl.text = info.get("name", String(key))
	row.add_child(name_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 0)
	if Weapons.has_attachment(WEAPON, key):
		btn.text = "Equipped"
		btn.disabled = true
	else:
		btn.text = "Buy  %dg" % int(info.get("gold", 0))
		btn.disabled = not Currency.can_afford(int(info.get("gold", 0)))
		btn.pressed.connect(_on_attach.bind(key))
	row.add_child(btn)
	return row


func _on_upgrade(track: String) -> void:
	_status.text = ("Upgraded %s." % track.to_upper()) if Weapons.upgrade(WEAPON, track) else "Can't upgrade — gold/scrap/max."
	_refresh()


func _on_attach(key: StringName) -> void:
	_status.text = ("Equipped %s." % Weapons.attachment_info(key).get("name", "")) if Weapons.buy_attachment(WEAPON, key) else "Not enough gold."
	_refresh()


func _fmt_stat(track: String, v: float) -> String:
	match track:
		"damage", "capacity": return "%d" % int(round(v))
		"fire_rate": return "%.1f/s" % v
		"reload": return "%.2fs" % v
		_: return str(v)
