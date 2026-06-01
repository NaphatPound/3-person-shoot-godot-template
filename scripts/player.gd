class_name Player
extends CharacterBody3D
## Third-person shooter avatar (RE4-Remake style).
##
## Builds everything on the imported Mixamo model at runtime: merges the Shooting clip, attaches a gun
## to the right-hand bone, and adds the spine AimModifier. RMB holds the aim pose + faces the body to the
## camera + tells the camera to zoom; LMB plays the recoil window, flashes the muzzle, and fires a hit-scan
## ray from the camera through screen-center. The upper body bends to the center crosshair via AimModifier.
##
## NOTE: only a *Shooting* clip was provided (no idle/walk locomotion), so the avatar stays in the gun-ready
## pose and slides while moving — wiring locomotion clips is the intended extension point.

# --- assets / calibration (see logs.md §T3) ---
const MODEL_FBX := "res://model/Ch35_nonPBR.fbx"
const ANIM_FBX := "res://animation/Shooting.fbx"
const SOURCE_CLIP := "mixamo_com"          # the real shooting motion inside the FBX
const SHOOT_ANIM := "shoot"                # name we store the merged clip under
const RIGHT_HAND_BONE := "mixamorig_RightHand"
const SPINE_BONES: PackedStringArray = ["mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]

# Shooting-clip timing (seconds): steady aim just before the recoil kick, fired through recovery.
const AIM_POSE_TIME := 0.21
const FIRE_START := 0.21
const FIRE_END := 1.0

@export var move_speed := 3.6
@export var aim_move_speed := 1.9          # strafe slower while aiming
@export var gravity := 20.0
@export var turn_speed := 12.0
@export var fire_cooldown := 0.16
@export var fire_speed_scale := 1.4        # play the recoil window a bit fast for snappy fire
@export var aim_pitch_gain := 1.0          # how strongly the spine follows the camera pitch
@export var fire_recoil := 0.045           # camera kick per shot (rad)
@export var shoot_mask := 5                # world(1) | dummy(4)
## Gun placement in the right-hand bone's local frame (calibrated visually in T7).
@export var gun_offset := Transform3D(
	Basis.from_euler(Vector3(deg_to_rad(-90.0), deg_to_rad(0.0), deg_to_rad(90.0))),
	Vector3(0.0, 0.04, 0.03))

@export var camera_rig_path: NodePath

signal fired                               # for the HUD crosshair kick
signal hit_confirmed(point: Vector3, hostile: bool)

var _model: Node3D
var _skel: Skeleton3D
var _anim: AnimationPlayer
var _aim_mod: AimModifier
var _gun: Gun
var _cam_rig: CameraRig
var _aiming := false
var _firing := false
var _fire_cd := 0.0
var _last_hit := "—"
var demo_aim := false        # set by the --demo hook in world.gd to force the aim state


func _ready() -> void:
	add_to_group("player")
	_cam_rig = get_node_or_null(camera_rig_path) as CameraRig
	_build_model()
	if _skel == null or _anim == null:
		push_error("Player: model missing Skeleton3D/AnimationPlayer"); return
	_merge_shoot_clip()
	_hold_aim_pose()
	_build_gun()
	_build_aim_modifier()
	if _cam_rig:
		_cam_rig.set_target(self)


func _build_model() -> void:
	var ps := load(MODEL_FBX) as PackedScene
	if ps == null:
		push_error("Player: could not load " + MODEL_FBX); return
	_model = ps.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_skel = _first_of_type(_model, "Skeleton3D") as Skeleton3D
	_anim = _first_of_type(_model, "AnimationPlayer") as AnimationPlayer


func _merge_shoot_clip() -> void:
	var ps := load(ANIM_FBX) as PackedScene
	if ps == null:
		push_error("Player: could not load " + ANIM_FBX); return
	var inst := ps.instantiate()
	var src := _first_of_type(inst, "AnimationPlayer") as AnimationPlayer
	if src != null and src.has_animation(SOURCE_CLIP):
		var clip: Animation = src.get_animation(SOURCE_CLIP).duplicate(true)
		clip.loop_mode = Animation.LOOP_NONE
		var lib := _anim.get_animation_library("")
		if lib == null:
			lib = AnimationLibrary.new()
			_anim.add_animation_library("", lib)
		if lib.has_animation(SHOOT_ANIM):
			lib.remove_animation(SHOOT_ANIM)
		lib.add_animation(SHOOT_ANIM, clip)
	else:
		push_error("Player: shooting clip '%s' not found in FBX" % SOURCE_CLIP)
	inst.free()


# Hold the steady aim pose (paused). The gun stays raised/ready; the spine modifier (off until aiming)
# leaves this raw pose alone when hip-firing.
func _hold_aim_pose() -> void:
	if not _anim.has_animation(SHOOT_ANIM):
		return
	_anim.play(SHOOT_ANIM)
	_anim.seek(AIM_POSE_TIME, true)
	_anim.pause()
	_anim.animation_finished.connect(_on_anim_finished)


func _build_gun() -> void:
	var socket := BoneAttachment3D.new()
	socket.name = "GunSocket"
	_skel.add_child(socket)
	socket.bone_name = RIGHT_HAND_BONE
	_gun = Gun.new()
	_gun.name = "Gun"
	socket.add_child(_gun)
	_gun.transform = gun_offset


func _build_aim_modifier() -> void:
	_aim_mod = AimModifier.new()
	_aim_mod.name = "AimModifier"
	_aim_mod.bone_names = SPINE_BONES
	_skel.add_child(_aim_mod)
	_aim_mod.influence = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	# first click captures the mouse (required for Web pointer-lock); afterwards LMB fires
	if event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("attack"):
		_try_fire()


func _physics_process(delta: float) -> void:
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_aiming = demo_aim or Input.is_action_pressed("aim")
	if _cam_rig:
		_cam_rig.set_aiming(_aiming)

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# camera-relative movement
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3.ZERO
	var cam := _cam_rig.get_camera() if _cam_rig else get_viewport().get_camera_3d()
	if cam != null and move != Vector2.ZERO:
		var b := cam.global_transform.basis
		var fwd := -b.z; fwd.y = 0.0; fwd = fwd.normalized()
		var right := b.x; right.y = 0.0; right = right.normalized()
		dir = (right * move.x - fwd * move.y).normalized()

	var spd := aim_move_speed if _aiming else move_speed
	if dir != Vector3.ZERO:
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, spd)
		velocity.z = move_toward(velocity.z, 0.0, spd)

	# facing: aim -> face the camera's forward; hip -> face the movement direction
	var target_yaw := _model.rotation.y
	if _aiming and _cam_rig:
		var f := _cam_rig.get_forward_flat()
		target_yaw = atan2(f.x, f.z)
	elif dir != Vector3.ZERO:
		target_yaw = atan2(dir.x, dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)

	move_and_slide()

	# drive the spine aim modifier from the camera pitch, eased by the aim blend
	if _aim_mod and _cam_rig:
		_aim_mod.aim_pitch = _cam_rig.get_look_pitch() * aim_pitch_gain
		_aim_mod.influence = _cam_rig.get_aim_t()

	# end the fire window -> snap back to the held aim pose
	if _firing and _anim.current_animation_position >= FIRE_END:
		_end_fire()


func _try_fire() -> void:
	if _fire_cd > 0.0:
		return
	_fire_cd = fire_cooldown
	# play the recoil window
	_firing = true
	_anim.play(SHOOT_ANIM, -1.0, fire_speed_scale)
	_anim.seek(FIRE_START, true)
	if _gun:
		_gun.flash()
	if _cam_rig:
		_cam_rig.add_recoil(fire_recoil)
	fired.emit()
	_raycast_shot()


func _end_fire() -> void:
	_firing = false
	_anim.play(SHOOT_ANIM)
	_anim.seek(AIM_POSE_TIME, true)
	_anim.pause()


func _raycast_shot() -> void:
	var cam := _cam_rig.get_camera() if _cam_rig else get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 200.0   # straight through screen-center
	var q := PhysicsRayQueryParameters3D.create(from, to, shoot_mask)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		_last_hit = "miss"
		return
	var point: Vector3 = hit.position
	var collider: Object = hit.collider
	var hostile := collider is Node and (collider as Node).is_in_group("dummy")
	if hostile and collider.has_method("on_hit"):
		collider.on_hit()
	_last_hit = "%s @ %.1fm" % ["dummy" if hostile else "world", from.distance_to(point)]
	hit_confirmed.emit(point, hostile)


func _on_anim_finished(anim_name: StringName) -> void:
	# if the recoil window runs to the very end before _physics_process catches FIRE_END, re-settle
	if anim_name == SHOOT_ANIM and _firing:
		_end_fire()


# --- helpers / debug ---
func _first_of_type(n: Node, type_name: String) -> Node:
	if n.is_class(type_name):
		return n
	for c in n.get_children():
		var f := _first_of_type(c, type_name)
		if f != null:
			return f
	return null


func is_aiming() -> bool: return _aiming
func is_firing() -> bool: return _firing
func fire() -> void: _try_fire()   # public entry for the --demo hook
func get_last_hit() -> String: return _last_hit
func get_skeleton() -> Skeleton3D: return _skel
func get_anim_player() -> AnimationPlayer: return _anim
func get_aim_modifier() -> AimModifier: return _aim_mod


func get_debug_text() -> String:
	var pitch_deg := 0.0
	if _cam_rig:
		pitch_deg = rad_to_deg(_cam_rig.get_look_pitch())
	var aim_t := _cam_rig.get_aim_t() if _cam_rig else 0.0
	return "state: %s\naim_t: %.2f\nanim t: %.2f\nspine pitch: %.0f°\nlast hit: %s" % [
		"AIM" if _aiming else "HIP", aim_t, _anim.current_animation_position, pitch_deg, _last_hit]
