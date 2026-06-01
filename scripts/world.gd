extends Node3D
## Main scene controller. Normally just hosts the level. When launched with `-- --demo` it runs an
## automated aim/shoot sequence and saves screenshots to res://build/ so the look can be verified
## without a human at the keyboard (used during the DEBUG pass — see logs.md §T7).

@onready var _player: Player = $Player
@onready var _rig: CameraRig = $CameraRig


func _ready() -> void:
	# point the sun down at an angle (set here to avoid hand-authoring a rotation matrix in the scene)
	$DirectionalLight3D.rotation_degrees = Vector3(-55, -40, 0)
	if "--demo" in OS.get_cmdline_user_args():
		_run_demo()


func _run_demo() -> void:
	# let physics settle and the camera snap into place
	for i in 40:
		await get_tree().process_frame
	await _shot("res://build/demo_1_hip.png")

	# aim in (RE4 zoom) and put the reticle on the centre dummy's chest
	_player.demo_aim = true
	for i in 50:
		await get_tree().process_frame
	var target: Vector3 = $Dummy2.global_position + Vector3.UP * 1.3
	for k in 4:
		_rig.look_at_point(target)
		await get_tree().process_frame
	await _shot("res://build/demo_2_aim.png")

	# fire on the dummy -> it should flash red (hit), crosshair kicks, muzzle flashes
	_player.fire()
	for i in 4:
		await get_tree().process_frame
	await _shot("res://build/demo_3_fire.png")
	for i in 14:
		await get_tree().process_frame
	await _shot("res://build/demo_4_hit.png")

	# look steeply UP, then DOWN, to prove the spine bends the upper body / gun to the crosshair
	for k in 30:
		_rig.look_at_point($Dummy2.global_position + Vector3.UP * 6.0)
		await get_tree().process_frame
	await _shot("res://build/demo_5_lookup.png")
	for k in 30:
		_rig.look_at_point($Dummy2.global_position + Vector3(0, -1.5, 2.0))
		await get_tree().process_frame
	await _shot("res://build/demo_6_lookdown.png")

	print("DEMO done — state: ", _player.get_debug_text().replace("\n", " | "))
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("saved %s (err=%d) size=%dx%d" % [path, err, img.get_width(), img.get_height()])
