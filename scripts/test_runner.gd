extends Node
## Headless test harness. Loads the real world scene, lets it build/settle across process frames, then
## asserts the template's wiring and behaviour. CI-friendly: exits 0 on all-pass, 1 on any failure.
## Run:  godot --headless --path . scenes/test.tscn --quit-after 600

var _pass := 0
var _fail := 0


func _ready() -> void:
	await _run()


func _run() -> void:
	var world := (load("res://scenes/world.tscn") as PackedScene).instantiate()
	add_child(world)
	# let Player._ready build the model/gun/modifier and physics settle
	for i in 25:
		await get_tree().process_frame

	var player: Player = world.get_node_or_null("Player")
	var rig: CameraRig = world.get_node_or_null("CameraRig")
	_check("player present", player != null)
	_check("camera rig present", rig != null)
	if player == null:
		return _finish()

	var skel := player.get_skeleton()
	var anim := player.get_anim_player()
	_check("skeleton resolved", skel != null)
	_check("skeleton has 65 bones", skel != null and skel.get_bone_count() == 65)
	_check("animation player resolved", anim != null)
	_check("Shooting clip merged as 'shoot'", anim != null and anim.has_animation("shoot"))
	_check("right-hand bone found", skel != null and skel.find_bone("mixamorig_RightHand") != -1)
	for b in ["mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]:
		_check("spine bone '%s' found" % b, skel != null and skel.find_bone(b) != -1)

	# gun attached to the right-hand bone socket, with a muzzle
	var socket := skel.get_node_or_null("GunSocket") if skel else null
	_check("gun socket is a hand BoneAttachment3D",
		socket is BoneAttachment3D and (socket as BoneAttachment3D).bone_name == "mixamorig_RightHand")
	var gun := socket.get_node_or_null("Gun") if socket else null
	_check("gun attached under socket", gun != null)
	_check("gun has a Muzzle marker", gun != null and gun.get_node_or_null("Muzzle") != null)

	# aim modifier present and actually moves the upper body — driven through the real aim pipeline
	# (not aiming vs aiming steeply up), measured on the right-hand bone in skeleton space.
	var mod := player.get_aim_modifier()
	_check("aim modifier present under skeleton", mod != null and mod.get_parent() == skel)
	if mod != null and skel != null and rig != null:
		var hand := skel.find_bone("mixamorig_RightHand")
		var gun_node: Node3D = skel.get_node("GunSocket/Gun") if skel.has_node("GunSocket/Gun") else null
		var up_target: Node3D = world.get_node_or_null("Dummy2")
		player.demo_aim = false
		for k in 30:
			await get_tree().process_frame
		var flat_bone := skel.get_bone_global_pose(hand).origin
		var flat_gun := gun_node.global_position if gun_node else Vector3.ZERO
		player.demo_aim = true
		for k in 45:
			if up_target:
				rig.look_at_point(up_target.global_position + Vector3.UP * 6.0)
			await get_tree().process_frame
		var bent_bone := skel.get_bone_global_pose(hand).origin
		var bent_gun := gun_node.global_position if gun_node else Vector3.ZERO
		print("    [diag] bone Δ=%.3f m  gun Δ=%.3f m  influence=%.2f aim_pitch=%.2f"
			% [flat_bone.distance_to(bent_bone), flat_gun.distance_to(bent_gun), mod.influence, mod.aim_pitch])
		# the gun rides the rendered bone pose (BoneAttachment3D), so it reflects the modifier output
		_check("aim modifier moves the gun (>5cm)", flat_gun.distance_to(bent_gun) > 0.05)
		player.demo_aim = false
		for k in 10:
			await get_tree().process_frame

	# hit-scan ray from the aimed camera hits a target dummy
	if rig != null:
		var dummy: Node3D = world.get_node_or_null("Dummy2")
		_check("test dummy present", dummy != null)
		if dummy != null:
			player.demo_aim = true
			for k in 30:
				rig.look_at_point(dummy.global_position + Vector3.UP * 1.3)
				await get_tree().process_frame
			player.fire()
			await get_tree().process_frame
			_check("hit-scan ray hits the dummy", player.get_last_hit().begins_with("dummy"))

	_finish()


func _check(label: String, cond: bool) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func _finish() -> void:
	print("\n=== TestRunner done: %d passed, %d failed ===" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
