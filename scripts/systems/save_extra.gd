extends Node
## SaveExtra (autoload) — extended persistence. Hooks SaveSystem's `saved`/`loaded` signals (so [F5]/[F9]
## just work) and writes/reads a SECOND file (user://savegame_extra.json) covering everything #9 misses:
## the Storage stash, Stats/achievements, Perks, day/time, infection, the perk/difficulty-tuned values
## (capacity, regen, max health, hunger drain, horde knobs...), and the kill/open counters. Reads/writes
## only public surfaces of the other autoloads — it does NOT edit SaveSystem or any other source.
## Loaded LAST so every system it touches exists, and its loaded-handler runs after #9's restore.

const SAVE_PATH := "user://savegame_extra.json"


func _ready() -> void:
	SaveSystem.saved.connect(func(): save_extra())
	SaveSystem.loaded.connect(func(): load_extra())


func save_extra() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(_collect(), "\t"))
	f.close()
	return true


func load_extra() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY:
		return false
	_apply(d)
	return true


func _collect() -> Dictionary:
	var storage := {}
	for id in Storage._items:
		storage[String(id)] = int(Storage._items[id])
	var stats_unlocked := []
	for id in Stats._unlocked:
		if Stats._unlocked[id]:
			stats_unlocked.append(String(id))
	var perks_owned := []
	for id in Perks._unlocked:
		if Perks._unlocked[id]:
			perks_owned.append(String(id))

	return {
		"storage": storage,
		"stats": Stats.stats.duplicate(),
		"stats_unlocked": stats_unlocked,
		"perk_sp": Perks.sp,
		"perks_owned": perks_owned,
		"daynight": { "day": DayNight.day, "t": DayNight.t },
		"difficulty_day": Difficulty._day,
		"infection": Infection.level,
		"tuning": {
			"inv_capacity": Inventory.capacity,
			"stamina_regen": Stamina.regen_rate,
			"stamina_drain": Stamina.drain_rate,
			"max_health": SurvivalStats.max_health,
			"health_per_heal": SurvivalStats.health_per_heal,
			"hunger_drain": SurvivalStats.hunger_drain_per_sec,
			"noise_decay": NoiseMeter.decay,
			"horde_cap": Horde.alive_cap,
			"horde_base": Horde.base_interval,
			"horde_night": Horde.night_interval,
		},
		"counters": {
			"traps": Traps.kills, "assists": Companions.assists,
			"molotov": Molotovs.kills, "grenade": Grenades.kills, "crates": Crates.opened,
		},
	}


func _apply(d: Dictionary) -> void:
	# Storage stash
	Storage._items.clear()
	for k in d.get("storage", {}):
		Storage._items[StringName(k)] = int(d["storage"][k])
	Storage.changed.emit()

	# Stats + achievements
	for k in d.get("stats", {}):
		Stats.stats[k] = int(d["stats"][k])
	for id in d.get("stats_unlocked", []):
		Stats._unlocked[StringName(id)] = true
	Stats.changed.emit()

	# Perks (SP + owned flags; effects come back via the saved tuning values below)
	Perks.sp = int(d.get("perk_sp", Perks.sp))
	for id in d.get("perks_owned", []):
		Perks._unlocked[StringName(id)] = true
	Perks.changed.emit()

	# Time of day
	var dn = d.get("daynight", {})
	DayNight.day = int(dn.get("day", DayNight.day))
	DayNight.t = float(dn.get("t", DayNight.t))

	# Tuning values (preserve perk + difficulty effects without re-applying)
	var tn = d.get("tuning", {})
	if tn.has("inv_capacity"):
		Inventory.capacity = int(tn["inv_capacity"])
		Inventory._slots.resize(Inventory.capacity)
		Inventory.changed.emit()
	Stamina.regen_rate = float(tn.get("stamina_regen", Stamina.regen_rate))
	Stamina.drain_rate = float(tn.get("stamina_drain", Stamina.drain_rate))
	SurvivalStats.max_health = float(tn.get("max_health", SurvivalStats.max_health))
	SurvivalStats.health_per_heal = float(tn.get("health_per_heal", SurvivalStats.health_per_heal))
	SurvivalStats.hunger_drain_per_sec = float(tn.get("hunger_drain", SurvivalStats.hunger_drain_per_sec))
	NoiseMeter.decay = float(tn.get("noise_decay", NoiseMeter.decay))
	Horde.alive_cap = int(tn.get("horde_cap", Horde.alive_cap))
	Horde.base_interval = float(tn.get("horde_base", Horde.base_interval))
	Horde.night_interval = float(tn.get("horde_night", Horde.night_interval))

	# Difficulty day (kept in sync with DayNight so it won't immediately re-scale the restored tuning)
	Difficulty._day = int(d.get("difficulty_day", Difficulty._day))

	# Infection
	Infection.level = float(d.get("infection", Infection.level))
	Infection.changed.emit(Infection.level)

	# Counters
	var cn = d.get("counters", {})
	Traps.kills = int(cn.get("traps", Traps.kills))
	Companions.assists = int(cn.get("assists", Companions.assists))
	Molotovs.kills = int(cn.get("molotov", Molotovs.kills))
	Grenades.kills = int(cn.get("grenade", Grenades.kills))
	Crates.opened = int(cn.get("crates", Crates.opened))
