class_name AimModifier
extends SkeletonModifier3D
## Bends the upper body to follow the aim (the fixed center crosshair).
##
## A SkeletonModifier3D's `_process_modification()` runs AFTER the AnimationPlayer writes the pose,
## so we can additively rotate the spine without the animation stomping it. The target pitch (from the
## camera's look angle) is distributed across a chain of spine bones — each takes an equal share —
## so the gun, which hangs off the hand bone downstream of the spine, points where the camera looks.
##
## Blending in/out is handled by the built-in `influence` (0 = pure animation, 1 = full aim); the
## player eases it with the aim state. Sign/axis are exported so they can be calibrated against the rig.

@export var bone_names: PackedStringArray = ["mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]
@export var pitch_axis := Vector3(1, 0, 0)   ## local bone axis to rotate about (Mixamo: X ≈ right)
@export var pitch_sign := -1.0               ## calibrated: -1 so looking up arches back / raises the gun
@export var max_total_pitch_deg := 55.0      ## clamp so the mesh never folds

## Fed by the player every frame: the camera look pitch in radians (+ = looking up).
var aim_pitch := 0.0

var _idx: PackedInt32Array = PackedInt32Array()
var _resolved := false


func _resolve() -> void:
	_idx = PackedInt32Array()
	var skel := get_skeleton()
	if skel == null:
		return
	for bn in bone_names:
		_idx.append(skel.find_bone(bn))
	_resolved = true


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	if not _resolved:
		_resolve()
	if _idx.is_empty():
		return
	var limit := deg_to_rad(max_total_pitch_deg)
	var total := clampf(aim_pitch * pitch_sign, -limit, limit)
	var per := total / float(_idx.size())
	var q := Quaternion(pitch_axis.normalized(), per)
	for i in _idx.size():
		var b := _idx[i]
		if b == -1:
			continue
		skel.set_bone_pose_rotation(b, skel.get_bone_pose_rotation(b) * q)
