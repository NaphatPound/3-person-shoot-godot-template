extends Node
## Currency (autoload) — the player's money (RE4-style pesetas / "gold"). Shared by the Merchant now
## and the weapon-upgrade system later. Pure data + a `changed` signal.

signal changed(amount: int)

@export var starting := 300
var amount := 0


func _ready() -> void:
	amount = starting
	changed.emit(amount)


func add(n: int) -> void:
	amount = maxi(0, amount + n)
	changed.emit(amount)


func can_afford(n: int) -> bool:
	return amount >= n


func spend(n: int) -> bool:
	if amount < n:
		return false
	amount -= n
	changed.emit(amount)
	return true
