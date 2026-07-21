extends Node
class_name HestiaCourtController

## Wires Hestia panels, gating, conduit fire, and court completion.

const ZONE_ID := "hestia"
const TRIAD := ["1.1", "1.2", "1.3"]
const WALLS := ["1.4", "1.5", "1.6", "1.7"]
const ALTAR := ["1.8", "1.9"]
const ALL_IDS := ["1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7", "1.8", "1.9"]

var _panels: Dictionary = {}  # puzzle_id -> LineTracePanel
var _conduit_cold: StandardMaterial3D
var _conduit_hot: StandardMaterial3D


func _ready() -> void:
	_conduit_cold = _make_emissive(Color(0.35, 0.18, 0.08), 0.12)
	_conduit_hot = _make_emissive(Color(1.0, 0.45, 0.12), 1.6)
	call_deferred("_boot")


func _boot() -> void:
	await get_tree().process_frame
	_collect_panels()
	_apply_saved_progress()
	_refresh_gating()
	_refresh_fire_fx()


func _make_emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.35
	return m


func _collect_panels() -> void:
	_panels.clear()
	for node in get_tree().get_nodes_in_group("line_trace_panel"):
		if node is LineTracePanel:
			var panel := node as LineTracePanel
			_panels[panel.puzzle_id] = panel
			if not panel.puzzle_solved.is_connected(_on_panel_solved):
				panel.puzzle_solved.connect(_on_panel_solved)


func _on_panel_solved(puzzle_id: String) -> void:
	GameState.mark_puzzle_solved(ZONE_ID, puzzle_id)
	_refresh_gating()
	_refresh_fire_fx()
	if _all_solved(ALTAR):
		GameState.complete_zone(ZONE_ID)


func _apply_saved_progress() -> void:
	for id in ALL_IDS:
		if GameState.is_puzzle_solved(ZONE_ID, id) and _panels.has(id):
			(_panels[id] as LineTracePanel).mark_solved(true)


func _refresh_gating() -> void:
	var triad_done := _all_solved(TRIAD)
	var walls_done := _all_solved(WALLS)
	for id in TRIAD:
		if _panels.has(id):
			(_panels[id] as LineTracePanel).set_unlocked(true)
	for id in WALLS:
		if _panels.has(id):
			var p := _panels[id] as LineTracePanel
			p.set_unlocked(triad_done or p.is_solved)
	for id in ALTAR:
		if _panels.has(id):
			var p := _panels[id] as LineTracePanel
			p.set_unlocked(walls_done or p.is_solved)


func _all_solved(ids: Array) -> bool:
	for id in ids:
		if not GameState.is_puzzle_solved(ZONE_ID, str(id)):
			return false
	return true


func _refresh_fire_fx() -> void:
	var triad_done := _all_solved(TRIAD)
	var walls_done := _all_solved(WALLS)
	var altar_done := _all_solved(ALTAR)

	for i in 3:
		var pid := "1.%d" % (i + 1)
		var lit := GameState.is_puzzle_solved(ZONE_ID, pid)
		_set_conduit_lit("Pillar_1_%d" % (i + 1), lit)

	# Side panels: left arches = 1.4 (rear), 1.5 (outer); right = 1.6, 1.7
	var side_map := {
		"Panel_-1_0": "1.4",
		"Panel_-1_1": "1.5",
		"Panel_1_0": "1.6",
		"Panel_1_1": "1.7",
		"PanelRiser_-1_0": "1.4",
		"PanelRiser_-1_1": "1.5",
		"PanelRiser_1_0": "1.6",
		"PanelRiser_1_1": "1.7",
	}
	for seg_name in side_map.keys():
		var pid: String = side_map[seg_name]
		_set_conduit_lit(seg_name, GameState.is_puzzle_solved(ZONE_ID, pid))

	_set_conduit_lit("Altar", walls_done or altar_done)
	_set_torches_lit(triad_done)
	_set_altar_flame(altar_done)


func _set_conduit_lit(seg_name: String, lit: bool) -> void:
	var node := _find_generated(seg_name)
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = _conduit_hot if lit else _conduit_cold


func _set_torches_lit(lit: bool) -> void:
	for node in get_tree().get_nodes_in_group("hestia_torch_light"):
		if node is OmniLight3D:
			(node as OmniLight3D).light_energy = 1.6 if lit else 0.15
	for node in get_tree().get_nodes_in_group("hestia_torch_flame"):
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			if mesh.material_override is StandardMaterial3D:
				var mat := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.emission_energy_multiplier = 1.8 if lit else 0.2
				mesh.material_override = mat


func _set_altar_flame(lit: bool) -> void:
	var altar := _find_generated("EternalFlameAltar")
	if altar == null:
		return
	var light := altar.get_node_or_null("AltarLight")
	if light is OmniLight3D:
		(light as OmniLight3D).light_energy = 3.2 if lit else 0.6
	var flame := altar.get_node_or_null("AltarFlame")
	if flame is MeshInstance3D:
		var mesh := flame as MeshInstance3D
		if mesh.material_override is StandardMaterial3D:
			var mat := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.emission_energy_multiplier = 2.4 if lit else 0.5
			mesh.material_override = mat


func _find_generated(node_name: String) -> Node:
	var builder := get_parent().get_node_or_null("CourtBuilder")
	if builder == null:
		builder = get_tree().current_scene.find_child("CourtBuilder", true, false)
	if builder == null:
		return null
	return builder.find_child(node_name, true, false)
