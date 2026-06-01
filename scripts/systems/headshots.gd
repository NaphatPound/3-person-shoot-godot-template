extends Node
## Headshots (autoload) — rewards precision. Listens (lazily) to the player's hit_confirmed; a hostile
## hit landing above head_threshold counts a HEADSHOT and pays a gold bonus via Currency. Reads the hit
## point only — touches no existing node. Passive / key-free.

signal headshot(bonus: int)
signal changed

@export var head_threshold := 1.45    ## world Y above which a hit counts as a headshot
@export var bonus := 25

var count := 0
var _player: Node = null


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var p := get_tree().get_first_node_in_group(&"player")
		if p and p.has_signal("hit_confirmed") and not p.hit_confirmed.is_connected(_on_hit):
			p.hit_confirmed.connect(_on_hit)
			_player = p


func _on_hit(point: Vector3, hostile: bool) -> void:
	if hostile and point.y >= head_threshold:
		count += 1
		Currency.add(bonus)
		headshot.emit(bonus)
		changed.emit()
