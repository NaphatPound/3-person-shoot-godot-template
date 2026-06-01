extends Node
## Merchant (autoload) — the buy/sell economy layered on Inventory + Currency. The merchant SELLS a
## fixed `stock` at buy_price, and BUYS any valued item from the player at `sell_factor` of its
## Item.value (so loot found in the world — gems, scrap — turns into gold). Pure logic; MerchantUI
## drives it. Touches no existing system.

@export var sell_factor := 0.5     ## fraction of Item.value the player receives when selling

# What the merchant offers; `price` is what the player pays to buy one.
var stock := [
	{ "id": &"ammo_9mm", "price": 10 },
	{ "id": &"ration", "price": 70 },
	{ "id": &"herb_green", "price": 150 },
]


func get_stock() -> Array:
	return stock


func buy_price(id: StringName) -> int:
	for s in stock:
		if s["id"] == id:
			return s["price"]
	var item: Item = ItemDB.get_item(id)
	return item.value if item else 0


func sell_price(id: StringName) -> int:
	var item: Item = ItemDB.get_item(id)
	if item == null:
		return 0
	return int(round(item.value * sell_factor))


## Player buys one of `id`. Returns true on success (enough gold AND room in the bag).
func buy(id: StringName) -> bool:
	var price := buy_price(id)
	if not Currency.can_afford(price):
		return false
	if Inventory.add(id, 1) != 0:
		return false      # bag full — nothing was added, so charge nothing
	Currency.spend(price)
	return true


## Player sells one of `id`. Returns the gold earned (0 = couldn't).
func sell(id: StringName) -> int:
	if not Inventory.has(id, 1):
		return 0
	var price := sell_price(id)
	if Inventory.remove(id, 1):
		Currency.add(price)
		return price
	return 0
