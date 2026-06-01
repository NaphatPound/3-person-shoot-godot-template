extends Node
## TensionFX (autoload) — a pulsing red danger vignette (layer -1, behind the HUD) + a "! DANGER !"
## flash when threat is high. Intensity and pulse rate scale with Tension.level. Built in code across two
## CanvasLayers; touches no existing node.

var _vig: ColorRect
var _danger: Label
var _t := 0.0


func _ready() -> void:
	_build()
	Tension.changed.connect(_on_changed)


func _build() -> void:
	var vl := CanvasLayer.new()
	vl.layer = -1
	add_child(vl)
	_vig = ColorRect.new()
	_vig.color = Color(0.5, 0.0, 0.0, 0.0)
	_vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vl.add_child(_vig)

	var ul := CanvasLayer.new()
	ul.layer = 16
	add_child(ul)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ul.add_child(root)
	_danger = Label.new()
	_danger.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_danger.offset_top = 128
	_danger.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_danger.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_danger.add_theme_font_size_override("font_size", 18)
	_danger.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_danger.text = "! DANGER !"
	_danger.visible = false
	root.add_child(_danger)


func _process(delta: float) -> void:
	_t += delta


func _on_changed(lvl: float) -> void:
	var pulse := 0.55 + 0.45 * sin(_t * (2.0 + lvl * 7.0))
	if _vig:
		_vig.color.a = lvl * pulse * 0.28
	if _danger:
		_danger.visible = Tension.is_high()
