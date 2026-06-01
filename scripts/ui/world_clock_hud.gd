extends Node
## WorldClockHUD (autoload) — shows the day/night clock + current wave (top-center) and a full-screen
## night tint that deepens after dark. The tint sits on a CanvasLayer at layer -1 (between the 3D view
## and the in-world HUD Control on layer 0), so it darkens the scene WITHOUT dimming the UI. Built in
## code across two CanvasLayers; touches no existing node.

var _tint: ColorRect
var _clock: Label
var _wave: Label


func _ready() -> void:
	_build()
	DayNight.time_changed.connect(_on_time)
	DayNight.phase_changed.connect(func(_p): _refresh())
	Horde.wave_started.connect(func(_n, _c): _refresh())
	_refresh()


func _build() -> void:
	# night tint — behind the world-space HUD, above the 3D
	var tint_layer := CanvasLayer.new()
	tint_layer.layer = -1
	add_child(tint_layer)
	_tint = ColorRect.new()
	_tint.color = Color(0.03, 0.05, 0.12, 0.0)
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint_layer.add_child(_tint)

	# clock + wave readout, top-center
	var ui := CanvasLayer.new()
	ui.layer = 17
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_top = 8
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	_clock = Label.new()
	_clock.add_theme_font_size_override("font_size", 18)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_clock)

	_wave = Label.new()
	_wave.add_theme_font_size_override("font_size", 14)
	_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave.add_theme_color_override("font_color", Color(1, 0.7, 0.6))
	box.add_child(_wave)


func _on_time(_t: float) -> void:
	if _tint:
		_tint.color.a = DayNight.darkness() * 0.6
	if _clock:
		_clock.text = "%s   [%s]" % [DayNight.clock_text(), DayNight.phase_name()]


func _refresh() -> void:
	if _clock:
		_clock.text = "%s   [%s]" % [DayNight.clock_text(), DayNight.phase_name()]
	if _wave:
		_wave.text = "Wave %d   ·   Zombies: %d" % [Horde.wave, Horde.alive()]
