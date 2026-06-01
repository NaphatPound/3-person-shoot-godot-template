extends Node
## Quests (autoload) — a simple objective system. Quests are active from the start; progress is read by
## listening to EXISTING signals (Inventory.changed, Currency.changed, the player's hit_confirmed) —
## never by modifying those systems. When an objective is met the quest auto-completes and grants its
## reward (gold and/or an item). QuestTracker renders it. Ties the loot/merchant/combat systems together
## (collect found items, hold gold from selling, shoot zombies).

signal changed
signal quest_completed(id: StringName)

enum Type { COLLECT, HUNT, REACH_GOLD }

const DEFS := [
	{ "id": &"q_scrap", "type": Type.COLLECT, "target_id": &"scrap", "target": 3,
	  "title": "Scavenger", "desc": "Gather 3 Scrap Metal.", "gold": 150 },
	{ "id": &"q_hunt", "type": Type.HUNT, "target": 5,
	  "title": "Cull the Horde", "desc": "Shoot 5 zombies.", "gold": 200, "item": &"ammo_9mm", "count": 15 },
	{ "id": &"q_gold", "type": Type.REACH_GOLD, "target": 500,
	  "title": "Deep Pockets", "desc": "Hold 500 gold at once (sell loot to the merchant).", "item": &"herb_green", "count": 2 },
	{ "id": &"q_gem", "type": Type.COLLECT, "target_id": &"gem_blue", "target": 1,
	  "title": "Treasure Hunter", "desc": "Find a Blue Gem.", "gold": 300 },
]

var _progress: Dictionary = {}   # id -> int
var _done: Dictionary = {}       # id -> bool
var _hunt := 0
var _player: Node = null
var _busy := false


func _ready() -> void:
	for d in DEFS:
		_progress[d["id"]] = 0
		_done[d["id"]] = false
	Inventory.changed.connect(_reeval)
	Currency.changed.connect(func(_a): _reeval())
	_reeval()


func _process(_delta: float) -> void:
	# lazily hook the player's hit signal once it exists (additive — no edit to player.gd)
	if _player == null or not is_instance_valid(_player):
		var p := get_tree().get_first_node_in_group(&"player")
		if p and p.has_signal("hit_confirmed") and not p.hit_confirmed.is_connected(_on_hit):
			p.hit_confirmed.connect(_on_hit)
			_player = p


func _on_hit(_point: Vector3, hostile: bool) -> void:
	if hostile:
		_hunt += 1
		_reeval()


func _reeval() -> void:
	if _busy:
		return
	_busy = true
	for d in DEFS:
		var id: StringName = d["id"]
		if _done[id]:
			continue
		var prog := _current_progress(d)
		_progress[id] = prog
		if prog >= int(d["target"]):
			_complete(d)
	_busy = false
	changed.emit()


func _current_progress(d: Dictionary) -> int:
	match int(d["type"]):
		Type.COLLECT: return Inventory.count_of(d["target_id"])
		Type.HUNT: return _hunt
		Type.REACH_GOLD: return Currency.amount
	return 0


func _complete(d: Dictionary) -> void:
	var id: StringName = d["id"]
	_done[id] = true
	_progress[id] = int(d["target"])
	if d.has("gold"):
		Currency.add(int(d["gold"]))
	if d.has("item"):
		Inventory.add(d["item"], int(d.get("count", 1)))
	quest_completed.emit(id)


# --- read API for the UI ---
func all_defs() -> Array:
	return DEFS

func active_defs() -> Array:
	var out := []
	for d in DEFS:
		if not _done[d["id"]]:
			out.append(d)
	return out

func is_done(id: StringName) -> bool:
	return _done.get(id, false)

func progress_of(id: StringName) -> int:
	return _progress.get(id, 0)

func target_of(d: Dictionary) -> int:
	return int(d["target"])
