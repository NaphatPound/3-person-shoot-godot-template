extends Control
class_name CompassView
## A heading compass band: cardinal letters + objective bearings (merchant / extraction / safe-zone)
## scroll across as the camera turns. Center = straight ahead. Pure HUD — reads the camera + group
## positions; modifies nothing.

@export var half_fov := deg_to_rad(80.0)   ## angular half-width shown across the band


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.4))

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var fwd := -cam.global_transform.basis.z
	var heading := atan2(fwd.x, fwd.z)

	var cards := { "N": atan2(0.0, -1.0), "E": atan2(1.0, 0.0), "S": atan2(0.0, 1.0), "W": atan2(-1.0, 0.0) }
	for c in cards:
		var x := _bearing_x(cards[c], heading, w)
		if x >= 0.0:
			draw_line(Vector2(x, 0), Vector2(x, h * 0.5), Color(1, 1, 1, 0.6), 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(x - 5, h - 4), c, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))

	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player:
		_objective(player, &"merchant", Color(0.7, 0.45, 1.0), heading, w, h)
		_objective(player, &"extraction", Color(0.4, 1.0, 0.5), heading, w, h)
		_objective(player, &"safezone", Color(0.4, 0.9, 0.6), heading, w, h)

	draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, h), Color(1, 0.9, 0.3), 2.0)


func _objective(player: Node3D, grp: StringName, col: Color, heading: float, w: float, h: float) -> void:
	var nearest := _nearest(player, grp)
	if nearest == null:
		return
	var d := nearest.global_position - player.global_position
	var x := _bearing_x(atan2(d.x, d.z), heading, w)
	if x >= 0.0:
		draw_circle(Vector2(x, h * 0.5), 4.0, col)


func _nearest(player: Node3D, grp: StringName) -> Node3D:
	var best: Node3D = null
	var bd := INF
	for n in get_tree().get_nodes_in_group(grp):
		if n is Node3D and is_instance_valid(n):
			var dd := player.global_position.distance_squared_to((n as Node3D).global_position)
			if dd < bd:
				bd = dd
				best = n
	return best


## Map a world bearing angle to an x on the band, or -1.0 if outside the shown FOV.
func _bearing_x(angle: float, heading: float, w: float) -> float:
	var rel := wrapf(angle - heading, -PI, PI)
	if absf(rel) > half_fov:
		return -1.0
	return w * 0.5 + (rel / half_fov) * (w * 0.5)
