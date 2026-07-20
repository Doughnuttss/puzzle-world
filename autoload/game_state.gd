extends Node

## Central progress / unlock state for hub + courts.

signal zone_unlocked(zone_id: String)
signal zone_completed(zone_id: String)
signal keys_changed

const SAVE_PATH := "user://save.json"

const ZONE_HUB := "hub"

## Play order (scaffolded learning curve).
const COURT_ORDER: Array[String] = [
	"hephaestus",
	"demeter",
	"apollo",
	"poseidon",
	"aphrodite",
	"artemis",
	"hera",
	"athena",
	"dionysus",
	"ares",
	"hermes",
	"zeus",
]

const COURT_META := {
	"hephaestus": {"name": "Hephaestus", "title": "The Ash Forge", "color": Color(0.85, 0.45, 0.2)},
	"demeter": {"name": "Demeter", "title": "The Grain Terrace", "color": Color(0.75, 0.7, 0.25)},
	"apollo": {"name": "Apollo", "title": "The Sun Colonnade", "color": Color(1.0, 0.92, 0.45)},
	"poseidon": {"name": "Poseidon", "title": "The Quaking Harbor", "color": Color(0.25, 0.55, 0.75)},
	"aphrodite": {"name": "Aphrodite", "title": "The Mirror Garden", "color": Color(0.95, 0.55, 0.7)},
	"artemis": {"name": "Artemis", "title": "The Moonlit Hunt", "color": Color(0.7, 0.8, 0.9)},
	"hera": {"name": "Hera", "title": "The Vow Hall", "color": Color(0.65, 0.45, 0.85)},
	"athena": {"name": "Athena", "title": "The Olive Oracle", "color": Color(0.45, 0.65, 0.4)},
	"dionysus": {"name": "Dionysus", "title": "The Revel Theater", "color": Color(0.7, 0.25, 0.45)},
	"ares": {"name": "Ares", "title": "The Clash Yard", "color": Color(0.75, 0.2, 0.15)},
	"hermes": {"name": "Hermes", "title": "The Crossroads", "color": Color(0.7, 0.55, 0.3)},
	"zeus": {"name": "Zeus", "title": "The Thunder Throne", "color": Color(0.85, 0.9, 1.0)},
}

## First court only at new game.
var unlocked_zones: Array[String] = ["hephaestus"]
var completed_zones: Array[String] = []
var keys: Array[String] = []
var spawn_point_id: String = "default"
var current_zone_id: String = ZONE_HUB


func _ready() -> void:
	load_game()


func get_court_meta(zone_id: String) -> Dictionary:
	return COURT_META.get(zone_id, {"name": zone_id, "title": zone_id, "color": Color.WHITE})


func is_zone_unlocked(zone_id: String) -> bool:
	return zone_id in unlocked_zones or zone_id == ZONE_HUB


func unlock_zone(zone_id: String) -> void:
	if zone_id in unlocked_zones:
		return
	unlocked_zones.append(zone_id)
	zone_unlocked.emit(zone_id)
	save_game()


func complete_zone(zone_id: String) -> void:
	if zone_id not in completed_zones:
		completed_zones.append(zone_id)
		zone_completed.emit(zone_id)

	var idx := COURT_ORDER.find(zone_id)
	if idx >= 0 and idx + 1 < COURT_ORDER.size():
		unlock_zone(COURT_ORDER[idx + 1])
	save_game()


func has_key(key_id: String) -> bool:
	return key_id in keys


func grant_key(key_id: String) -> void:
	if key_id in keys:
		return
	keys.append(key_id)
	keys_changed.emit()
	save_game()


func set_spawn_point(point_id: String) -> void:
	spawn_point_id = point_id


func save_game() -> void:
	var data := {
		"unlocked_zones": unlocked_zones,
		"completed_zones": completed_zones,
		"keys": keys,
		"spawn_point_id": spawn_point_id,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save game: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	unlocked_zones.assign(data.get("unlocked_zones", ["hephaestus"]))
	completed_zones.assign(data.get("completed_zones", []))
	keys.assign(data.get("keys", []))
	spawn_point_id = str(data.get("spawn_point_id", "default"))


func reset_progress() -> void:
	unlocked_zones = ["hephaestus"]
	completed_zones = []
	keys = []
	spawn_point_id = "default"
	save_game()
