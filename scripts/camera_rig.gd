class_name CameraRig
extends Node3D
## Over-the-shoulder third-person camera, RE4-Remake style.
##
## Sits behind the target's shoulder and looks FORWARD (not at the character), so screen-center
## is the aim point. The mouse drives yaw (around the target) and pitch. While aiming it blends to
## a tighter profile — closer, narrower FOV, smaller shoulder offset — but never loses mouse control.
##
## Camera collision is a manual ray from the pivot to the desired camera spot (kept simple and fully
## under our control, instead of a SpringArm3D — see logs.md / plan.md §4).

@export var target_path: NodePath

@export_group("Hip profile (not aiming)")
@export var hip_distance := 3.4      ## how far behind the shoulder
@export var hip_height := 1.55       ## pivot height above the target's feet
@export var hip_shoulder := 0.55     ## lateral offset (+ = right shoulder)
@export var hip_fov := 70.0

@export_group("Aim profile (RE4 zoom)")
@export var aim_distance := 1.45
@export var aim_height := 1.48
@export var aim_shoulder := 0.42
@export var aim_fov := 45.0

@export_group("Feel")
@export var sensitivity := 0.0032
@export var min_pitch := -1.15        ## look-down limit (rad); +pitch = look up
@export var max_pitch := 1.15         ## look-up limit (rad)
@export var aim_blend_speed := 9.0    ## hip<->aim transition speed
@export var follow_smooth := 16.0     ## camera position follow stiffness
@export var collision_mask := 1       ## world layer the camera avoids clipping into
@export var collision_margin := 0.2

@export_group("Recoil")
@export var max_kick := 0.06          ## max transient upward pitch (rad)
@export var kick_recover := 0.5       ## rad/s the kick decays

@onready var _cam: Camera3D = $Camera3D

var _target: Node3D
var _yaw := 0.0
var _pitch := 0.12
var _aim_t := 0.0          ## 0 = hip, 1 = aim (eased toward _aiming)
var _aiming := false
var _kick := 0.0           ## transient recoil pitch
var _first := true


func _ready() -> void:
	add_to_group("camera_rig")
	_target = get_node_or_null(target_path) as Node3D


func set_target(t: Node3D) -> void:
	_target = t


func set_aiming(v: bool) -> void:
	_aiming = v


func add_recoil(amount: float) -> void:
	_kick = minf(_kick + amount, max_kick)


# --- exposed state for the player + aim modifier + HUD ---
func get_aim_t() -> float: return _aim_t
func get_look_pitch() -> float: return _pitch
func get_yaw() -> float: return _yaw
func get_camera() -> Camera3D: return _cam
func is_aiming() -> bool: return _aiming

## Horizontal forward unit vector (the direction the camera looks, flattened).
func get_forward_flat() -> Vector3:
	var f := -_orientation().z
	f.y = 0.0
	return f.normalized() if f.length() > 0.001 else Vector3.FORWARD


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * sensitivity
		_pitch = clampf(_pitch - event.relative.y * sensitivity, min_pitch, max_pitch)


## Point the camera so screen-center looks at a world point (used by the --demo hook and handy for
## scripted sequences). Derives yaw/pitch from the current camera position; call a few times across
## frames to converge (the camera moves slightly as yaw/pitch change).
func look_at_point(p: Vector3) -> void:
	var dir := p - _cam.global_position
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	_pitch = clampf(asin(clampf(dir.y, -1.0, 1.0)), min_pitch, max_pitch)
	_yaw = atan2(-dir.x, -dir.z)


func _orientation() -> Basis:
	return Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch + _kick)


func _process(delta: float) -> void:
	if _target == null:
		return
	# blend hip <-> aim, ease the result
	_aim_t = move_toward(_aim_t, 1.0 if _aiming else 0.0, aim_blend_speed * delta)
	var t := smoothstep(0.0, 1.0, _aim_t)
	var distance := lerpf(hip_distance, aim_distance, t)
	var height := lerpf(hip_height, aim_height, t)
	var shoulder := lerpf(hip_shoulder, aim_shoulder, t)
	_cam.fov = lerpf(hip_fov, aim_fov, t)
	_kick = move_toward(_kick, 0.0, kick_recover * delta)

	var orient := _orientation()
	var pivot := _target.global_position + Vector3.UP * height
	var back := orient * Vector3(0.0, 0.0, 1.0)    # behind the look direction
	var right := orient * Vector3(1.0, 0.0, 0.0)
	var desired := pivot + back * distance + right * shoulder

	# manual camera collision: don't let the camera poke through world geometry
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pivot, desired, collision_mask)
	q.exclude = [_target.get_rid()] if _target is CollisionObject3D else []
	var hit := space.intersect_ray(q)
	var cam_pos := desired
	if hit:
		cam_pos = (hit.position as Vector3) + (pivot - desired).normalized() * collision_margin

	if _first:
		_cam.global_transform = Transform3D(orient, cam_pos)
		_first = false
	else:
		var k := 1.0 - exp(-follow_smooth * delta)
		var new_pos := _cam.global_position.lerp(cam_pos, k)
		_cam.global_transform = Transform3D(orient, new_pos)
