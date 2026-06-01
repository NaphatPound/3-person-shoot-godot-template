extends Node
## Stats (autoload) — accumulates gameplay stats purely by listening to EXISTING signals (player
## fired/hit_confirmed, Inventory.item_added, Currency.changed, Quests.quest_completed,
## Crafting.crafted) and unlocks named achievements when thresholds are crossed. Reads Traps.kills /
## Companions.assists for display. Never modifies those systems. StatsUI renders it ([Y]).

signal changed
signal achievement_unlocked(id: StringName, title: String)

const ACHIEVEMENTS := [
	{ "id": &"a_shots", "title": "Trigger Happy", "desc": "Fire 50 shots.", "stat": "shots", "target": 50 },
	{ "id": &"a_kills", "title": "Exterminator", "desc": "Land 25 hits on zombies.", "stat": "hits", "target": 25 },
	{ "id": &"a_items", "title": "Scavenger", "desc": "Gain 50 items.", "stat": "items", "target": 50 },
	{ "id": &"a_gold", "title": "Pesetas!", "desc": "Earn 1000 gold total.", "stat": "gold_earned", "target": 1000 },
	{ "id": &"a_quests", "title": "Questmaster", "desc": "Complete 4 quests.", "stat": "quests", "target": 4 },
	{ "id": &"a_craft", "title": "Tinkerer", "desc": "Craft 10 items.", "stat": "crafted", "target": 10 },
]

var stats := { "shots": 0, "hits": 0, "items": 0, "gold_earned": 0, "quests": 0, "crafted": 0 }
var _unlocked := {}
var _last_gold := 0
var _player: Node = null


func _ready() -> void:
	for a in ACHIEVEMENTS:
		_unlocked[a["id"]] = false
	_last_gold = Currency.amount
	Inventory.item_added.connect(func(_id, count): _add("items", count))
	Currency.changed.connect(_on_gold)
	Quests.quest_completed.connect(func(_id): _add("quests", 1))
	Crafting.crafted.connect(func(_id): _add("crafted", 1))


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var p := get_tree().get_first_node_in_group(&"player")
		if p and p.has_signal("fired") and not p.fired.is_connected(_on_fired):
			p.fired.connect(_on_fired)
			p.hit_confirmed.connect(_on_hit)
			_player = p


func _on_fired() -> void:
	_add("shots", 1)


func _on_hit(_point: Vector3, hostile: bool) -> void:
	if hostile:
		_add("hits", 1)


func _on_gold(amount: int) -> void:
	if amount > _last_gold:
		_add("gold_earned", amount - _last_gold)
	_last_gold = amount


func _add(key: String, n: int) -> void:
	stats[key] = stats.get(key, 0) + n
	_check()
	changed.emit()


func _check() -> void:
	for a in ACHIEVEMENTS:
		if not _unlocked[a["id"]] and stats.get(a["stat"], 0) >= int(a["target"]):
			_unlocked[a["id"]] = true
			achievement_unlocked.emit(a["id"], a["title"])


func is_unlocked(id: StringName) -> bool:
	return _unlocked.get(id, false)


func get_stat(key: String) -> int:
	return stats.get(key, 0)


func unlocked_count() -> int:
	var n := 0
	for id in _unlocked:
		if _unlocked[id]:
			n += 1
	return n
