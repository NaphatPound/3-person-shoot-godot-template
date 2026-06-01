extends CanvasLayer
## ExtractionHUD (autoload) — a top-center status line (countdown / "OPEN — reach the zone" / extracting
## %) and a centered victory banner on escape. Reactive to the Extraction autoload; PROCESS_MODE_ALWAYS
## so the win banner shows over the paused game. Touches no existing node.

var _status: Label
var _banner: PanelContainer
var _banner_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 54
	_build()
	Extraction.time_changed.connect(_on_time)
	Extraction.hold_changed.connect(_on_hold)
	Extraction.state_changed.connect(func(_s): _refresh())
	Extraction.extracted.connect(_on_extracted)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_status.offset_top = 92
	_status.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	root.add_child(_status)

	_banner = PanelContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.15, 0.08, 0.85)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	_banner.add_theme_stylebox_override("panel", sb)
	root.add_child(_banner)
	_banner_label = Label.new()
	_banner_label.add_theme_font_size_override("font_size", 34)
	_banner_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.75))
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.text = "YOU ESCAPED\nYou survived the outbreak."
	_banner.add_child(_banner_label)
	_banner.visible = false


func _on_time(rem: float) -> void:
	if Extraction.state == Extraction.State.WAITING:
		_status.text = "Extraction in  %d:%02d" % [int(rem) / 60, int(rem) % 60]


func _on_hold(t: float) -> void:
	if Extraction.state == Extraction.State.OPEN:
		_status.text = "EXTRACTING...  %d%%" % int(t / Extraction.hold_time * 100.0)


func _refresh() -> void:
	match Extraction.state:
		Extraction.State.WAITING:
			_status.text = "Extraction in  %d:%02d" % [int(Extraction.remaining()) / 60, int(Extraction.remaining()) % 60]
		Extraction.State.OPEN:
			_status.text = "EXTRACTION OPEN — reach the zone!"
		Extraction.State.EXTRACTED:
			_status.text = ""


func _on_extracted() -> void:
	if _banner:
		_banner.visible = true
