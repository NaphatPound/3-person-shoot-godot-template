extends Node
## WeatherFX (autoload) — renders the weather: a fog/gloom tint (layer -1) + a rain overlay (layer -1,
## behind the HUD so it falls "in the world") + a small weather label under the clock. Reactive to the
## Weather autoload across three CanvasLayers; built in code; touches no existing node.

var _fog: ColorRect
var _label: Label


func _ready() -> void:
	_build()
	Weather.changed.connect(_on_changed)
	Weather.weather_changed.connect(func(_s): _refresh_label())
	_on_changed()
	_refresh_label()


func _build() -> void:
	var fog_layer := CanvasLayer.new()
	fog_layer.layer = -1
	add_child(fog_layer)
	_fog = ColorRect.new()
	_fog.color = Color(0.6, 0.64, 0.7, 0.0)
	_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_layer.add_child(_fog)

	var rain_layer := CanvasLayer.new()
	rain_layer.layer = -1
	add_child(rain_layer)
	var rain := WeatherRain.new()
	rain.set_anchors_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain_layer.add_child(rain)

	var ui := CanvasLayer.new()
	ui.layer = 17
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 50
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.8))
	root.add_child(_label)


func _on_changed() -> void:
	if _fog:
		_fog.color.a = Weather.fog_amount() * 0.4


func _refresh_label() -> void:
	if _label:
		_label.text = "Weather: " + Weather.state_name()
