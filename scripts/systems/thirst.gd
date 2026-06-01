extends Node
## Thirst (autoload) — a second survival stat parallel to Hunger. Thirst drains over time; when it drops
## past auto_drink_at it AUTO-drinks a Water item from the Inventory (key-free — the action keys are
## exhausted); if there's none and it hits 0, dehydration chips health via SurvivalStats. Registers a
## Water item (buyable/craftable). Touches no existing node.

signal changed(thirst: float)

@export var max_thirst := 100.0
@export var drain := 0.5             ## thirst/sec
@export var dehydrate_dps := 1.5     ## health/sec lost while fully dehydrated
@export var per_water := 60.0        ## thirst restored per Water
@export var auto_drink_at := 25.0    ## auto-drink when thirst drops to/under this

var thirst := 100.0


func _ready() -> void:
	thirst = max_thirst
	ItemDB.register(Item.make(&"water", "Water Bottle", Item.Category.MISC, 9, 30, "Drink to quench thirst (auto-used when low)."))
	Merchant.stock.append({ "id": &"water", "price": 35 })
	Crafting.recipes.append({ "id": &"r_water", "name": "Water Bottle", "inputs": { &"scrap": 1 }, "out": &"water", "count": 1 })
	changed.emit(thirst)


func _process(delta: float) -> void:
	thirst = maxf(0.0, thirst - drain * delta)
	if thirst <= auto_drink_at and Inventory.has(&"water", 1):
		Inventory.remove(&"water", 1)
		thirst = minf(max_thirst, thirst + per_water)
	if thirst <= 0.0:
		SurvivalStats.add_health(-dehydrate_dps * delta)
	changed.emit(thirst)


func drink() -> bool:
	if not Inventory.has(&"water", 1):
		return false
	Inventory.remove(&"water", 1)
	thirst = minf(max_thirst, thirst + per_water)
	changed.emit(thirst)
	return true


func is_dehydrated() -> bool:
	return thirst <= 0.0
