extends Resource
class_name Item
## A single item DEFINITION (data only — no scene logic), shared by every gameplay system:
## Inventory holds stacks of these by id; the merchant, loot and quest systems (added later by the
## loop) all resolve item data through the ItemDB rather than hard-coding names. Kept a Resource so
## items can later live in .tres files or be authored in the editor.

enum Category { WEAPON, AMMO, HEAL, FOOD, MATERIAL, KEY, VALUABLE, MISC }

@export var id: StringName = &""              ## unique key, e.g. &"ammo_9mm"
@export var name: String = "Item"             ## display name
@export_multiline var description: String = ""
@export var category: Category = Category.MISC
@export var max_stack: int = 1                ## 1 = not stackable; >1 = stacks up to this many
@export var value: int = 0                    ## base trade value (the merchant system reads this)
@export var icon: Texture2D = null            ## optional; UI falls back to a category-colored cell


func is_stackable() -> bool:
	return max_stack > 1


## Convenience builder so the ItemDB can declare items in one tidy line.
static func make(p_id: StringName, p_name: String, p_cat: Category, p_stack: int, p_value: int, p_desc := "") -> Item:
	var it := Item.new()
	it.id = p_id
	it.name = p_name
	it.category = p_cat
	it.max_stack = p_stack
	it.value = p_value
	it.description = p_desc
	return it
