extends CanvasLayer
## SurvivalHUD (autoload) — compact Health/Hunger bars in the TOP-LEFT corner, on a dedicated
## CanvasLayer so it never touches the existing crosshair HUD (scenes/hud.tscn, which uses the
## bottom strip + top-right). Purely reactive to SurvivalStats; shows STARVING / YOU DIED hints
## and the [F]/[H] keys.

var _health_bar: ProgressBar
var _hunger_bar: ProgressBar
var _status: Label


func _ready() -> void:
	layer = 20
	_build()
	SurvivalStats.stats_changed.connect(_on_stats)
	_on_stats(SurvivalStats.hunger, SurvivalStats.health)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.offset_left = 18
	box.offset_top = 16
	box.offset_right = 246
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	_health_bar = _make_bar(box, "HEALTH", Color(0.85, 0.27, 0.27))
	_hunger_bar = _make_bar(box, "HUNGER", Color(0.86, 0.62, 0.2))

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_status.text = "[F] eat   ·   [H] heal"
	box.add_child(_status)


func _make_bar(parent: Node, caption: String, col: Color) -> ProgressBar:
	var l := Label.new()
	l.text = caption
	l.add_theme_font_size_override("font_size", 12)
	parent.add_child(l)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 16)

	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)

	parent.add_child(bar)
	return bar


func _on_stats(hunger: float, health: float) -> void:
	if _hunger_bar:
		_hunger_bar.value = hunger
	if _health_bar:
		_health_bar.value = health
	var t := "[F] eat   ·   [H] heal"
	var col := Color(1, 1, 1, 0.6)
	if health <= 0.0:
		t = "YOU DIED   ·   [H] use a herb to recover"
		col = Color(1, 0.25, 0.25)
	elif hunger <= 0.0:
		t = "STARVING!   ·   [F] eat now"
		col = Color(1, 0.5, 0.2)
	if _status:
		_status.text = t
		_status.add_theme_color_override("font_color", col)
