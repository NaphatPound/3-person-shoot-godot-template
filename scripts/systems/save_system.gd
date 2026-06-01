extends Node
## SaveSystem (autoload) — snapshots every survival system to user://savegame.json and restores it.
## [F5] quick-save, [F9] quick-load. Reads/writes the other autoloads through their public surface
## (vars + signals); it never edits their source. During a load it sets Quests._busy so the multi-step
## restore (inventory -> currency -> ...) can't trigger spurious quest completions/rewards, then clears
## it and refreshes. Loaded last in the autoload list so every system it touches already exists.

signal saved
signal loaded
signal load_failed

const SAVE_PATH := "user://savegame.json"


func _enter_tree() -> void:
	_ensure(&"quick_save", KEY_F5)
	_ensure(&"quick_load", KEY_F9)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quick_save"):
		save_game()
	elif event.is_action_pressed(&"quick_load"):
		load_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_collect(), "\t"))
	f.close()
	saved.emit()
	return true


func load_game() -> bool:
	if not has_save():
		load_failed.emit()
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		load_failed.emit()
		return false
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		load_failed.emit()
		return false
	_apply(data)
	loaded.emit()
	return true


func _collect() -> Dictionary:
	var inv := []
	for s in Inventory.get_slots():
		if s != null:
			inv.append({ "id": String(s["id"]), "count": int(s["count"]) })

	var weapons := {}
	for wid in Weapons._levels:
		var levels := {}
		for tk in Weapons._levels[wid]:
			levels[String(tk)] = int(Weapons._levels[wid][tk])
		var atts := []
		for ak in Weapons._attachments.get(wid, {}):
			if Weapons._attachments[wid][ak]:
				atts.append(String(ak))
		weapons[String(wid)] = { "levels": levels, "attachments": atts }

	var qdone := []
	for id in Quests._done:
		if Quests._done[id]:
			qdone.append(String(id))
	var qprog := {}
	for id in Quests._progress:
		qprog[String(id)] = int(Quests._progress[id])

	return {
		"version": 1,
		"inventory": inv,
		"currency": Currency.amount,
		"survival": { "hunger": SurvivalStats.hunger, "health": SurvivalStats.health },
		"ammo": { "magazine": Ammo.magazine },
		"weapons": weapons,
		"quests": { "done": qdone, "progress": qprog, "hunt": Quests._hunt },
	}


func _apply(data: Dictionary) -> void:
	Quests._busy = true   # freeze quest re-evaluation through the whole multi-step restore

	# --- inventory: clear, then refill from save ---
	var totals := {}
	for s in Inventory.get_slots():
		if s != null:
			totals[s["id"]] = totals.get(s["id"], 0) + int(s["count"])
	for id in totals:
		Inventory.remove(id, totals[id])
	for entry in data.get("inventory", []):
		Inventory.add(StringName(entry["id"]), int(entry["count"]))

	# --- weapons ---
	var wdata = data.get("weapons", {})
	for wid_s in wdata:
		var wid := StringName(wid_s)
		if Weapons._levels.has(wid):
			for tk in wdata[wid_s].get("levels", {}):
				Weapons._levels[wid][tk] = int(wdata[wid_s]["levels"][tk])
			Weapons._attachments[wid] = {}
			for ak in wdata[wid_s].get("attachments", []):
				Weapons._attachments[wid][StringName(ak)] = true
	Weapons.changed.emit()

	# --- survival ---
	var sv = data.get("survival", {})
	SurvivalStats.hunger = clampf(float(sv.get("hunger", SurvivalStats.max_hunger)), 0.0, SurvivalStats.max_hunger)
	SurvivalStats.health = clampf(float(sv.get("health", SurvivalStats.max_health)), 0.0, SurvivalStats.max_health)
	SurvivalStats._alive = SurvivalStats.health > 0.0
	SurvivalStats.stats_changed.emit(SurvivalStats.hunger, SurvivalStats.health)

	# --- currency ---
	Currency.amount = maxi(0, int(data.get("currency", Currency.amount)))
	Currency.changed.emit(Currency.amount)

	# --- ammo ---
	Ammo.magazine = maxi(0, int(data.get("ammo", {}).get("magazine", Ammo.magazine)))
	Ammo.changed.emit()

	# --- quests ---
	var q = data.get("quests", {})
	for id in Quests._done:
		Quests._done[id] = false
	for id_s in q.get("done", []):
		Quests._done[StringName(id_s)] = true
	for id_s in q.get("progress", {}):
		Quests._progress[StringName(id_s)] = int(q["progress"][id_s])
	Quests._hunt = int(q.get("hunt", 0))

	Quests._busy = false
	Quests.changed.emit()


func _ensure(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var e := InputEventKey.new()
		e.physical_keycode = code
		InputMap.action_add_event(action, e)
