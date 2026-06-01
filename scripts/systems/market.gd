extends Node
## Market (autoload) — a fluctuating economy over the Merchant. Each new day (polls DayNight.day) it
## drifts every merchant buy price (relative to captured base prices) and the sell_factor within bounds,
## so prices rise/fall day to day. Additive runtime tuning of Merchant's public vars — it does not edit
## the Merchant. Loaded LAST so it captures the FULL stock (after other systems append their items).

signal drifted(day: int)

var _base := {}            # id -> base buy price
var _base_sell := 0.5
var _day := -1


func _ready() -> void:
	for s in Merchant.get_stock():
		_base[s["id"]] = int(s["price"])
	_base_sell = Merchant.sell_factor
	_apply(maxi(1, DayNight.day))


func _process(_delta: float) -> void:
	if DayNight.day != _day:
		_apply(DayNight.day)


func _apply(day: int) -> void:
	_day = day
	for s in Merchant.get_stock():
		var id = s["id"]
		if _base.has(id):
			s["price"] = int(round(float(_base[id]) * _drift(id, day)))
	Merchant.sell_factor = clampf(_base_sell + 0.12 * sin(float(day) * 0.9), 0.4, 0.62)
	drifted.emit(day)


func _drift(id, day: int) -> float:
	var phase := float(hash(id) % 100) * 0.063
	return clampf(1.0 + 0.28 * sin(float(day) * 1.3 + phase), 0.7, 1.35)


## Average current/base ratio across the stock — a simple market index for display/hooks.
func price_index() -> float:
	var sum := 0.0
	var n := 0
	for s in Merchant.get_stock():
		if _base.has(s["id"]) and int(_base[s["id"]]) > 0:
			sum += float(s["price"]) / float(_base[s["id"]])
			n += 1
	return sum / float(maxi(1, n))
