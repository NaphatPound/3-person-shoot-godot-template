extends CanvasLayer
## HelpOverlay (autoload) — [F1] toggles a controls cheat-sheet listing every keybind the survival
## systems register, grouped by category (the loop added ~20 keys, so this is the in-game reference).
## Pauses while open. Built in code; own [F1] action; PROCESS_MODE_ALWAYS + re-asserts pause. Touches
## no existing node.

const SECTIONS := [
	["MOVE / FIGHT", [
		["WASD / Arrows", "Move"],
		["Right Mouse", "Aim (RE4 zoom)"],
		["Left Mouse / Space", "Shoot"],
		["R", "Reload"],
		["Shift", "Sprint"],
		["N", "Throw grenade"],
		["L", "Flashlight"],
	]],
	["SURVIVE / BUILD", [
		["F", "Eat food"],
		["H", "Use healing item"],
		["V", "Use antidote"],
		["E", "Pick up loot"],
		["B", "Trade (near merchant)"],
		["G", "Storage (near box)"],
		["T", "Place trap"],
		["Z", "Place barricade"],
		["X", "Repair barricade"],
	]],
	["MENUS", [
		["I / Tab", "Inventory"],
		["U", "Weapon tuning"],
		["C", "Crafting"],
		["J", "Quest log"],
		["Y", "Stats & achievements"],
		["P", "Perks"],
		["M", "Toggle minimap"],
	]],
	["SYSTEM", [
		["F5 / F9", "Quick save / load"],
		["F3", "Debug overlay"],
		["F1", "This help"],
		["Esc", "Release mouse / close"],
	]],
]

var _open := false
var _root: Control


func _enter_tree() -> void:
	if not InputMap.has_action(&"help"):
		InputMap.add_action(&"help")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_F1
		InputMap.action_add_event(&"help", e)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 52
	_build()
	_root.visible = false


func _process(_delta: float) -> void:
	if _open and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"help"):
		toggle()
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open


func toggle() -> void:
	_open = not _open
	_root.visible = _open
	get_tree().paused = _open


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(740, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "CONTROLS"
	vb.add_child(title)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	vb.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	cols.add_child(right)

	_add_section(left, SECTIONS[0])
	_add_section(left, SECTIONS[1])
	_add_section(right, SECTIONS[2])
	_add_section(right, SECTIONS[3])

	var hint := Label.new()
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	hint.text = "[F1] / [Esc] close"
	vb.add_child(hint)


func _add_section(col: VBoxContainer, section: Array) -> void:
	var h := Label.new()
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	h.text = section[0]
	col.add_child(h)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 3)
	for e in section[1]:
		var k := Label.new()
		k.custom_minimum_size = Vector2(150, 0)
		k.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		k.text = e[0]
		grid.add_child(k)
		var a := Label.new()
		a.text = e[1]
		grid.add_child(a)
	col.add_child(grid)
