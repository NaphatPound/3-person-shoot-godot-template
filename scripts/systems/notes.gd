extends Node
## Notes (autoload) — collectible lore documents. Seeds a few NoteNodes (preset title/body) into the
## World scene; reading one ([E], via Interaction) opens it in NotesUI, marks it collected, and pays a
## small gold reward (which also nudges score via gold_earned). Tracks collected/total. Touches nothing.

signal opened(title: String, body: String)
signal changed

const WORLD_SCENE := "res://scenes/world.tscn"
const NOTES := [
	{ "title": "Day One", "body": "It started at the docks. We boarded the windows and held the safehouse three days before the radio went dead.", "pos": Vector3(5, 0, -5) },
	{ "title": "Lab Memo", "body": "Subject Ch-35 shows aggression spikes after dusk. Do NOT travel at night without a light.", "pos": Vector3(-5, 0, 5) },
	{ "title": "Scrawled Note", "body": "The merchant out west trades fair. Bring gems. Keep your blade close and your aim true.", "pos": Vector3(2, 0, 8) },
]

@export var reward := 50

var collected := 0
var _seeded: Node = null


func total() -> int:
	return NOTES.size()


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == _seeded:
		return
	_seeded = scene
	if scene.scene_file_path != WORLD_SCENE:
		return
	for d in NOTES:
		var n := NoteNode.new()
		n.title = d["title"]
		n.body = d["body"]
		scene.add_child(n)
		n.position = d["pos"]


func read(node) -> void:
	collected += 1
	Currency.add(reward)
	var t := "Note"
	var b := ""
	if node and is_instance_valid(node):
		t = node.title
		b = node.body
	opened.emit(t, b)
	changed.emit()
	if node and is_instance_valid(node):
		node.queue_free()
