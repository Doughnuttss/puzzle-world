extends Node

## Central progress / unlock state for hub + courts.

signal zone_unlocked(zone_id: String)
signal zone_completed(zone_id: String)
signal keys_changed

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 3

const ZONE_HUB := "hub"

## Play order — Tier 1 teach → Tier 4 finale (see COURT_META for themes).
const COURT_ORDER: Array[String] = [
	"hestia",      # 1  Tier 1 — branching lines (Witness)
	"hermes",      # 2  Tier 1 — timed lines
	"ares",        # 3  Tier 1 — parallel mirror movement
	"demeter",     # 4  Tier 2 — environmental routing (refreshment)
	"artemis",     # 5  Tier 2 — mirror + line-of-sight
	"hephaestus",  # 6  Tier 2 — mirrored line panels (grand integration)
	"apollo",      # 7  Tier 3 — color filter & partition
	"aphrodite",   # 8  Tier 3 — symmetrical mirror (refreshment)
	"athena",      # 9  Tier 3 — sequential / chess pathing
	"poseidon",    # 10 Tier 4 — vertical mirror & drift
	"hera",        # 11 Tier 4 — dual phantom multi-axis
	"zeus",        # 12 Tier 4 — final exam (5 mega-puzzles)
]

## name / title = hub labels; theme = environment note; tier + verb = design reference.
const COURT_META := {
	"hestia": {
		"name": "Hestia", "title": "The Hearth Megaron", "tier": 1, "puzzles": 9,
		"verb": "Branching lines",
		"theme": "Classical Greek megaron — terracotta, wooden beams, cold sunken hearth; fire spreads through copper floor conduits to bronze wall torches.",
		"color": Color(0.9, 0.45, 0.2),
	},
	"hermes": {
		"name": "Hermes", "title": "The Cloud Bridge", "tier": 1, "puzzles": 8,
		"verb": "Timed lines",
		"theme": "Open-air marble bridge above endless clouds — white Pentelic stone, gold wings, long morning shadows.",
		"color": Color(0.7, 0.55, 0.3),
	},
	"ares": {
		"name": "Ares", "title": "The Obsidian Phalanx", "tier": 1, "puzzles": 8,
		"verb": "Parallel mirror movement",
		"theme": "Brutalist obsidian fortress courtyard — blood-red mirror trench, bleeding sunset, crimson phantom phalanx.",
		"color": Color(0.75, 0.2, 0.15),
	},
	"demeter": {
		"name": "Demeter", "title": "The Living Garden", "tier": 2, "puzzles": 9,
		"verb": "Environmental routing",
		"theme": "Overgrown multi-tier botanical sanctuary — vine-wrapped ruins, irrigation trenches, dappled sunlight (refreshment court).",
		"color": Color(0.75, 0.7, 0.25),
	},
	"artemis": {
		"name": "Artemis", "title": "The Moonlit Hunt", "tier": 2, "puzzles": 9,
		"verb": "Mirror + line-of-sight",
		"theme": "Dense midnight pine forest — glowing blue moss, oversized silver moon, wolf vision cones.",
		"color": Color(0.7, 0.8, 0.9),
	},
	"hephaestus": {
		"name": "Hephaestus", "title": "The Volcanic Forge", "tier": 2, "puzzles": 10,
		"verb": "Mirrored line controls",
		"theme": "Subterranean industrial foundry — magma rivers, iron grates, bronze gears, automaton assembly (grand integration).",
		"color": Color(0.85, 0.45, 0.2),
	},
	"apollo": {
		"name": "Apollo", "title": "The Sun Amphitheater", "tier": 3, "puzzles": 9,
		"verb": "Color filter & partition",
		"theme": "Sun-drenched white marble amphitheater — crystal tripods, ceiling prisms, rainbow refractions.",
		"color": Color(1.0, 0.92, 0.45),
	},
	"aphrodite": {
		"name": "Aphrodite", "title": "The Mirror Garden", "tier": 3, "puzzles": 9,
		"verb": "Symmetrical mirror",
		"theme": "Decadent palace garden — pink quartz arches, roses, silver-rimmed mirrors, golden hour (refreshment court).",
		"color": Color(0.95, 0.55, 0.7),
	},
	"athena": {
		"name": "Athena", "title": "The Stone Library", "tier": 3, "puzzles": 10,
		"verb": "Sequential / chess pathing",
		"theme": "Towering ancient library — scroll shelves, dark granite chessboards, pale light beams.",
		"color": Color(0.45, 0.65, 0.4),
	},
	"poseidon": {
		"name": "Poseidon", "title": "The Sunken Temple", "tier": 4, "puzzles": 10,
		"verb": "Vertical mirror & drift",
		"theme": "Sunken temple in a pressurized air dome — whales outside, aquamarine light, overhead water tank mirror.",
		"color": Color(0.25, 0.55, 0.75),
	},
	"hera": {
		"name": "Hera", "title": "The Peacock Throne", "tier": 4, "puzzles": 10,
		"verb": "Dual phantom multi-axis",
		"theme": "Imperial throne room — deep purple, gold trim, peacock glass floors, stained-glass light (high integration).",
		"color": Color(0.65, 0.45, 0.85),
	},
	"zeus": {
		"name": "Zeus", "title": "The Storm Arena", "tier": 4, "puzzles": 5,
		"verb": "All mechanics — final exam",
		"theme": "Open-air arena atop storm clouds — golden conductor pillars, lightning arcs, eagle perch over the abyss.",
		"color": Color(0.85, 0.9, 1.0),
	},
}

## First court only at new game.
var unlocked_zones: Array[String] = ["hestia"]
var completed_zones: Array[String] = []
var keys: Array[String] = []
## zone_id -> Array of solved puzzle id strings (e.g. "1.1")
var solved_puzzles: Dictionary = {}
var spawn_point_id: String = "default"
var current_zone_id: String = ZONE_HUB


func _ready() -> void:
	# Keep listening for the dev reset hotkey even while puzzle UI pauses the tree.
	process_mode = Node.PROCESS_MODE_ALWAYS
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


func is_puzzle_solved(zone_id: String, puzzle_id: String) -> bool:
	var list: Array = solved_puzzles.get(zone_id, [])
	return puzzle_id in list


func mark_puzzle_solved(zone_id: String, puzzle_id: String) -> void:
	if not solved_puzzles.has(zone_id):
		solved_puzzles[zone_id] = []
	var list: Array = solved_puzzles[zone_id]
	if puzzle_id in list:
		return
	list.append(puzzle_id)
	solved_puzzles[zone_id] = list
	save_game()


func get_solved_puzzles(zone_id: String) -> Array:
	return solved_puzzles.get(zone_id, [])


func save_game() -> void:
	var data := {
		"save_version": SAVE_VERSION,
		"unlocked_zones": unlocked_zones,
		"completed_zones": completed_zones,
		"keys": keys,
		"solved_puzzles": solved_puzzles,
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
	var version := int(data.get("save_version", 1))
	if version < SAVE_VERSION:
		_migrate_save(data)
		return
	unlocked_zones.assign(data.get("unlocked_zones", ["hestia"]))
	completed_zones.assign(data.get("completed_zones", []))
	keys.assign(data.get("keys", []))
	solved_puzzles = data.get("solved_puzzles", {})
	spawn_point_id = str(data.get("spawn_point_id", "default"))


func _migrate_save(old_data: Dictionary) -> void:
	var version := int(old_data.get("save_version", 1))
	if version < 2:
		# Court order changed (v2): reset progress; Hestia is first court.
		unlocked_zones = ["hestia"]
		completed_zones = []
		keys = []
		solved_puzzles = {}
		spawn_point_id = "default"
		save_game()
		return
	# v2 -> v3: keep progress, add empty puzzle map.
	unlocked_zones.assign(old_data.get("unlocked_zones", ["hestia"]))
	completed_zones.assign(old_data.get("completed_zones", []))
	keys.assign(old_data.get("keys", []))
	solved_puzzles = old_data.get("solved_puzzles", {})
	spawn_point_id = str(old_data.get("spawn_point_id", "default"))
	save_game()


func reset_progress() -> void:
	unlocked_zones = ["hestia"]
	completed_zones = []
	keys = []
	solved_puzzles = {}
	spawn_point_id = "default"
	save_game()
	print("[DEV] Progress reset — only Hestia unlocked.")


func _unhandled_input(event: InputEvent) -> void:
	# Dev-only: Ctrl+Shift+R wipes save and reloads the current scene.
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and event.ctrl_pressed and event.shift_pressed:
			reset_progress()
			get_tree().reload_current_scene()
			get_viewport().set_input_as_handled()
