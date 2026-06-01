extends SceneTree
## Headless inspection of the provided Mixamo assets.
## Run:  godot --headless --path . -s scripts/inspect.gd
##
## Prints: model scene tree, skeleton bone list, key-bone presence, the model's own
## clips, the Shooting clip name/length, the right-hand rest pose (for gun calibration),
## and a time-sampled table of the right-hand motion across the Shooting clip so we can
## pick the aim-hold time and the fire/recoil window.

const MODEL_FBX := "res://model/Ch35_nonPBR.fbx"
const ANIM_FBX := "res://animation/Shooting.fbx"


func _initialize() -> void:
	print("\n===================== INSPECT START =====================")
	_inspect_model()
	print("\n========================= DONE ==========================\n")
	quit()


func _inspect_model() -> void:
	var mps := load(MODEL_FBX) as PackedScene
	if mps == null:
		push_error("could not load model " + MODEL_FBX); return
	var model := mps.instantiate()
	root.add_child(model)

	print("\n--- MODEL SCENE TREE (%s) ---" % MODEL_FBX)
	_print_tree(model, 0)

	var skel := model.find_child("*", true, false) as Skeleton3D
	# find_child with type filter:
	skel = _first_of_type(model, "Skeleton3D") as Skeleton3D
	var anim := _first_of_type(model, "AnimationPlayer") as AnimationPlayer
	if skel == null:
		push_error("no Skeleton3D in model"); return
	print("\n--- SKELETON: %d bones ---" % skel.get_bone_count())
	for i in skel.get_bone_count():
		print("  [%2d] %s  (parent=%d)" % [i, skel.get_bone_name(i), skel.get_bone_parent(i)])

	print("\n--- KEY BONE PRESENCE ---")
	for bn in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head",
			"RightShoulder", "RightArm", "RightForeArm", "RightHand",
			"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand"]:
		for pre in ["mixamorig_", "mixamorig:", ""]:
			var full: String = String(pre) + String(bn)
			var idx := skel.find_bone(full)
			if idx != -1:
				print("  %-16s -> idx %d  (name '%s')" % [bn, idx, full])
				break

	print("\n--- MODEL'S OWN ANIMATIONPLAYER ---")
	if anim != null:
		for lib_name in anim.get_animation_library_list():
			var lib := anim.get_animation_library(lib_name)
			for a in lib.get_animation_list():
				var clip := lib.get_animation(a)
				print("  lib '%s' clip '%s' len=%.3f" % [lib_name, a, clip.length])
	else:
		print("  (none)")

	# Right-hand rest pose (skeleton space) for gun attachment calibration.
	var rh := _find_bone_any(skel, "RightHand")
	if rh != -1:
		var gp := skel.get_bone_global_pose(rh)
		print("\n--- RIGHT-HAND REST (skeleton space) ---")
		print("  origin=%s" % gp.origin)
		print("  basis.x(right)=%s" % gp.basis.x)
		print("  basis.y(up)=%s" % gp.basis.y)
		print("  basis.z(fwd)=%s" % gp.basis.z)

	# --- load + merge the shooting clip, then sample motion across it ---
	print("\n--- ANIMATION FBX (%s) ---" % ANIM_FBX)
	var aps := load(ANIM_FBX) as PackedScene
	if aps == null:
		push_error("could not load anim " + ANIM_FBX); return
	var ainst := aps.instantiate()
	root.add_child(ainst)
	var src_ap := _first_of_type(ainst, "AnimationPlayer") as AnimationPlayer
	if src_ap == null:
		push_error("no AnimationPlayer in animation FBX"); return
	var clip_name := ""
	var clip: Animation = null
	for lib_name in src_ap.get_animation_library_list():
		var lib := src_ap.get_animation_library(lib_name)
		for a in lib.get_animation_list():
			var c := lib.get_animation(a)
			print("  lib '%s' clip '%s' len=%.3f loop=%d tracks=%d"
				% [lib_name, a, c.length, c.loop_mode, c.get_track_count()])
			# Prefer the real Mixamo motion clip ('mixamo_com'), not the static 'Take 001'.
			if String(a) == "mixamo_com":
				clip = c
				clip_name = a
	if clip == null:  # fallback: first clip
		for lib_name in src_ap.get_animation_library_list():
			var lib := src_ap.get_animation_library(lib_name)
			for a in lib.get_animation_list():
				clip = lib.get_animation(a); clip_name = a; break
			if clip != null: break

	if clip == null or anim == null:
		push_error("no clip or no model AnimationPlayer to merge into"); return

	# merge into the model's animation player so we can sample with the model's skeleton
	var merged := clip.duplicate(true) as Animation
	merged.loop_mode = Animation.LOOP_NONE
	var dlib := anim.get_animation_library("")
	if dlib == null:
		dlib = AnimationLibrary.new()
		anim.add_animation_library("", dlib)
	if dlib.has_animation("shoot"):
		dlib.remove_animation("shoot")
	dlib.add_animation("shoot", merged)

	# Sample the right-hand (and right-forearm) motion across the clip.
	var rfa := _find_bone_any(skel, "RightForeArm")
	var hips := _find_bone_any(skel, "Hips")
	print("\n--- SHOOTING CLIP SAMPLES (clip '%s', len=%.3f) ---" % [clip_name, merged.length])
	print("  t      handX   handY   handZ   hand-above-hips   forearmX  forearmZ")
	anim.play("shoot")
	var steps := 32
	for s in steps + 1:
		var t := merged.length * float(s) / float(steps)
		anim.seek(t, true)
		anim.advance(0.0)  # force the mixer to write the pose to the skeleton (headless, no process frames)
		var hp := skel.get_bone_global_pose(rh).origin if rh != -1 else Vector3.ZERO
		var hipp := skel.get_bone_global_pose(hips).origin if hips != -1 else Vector3.ZERO
		var fp := skel.get_bone_global_pose(rfa).origin if rfa != -1 else Vector3.ZERO
		print("  %5.3f  %6.3f  %6.3f  %6.3f   %6.3f          %6.3f   %6.3f"
			% [t, hp.x, hp.y, hp.z, hp.y - hipp.y, fp.x, fp.z])


func _print_tree(n: Node, depth: int) -> void:
	print("  " + "  ".repeat(depth) + "%s : %s" % [n.name, n.get_class()])
	for c in n.get_children():
		_print_tree(c, depth + 1)


func _first_of_type(root_node: Node, type_name: String) -> Node:
	if root_node.is_class(type_name):
		return root_node
	for c in root_node.get_children():
		var found := _first_of_type(c, type_name)
		if found != null:
			return found
	return null


func _find_bone_any(skel: Skeleton3D, base: String) -> int:
	for pre in ["mixamorig_", "mixamorig:", ""]:
		var idx := skel.find_bone(pre + base)
		if idx != -1:
			return idx
	return -1
