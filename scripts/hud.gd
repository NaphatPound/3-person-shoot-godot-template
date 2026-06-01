extends Control
## Heads-up display: a center crosshair that tightens when aiming and kicks when firing, a hit-marker
## flash, a controls hint, and an F3 debug overlay. Pulls live state from the Player (found by group)
## and reacts to its `fired` / `hit_confirmed` signals.

@export var hip_gap := 14.0      ## crosshair gap (px) when not aiming
@export var aim_gap := 5.0       ## crosshair gap when aiming
@export var tick_len := 9.0
@export var fire_kick := 7.0     ## extra gap added on each shot
@export var color := Color(1, 1, 1, 0.9)
@export var hostile_color := Color(1, 0.3, 0.3, 0.95)

@onready var _controls: Label = $Controls
@onready var _debug: Label = $Debug

var _player: Node = null
var _connected := false
var _gap := 14.0
var _kick := 0.0
var _hit_flash := 0.0
var _hit_hostile := false


func _ready() -> void:
	_debug.visible = true
	_controls.text = "WASD move   ·   RMB aim (zoom)   ·   LMB shoot   ·   F3 debug   ·   Esc release mouse"


func _process(delta: float) -> void:
	_acquire_player()
	var aim_t := 0.0
	if _player and _player.has_method("is_aiming"):
		var rig := get_tree().get_first_node_in_group("camera_rig")
		if rig and rig.has_method("get_aim_t"):
			aim_t = rig.get_aim_t()
	_gap = lerpf(hip_gap, aim_gap, aim_t)
	_kick = move_toward(_kick, 0.0, 40.0 * delta)
	_hit_flash = move_toward(_hit_flash, 0.0, 2.5 * delta)

	if _debug.visible:
		var txt := "FPS %d" % Engine.get_frames_per_second()
		if _player and _player.has_method("get_debug_text"):
			txt += "\n" + _player.get_debug_text()
		_debug.text = txt

	queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_debug.visible = not _debug.visible


func _acquire_player() -> void:
	if _player and is_instance_valid(_player):
		if not _connected:
			_connect_player()
		return
	_player = get_tree().get_first_node_in_group("player")
	_connected = false
	if _player:
		_connect_player()


func _connect_player() -> void:
	if _player.has_signal("fired") and not _player.fired.is_connected(_on_fired):
		_player.fired.connect(_on_fired)
	if _player.has_signal("hit_confirmed") and not _player.hit_confirmed.is_connected(_on_hit):
		_player.hit_confirmed.connect(_on_hit)
	_connected = true


func _on_fired() -> void:
	_kick = minf(_kick + fire_kick, 24.0)


func _on_hit(_point: Vector3, hostile: bool) -> void:
	_hit_flash = 1.0
	_hit_hostile = hostile


func _draw() -> void:
	var c := size * 0.5
	var g := _gap + _kick
	var col := color
	# crosshair: four ticks around a center gap
	draw_line(c + Vector2(0, -g), c + Vector2(0, -g - tick_len), col, 2.0)
	draw_line(c + Vector2(0, g), c + Vector2(0, g + tick_len), col, 2.0)
	draw_line(c + Vector2(-g, 0), c + Vector2(-g - tick_len, 0), col, 2.0)
	draw_line(c + Vector2(g, 0), c + Vector2(g + tick_len, 0), col, 2.0)
	# center dot
	draw_circle(c, 1.5, col)
	# hit marker: a short X that flashes after a confirmed hit
	if _hit_flash > 0.01:
		var hc := (hostile_color if _hit_hostile else Color(1, 1, 1))
		hc.a = _hit_flash
		var r := 10.0
		var r0 := 4.0
		for s in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			draw_line(c + s * r0, c + s * r, hc, 2.0)
