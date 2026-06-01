extends Node
## GameInput (autoload)
## Registers the template's input actions in code, so project.godot needs no
## fragile hand-authored [input] block. Safe to re-run (checks before adding).
##
## Actions:
##   aim          — Right-Mouse (hold to raise the gun / zoom the camera)
##   attack       — Left-Mouse  (fire) [+ Space as a keyboard fallback]
##   move_*       — WASD / arrow keys
##   toggle_debug — F3 (show/hide the debug overlay)
## (ui_cancel / Esc is a Godot built-in and is reused for "release mouse / quit".)

func _enter_tree() -> void:
	_ensure(&"aim", [_mouse(MOUSE_BUTTON_RIGHT)])
	_ensure(&"attack", [_mouse(MOUSE_BUTTON_LEFT), _key(KEY_SPACE)])
	_ensure(&"move_forward", [_key(KEY_W), _key(KEY_UP)])
	_ensure(&"move_back", [_key(KEY_S), _key(KEY_DOWN)])
	_ensure(&"move_left", [_key(KEY_A), _key(KEY_LEFT)])
	_ensure(&"move_right", [_key(KEY_D), _key(KEY_RIGHT)])
	_ensure(&"toggle_debug", [_key(KEY_F3)])


func _ensure(action: StringName, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in events:
		InputMap.action_add_event(action, e)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _mouse(btn: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = btn
	return e
