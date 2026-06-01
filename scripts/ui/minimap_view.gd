extends Control
class_name MinimapView
## A top-down radar drawn in code (north-up): player at center, live blips for zombies / merchant /
## storage / loot / traps read from their groups each frame. Pure HUD — reads world positions only and
## modifies nothing.

@export var view_range := 18.0     ## world metres from center to the map edge

const GROUP_COLORS := {
	"dummy": Color(1, 0.3, 0.3),
	"merchant": Color(0.7, 0.45, 1.0),
	"storage": Color(0.9, 0.65, 0.3),
	"pickup": Color(0.95, 0.9, 0.4),
	"trap": Color(1.0, 0.6, 0.2),
}


func _process(_delta: float) -> void:
	queue_redraw()


## World position -> map-local pixel (north-up: world +Z maps downward).
func blip_pos(world: Vector3, origin: Vector3) -> Vector2:
	var rel := world - origin
	return size * 0.5 + Vector2(rel.x, rel.z) / view_range * (size.x * 0.5)


func _draw() -> void:
	var r := size.x * 0.5
	var c := size * 0.5
	draw_circle(c, r, Color(0, 0, 0, 0.5))
	draw_arc(c, r - 1.0, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 1.5)

	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return
	var origin := player.global_position

	for g in GROUP_COLORS:
		var col: Color = GROUP_COLORS[g]
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D and is_instance_valid(n) and n != player:
				var p := blip_pos((n as Node3D).global_position, origin)
				var off := p - c
				if off.length() <= r - 3.0:
					draw_circle(p, 3.0, col)
				else:
					draw_circle(c + off.normalized() * (r - 3.0), 2.0, Color(col, 0.5))

	# player marker — a small triangle at center
	var tri := PackedVector2Array([c + Vector2(0, -5), c + Vector2(-4, 4), c + Vector2(4, 4)])
	draw_colored_polygon(tri, Color(1, 1, 1))
