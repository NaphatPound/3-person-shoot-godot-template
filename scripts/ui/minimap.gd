extends CanvasLayer
## Minimap (autoload) — hosts a MinimapView radar at center-right of the screen. [M] toggles it.
## Own CanvasLayer; touches no existing node.

var _view: MinimapView


func _enter_tree() -> void:
	if not InputMap.has_action(&"toggle_map"):
		InputMap.add_action(&"toggle_map")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_M
		InputMap.action_add_event(&"toggle_map", e)


func _ready() -> void:
	layer = 17
	_view = MinimapView.new()
	_view.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_view.offset_left = -168
	_view.offset_right = -18
	_view.offset_top = -75
	_view.offset_bottom = 75
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_map"):
		toggle()


func toggle() -> void:
	if _view:
		_view.visible = not _view.visible
