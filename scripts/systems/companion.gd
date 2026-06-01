extends Node3D
class_name CompanionNode
## A friendly ally that follows the player and shoots nearby zombies. Moves toward the player each frame
## (simple ground-level lerp, no physics) keeping follow_distance, and on a cooldown kills the nearest
## zombie (group "dummy") within attack_range (on_hit + free), reporting an assist to Companions.
## Self-builds a capsule body + muzzle flash + "ALLY" label; joins group "companion".

@export var follow_speed := 4.2
@export var follow_distance := 2.0
@export var attack_range := 9.0
@export var attack_cooldown := 1.1

var _cd := 0.0
var _muzzle: MeshInstance3D
var _flash_t := 0.0


func _ready() -> void:
	add_to_group(&"companion")

	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.6
	body.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 0.7)
	mat.emission_energy_multiplier = 0.35
	body.material_override = mat
	body.position = Vector3(0, 0.8, 0)
	add_child(body)

	_muzzle = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.12
	sph.height = 0.24
	_muzzle.mesh = sph
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(1, 0.9, 0.4)
	mm.emission_enabled = true
	mm.emission = Color(1, 0.85, 0.3)
	mm.emission_energy_multiplier = 3.0
	_muzzle.material_override = mm
	_muzzle.position = Vector3(0.25, 1.2, -0.3)
	_muzzle.visible = false
	add_child(_muzzle)

	var label := Label3D.new()
	label.text = "ALLY"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.95, 0)
	label.pixel_size = 0.006
	label.outline_size = 8
	add_child(label)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		var dist := to_player.length()
		if dist > follow_distance:
			global_position += to_player.normalized() * minf(follow_speed * delta, dist - follow_distance)
		global_position.y = 0.0

	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0 and _muzzle:
			_muzzle.visible = false

	_cd = maxf(0.0, _cd - delta)
	if _cd <= 0.0:
		var target := _nearest_dummy()
		if target != null:
			_shoot(target)
			_cd = attack_cooldown


func _nearest_dummy() -> Node3D:
	var best: Node3D = null
	var bd := attack_range * attack_range
	for z in get_tree().get_nodes_in_group(&"dummy"):
		if z is Node3D and is_instance_valid(z):
			var d := global_position.distance_squared_to((z as Node3D).global_position)
			if d <= bd:
				bd = d
				best = z
	return best


func _shoot(target: Node3D) -> void:
	if _muzzle:
		_muzzle.visible = true
		_flash_t = 0.08
	if target.has_method("on_hit"):
		target.on_hit()
	Companions.register_assist()
	target.queue_free()
