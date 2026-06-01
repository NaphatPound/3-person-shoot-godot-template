extends Node3D
## Scene-based inspector (runs with real process frames so AnimationPlayer poses actually
## apply to the skeleton — a bare SceneTree -s script can't do this headlessly).
## Run:  godot --headless --path . scenes/inspect.tscn --quit-after 400
## Samples the right-hand / forearm motion across the Shooting 'mixamo_com' clip to reveal
## the aim-hold pose and the fire/recoil window.

const MODEL_FBX := "res://model/Ch35_nonPBR.fbx"
const ANIM_FBX := "res://animation/Shooting.fbx"
const SHOOT_CLIP := "mixamo_com"


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	var model := (load(MODEL_FBX) as PackedScene).instantiate()
	add_child(model)
	var skel := _first_of_type(model, "Skeleton3D") as Skeleton3D
	var anim := _first_of_type(model, "AnimationPlayer") as AnimationPlayer
	var rh := _find_bone_any(skel, "RightHand")
	var rfa := _find_bone_any(skel, "RightForeArm")
	var ra := _find_bone_any(skel, "RightArm")
	var hips := _find_bone_any(skel, "Hips")
	var head := _find_bone_any(skel, "Head")

	# merge the shooting clip
	var aps := (load(ANIM_FBX) as PackedScene).instantiate()
	add_child(aps)
	var src := _first_of_type(aps, "AnimationPlayer") as AnimationPlayer
	var clip: Animation = src.get_animation(SHOOT_CLIP).duplicate(true)
	clip.loop_mode = Animation.LOOP_NONE
	var lib := anim.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new(); anim.add_animation_library("", lib)
	lib.add_animation("shoot", clip)

	print("\n=== SHOOTING CLIP MOTION SAMPLE (clip '%s', len=%.3f) ===" % [SHOOT_CLIP, clip.length])
	print("Right-hand & arm in skeleton space. handY=raise, handZ=fwd/back (recoil), arm/head dist shows the gun-up pose.")
	print(" t       handX   handY   handZ   handAbvHip  rArmPitchDeg  hand->head")
	anim.play("shoot")
	anim.pause()
	var steps := 28
	for s in steps + 1:
		var t := clip.length * float(s) / float(steps)
		anim.seek(t, true)
		await get_tree().process_frame
		await get_tree().process_frame
		var hp := skel.get_bone_global_pose(rh).origin
		var hipp := skel.get_bone_global_pose(hips).origin
		var headp := skel.get_bone_global_pose(head).origin
		# right-arm pitch: angle of the upper-arm->forearm vector vs horizontal
		var armp := skel.get_bone_global_pose(ra).origin
		var fap := skel.get_bone_global_pose(rfa).origin
		var armvec := (fap - armp)
		var arm_pitch := rad_to_deg(atan2(armvec.y, Vector2(armvec.x, armvec.z).length()))
		print(" %5.3f  %6.3f  %6.3f  %6.3f   %6.3f      %7.2f      %6.3f"
			% [t, hp.x, hp.y, hp.z, hp.y - hipp.y, arm_pitch, hp.distance_to(headp)])


func _first_of_type(n: Node, type_name: String) -> Node:
	if n.is_class(type_name):
		return n
	for c in n.get_children():
		var f := _first_of_type(c, type_name)
		if f != null:
			return f
	return null


func _find_bone_any(skel: Skeleton3D, base: String) -> int:
	for pre in ["mixamorig_", "mixamorig:", ""]:
		var idx := skel.find_bone(String(pre) + base)
		if idx != -1:
			return idx
	return -1
