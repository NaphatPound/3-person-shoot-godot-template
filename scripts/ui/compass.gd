extends CanvasLayer
## Compass (autoload) — hosts a CompassView heading band at top-center. Own CanvasLayer; touches no
## existing node.

var _view: CompassView


func _ready() -> void:
	layer = 16
	_view = CompassView.new()
	_view.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_view.offset_left = -200
	_view.offset_right = 200
	_view.offset_top = 112
	_view.offset_bottom = 140
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
