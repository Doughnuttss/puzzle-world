extends Node
class_name HestiaCourtController

## Wires Hestia panels, gating, conduit fire, hearth reveal, and court completion.

const ZONE_ID := "hestia"
const BASIC := ["1.1", "1.2", "1.3"]
const INTERMEDIATE := ["1.4", "1.5", "1.6", "1.7"]
const ADVANCED := ["1.8", "1.9", "1.10", "1.11"]
const EXPERT := ["1.12", "1.13"]
const ALL_IDS := [
	"1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7",
	"1.8", "1.9", "1.10", "1.11", "1.12", "1.13",
]
const HEARTH_REVEAL_SEC := 3.6
const ADV_DIM_PAUSE_SEC := 1.4
const ADV_LIGHT_STEP_SEC := 0.85
const EXPERT_EMERGE_SEC := 2.8

var _panels: Dictionary = {}  # puzzle_id -> LineTracePanel
var _conduit_cold: StandardMaterial3D
var _conduit_hot: StandardMaterial3D
var _hearth_revealed: bool = false
## True only after the rise finishes (or on load snap) — gates the center flame.
var _hearth_rise_complete: bool = false
var _hearth_tween: Tween
## After Intermediate max fire: how many Advanced arches have been lit/unlocked (0..4).
var _adv_enabled_count: int = 0
var _adv_reveal_tween: Tween
var _experts_emerged: bool = false
var _expert_tween: Tween


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
	_set_hearth_revealed(_all_solved(BASIC), false)
	# Snap advanced reveal if Intermediate was already cleared in a prior session.
	if _all_solved(INTERMEDIATE):
		_adv_enabled_count = ADVANCED.size()
		_refresh_gating()
		_apply_advanced_torch_state()
	else:
		_adv_enabled_count = 0
		_set_all_advanced_torches(false)
	_refresh_statue_eyes()
	_set_experts_emerged(_all_solved(ADVANCED), false)


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
	if _panels.has(puzzle_id):
		var panel := _panels[puzzle_id] as LineTracePanel
		var path := panel.get_display_path()
		if path.size() >= 2:
			GameState.set_puzzle_path(ZONE_ID, puzzle_id, path)
	GameState.mark_puzzle_solved(ZONE_ID, puzzle_id)

	var basic_done := _all_solved(BASIC)
	var mid_done := _all_solved(INTERMEDIATE)
	var adv_done := _all_solved(ADVANCED)
	_refresh_gating()
	_refresh_fire_fx()
	if basic_done:
		_set_hearth_revealed(true, true)

	if mid_done and _adv_enabled_count < ADVANCED.size():
		_start_advanced_reveal_sequence()

	_refresh_statue_eyes()
	if adv_done and not _experts_emerged:
		_set_experts_emerged(true, true)

	if _all_solved(EXPERT):
		GameState.complete_zone(ZONE_ID)


func _apply_saved_progress() -> void:
	for id in ALL_IDS:
		if GameState.is_puzzle_solved(ZONE_ID, id) and _panels.has(id):
			var panel := _panels[id] as LineTracePanel
			panel.set_solved_path(GameState.get_puzzle_path(ZONE_ID, id))
			panel.mark_solved(true)


func _refresh_gating() -> void:
	var basic_done := _all_solved(BASIC)
	var mid_done := _all_solved(INTERMEDIATE)
	for id in BASIC:
		if _panels.has(id):
			(_panels[id] as LineTracePanel).set_unlocked(true)
	for id in INTERMEDIATE:
		if _panels.has(id):
			var p := _panels[id] as LineTracePanel
			p.set_unlocked((basic_done and _hearth_revealed) or p.is_solved)
	for i in ADVANCED.size():
		var id: String = ADVANCED[i]
		if not _panels.has(id):
			continue
		var p := _panels[id] as LineTracePanel
		p.set_unlocked(p.is_solved or (mid_done and i < _adv_enabled_count))
	for id in EXPERT:
		if _panels.has(id):
			var p := _panels[id] as LineTracePanel
			p.set_unlocked((_experts_emerged) or p.is_solved)


func _all_solved(ids: Array) -> bool:
	for id in ids:
		if not GameState.is_puzzle_solved(ZONE_ID, str(id)):
			return false
	return true


func _count_solved(ids: Array) -> int:
	var n := 0
	for id in ids:
		if GameState.is_puzzle_solved(ZONE_ID, str(id)):
			n += 1
	return n


func _set_hearth_revealed(revealed: bool, animate: bool) -> void:
	if revealed == _hearth_revealed and animate:
		return
	var was_revealed := _hearth_revealed
	_hearth_revealed = revealed

	var platform := _find_generated("InnerPlatform") as Node3D
	var tablets := _find_generated("HearthTablets") as Node3D
	if platform == null or tablets == null:
		return

	var p_sunk: float = float(platform.get_meta("sunk_y", platform.position.y))
	var p_raised: float = float(platform.get_meta("raised_y", platform.position.y))
	var t_sunk: float = float(tablets.get_meta("sunk_y", tablets.position.y))
	var t_raised: float = float(tablets.get_meta("raised_y", tablets.position.y))
	var p_target := p_raised if revealed else p_sunk
	var t_target := t_raised if revealed else t_sunk

	if _hearth_tween != null and _hearth_tween.is_valid():
		_hearth_tween.kill()

	if animate and revealed and not was_revealed:
		_hearth_rise_complete = false
		_hide_hearth_flame()
		_hearth_tween = create_tween()
		_hearth_tween.set_parallel(true)
		_hearth_tween.set_ease(Tween.EASE_OUT)
		_hearth_tween.set_trans(Tween.TRANS_CUBIC)
		_hearth_tween.tween_property(platform, "position:y", p_target, HEARTH_REVEAL_SEC)
		_hearth_tween.tween_property(tablets, "position:y", t_target, HEARTH_REVEAL_SEC)
		_hearth_tween.chain().tween_callback(_on_hearth_reveal_finished)
	else:
		platform.position.y = p_target
		tablets.position.y = t_target
		_hearth_rise_complete = revealed
		_apply_tablet_interactable(revealed)
		_refresh_gating()
		_update_hearth_flame()

	_set_hearth_glow(revealed)


func _on_hearth_reveal_finished() -> void:
	_hearth_rise_complete = _hearth_revealed
	_apply_tablet_interactable(_hearth_revealed)
	_refresh_gating()
	_update_hearth_flame()


func _apply_tablet_interactable(enabled: bool) -> void:
	for id in INTERMEDIATE:
		if not _panels.has(id):
			continue
		var panel := _panels[id] as LineTracePanel
		if not panel.has_meta("hearth_tablet"):
			continue
		if enabled:
			panel.collision_layer = 1
			panel.monitorable = true
			panel.set_solid_enabled(true)
		else:
			panel.collision_layer = 0
			panel.monitorable = false
			panel.set_solid_enabled(false)


func _set_hearth_glow(lit: bool) -> void:
	var coals := _find_generated("HearthCoals")
	if coals is MeshInstance3D:
		var mesh := coals as MeshInstance3D
		var mat := StandardMaterial3D.new()
		if lit:
			mat.albedo_color = Color(0.45, 0.22, 0.08)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.1)
			mat.emission_energy_multiplier = 1.1
		else:
			mat.albedo_color = Color(0.12, 0.1, 0.08)
			mat.emission_enabled = false
		mat.roughness = 0.7
		mesh.material_override = mat


func _hide_hearth_flame() -> void:
	var flame := _find_generated("HearthFlame") as MeshInstance3D
	var light := _find_generated("HearthFlameLight") as OmniLight3D
	if flame:
		flame.visible = false
		flame.scale = Vector3(0.01, 0.01, 0.01)
	if light:
		light.light_energy = 0.0


func _update_hearth_flame() -> void:
	var flame := _find_generated("HearthFlame") as MeshInstance3D
	var light := _find_generated("HearthFlameLight") as OmniLight3D
	if flame == null:
		return

	if not _hearth_revealed or not _hearth_rise_complete:
		_hide_hearth_flame()
		return

	var mid_clears := _count_solved(INTERMEDIATE)
	# Stage 0 = just risen; each Intermediate clear grows the fire a lot.
	var stage := mid_clears  # 0..4
	var scales := [0.9, 2.2, 3.6, 5.2, 7.0]
	var s: float = scales[mini(stage, scales.size() - 1)]
	flame.visible = true
	flame.scale = Vector3(s, s * 1.35, s)
	if flame.material_override is StandardMaterial3D:
		var mat := (flame.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		mat.emission_energy_multiplier = 1.6 + float(stage) * 1.1
		flame.material_override = mat
	if light:
		light.light_energy = 1.4 + float(stage) * 2.2
		light.omni_range = 6.0 + float(stage) * 4.5


func _start_advanced_reveal_sequence() -> void:
	## Fire at max → dim the wall → light/unlock every Advanced arch one by one.
	if _adv_reveal_tween != null and _adv_reveal_tween.is_valid():
		_adv_reveal_tween.kill()
	_adv_enabled_count = 0
	_refresh_gating()
	_set_all_advanced_torches(false)

	_adv_reveal_tween = create_tween()
	_adv_reveal_tween.tween_interval(ADV_DIM_PAUSE_SEC)
	for i in ADVANCED.size():
		var idx := i
		_adv_reveal_tween.tween_callback(func(): _enable_advanced_step(idx))
		if i < ADVANCED.size() - 1:
			_adv_reveal_tween.tween_interval(ADV_LIGHT_STEP_SEC)


func _enable_advanced_step(index: int) -> void:
	_adv_enabled_count = index + 1
	_refresh_gating()
	_set_advanced_torches_for_id(ADVANCED[index], true)


func _apply_advanced_torch_state() -> void:
	for i in ADVANCED.size():
		_set_advanced_torches_for_id(ADVANCED[i], i < _adv_enabled_count)


func _set_all_advanced_torches(lit: bool) -> void:
	for id in ADVANCED:
		_set_advanced_torches_for_id(id, lit)


func _set_advanced_torches_for_id(puzzle_id: String, lit: bool) -> void:
	for node in get_tree().get_nodes_in_group("hestia_torch_light"):
		if node is OmniLight3D and str(node.get_meta("advanced_id", "")) == puzzle_id:
			(node as OmniLight3D).light_energy = 2.0 if lit else 0.06
	for node in get_tree().get_nodes_in_group("hestia_torch_flame"):
		if node is MeshInstance3D and str(node.get_meta("advanced_id", "")) == puzzle_id:
			var mesh := node as MeshInstance3D
			if mesh.material_override is StandardMaterial3D:
				var mat := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.emission_energy_multiplier = 2.2 if lit else 0.12
				mesh.material_override = mat


func _refresh_statue_eyes() -> void:
	for node in get_tree().get_nodes_in_group("hestia_statue_eye"):
		if not node is MeshInstance3D:
			continue
		var eye := node as MeshInstance3D
		var adv_id := str(eye.get_meta("advanced_id", ""))
		var lit := adv_id != "" and GameState.is_puzzle_solved(ZONE_ID, adv_id)
		var mat := StandardMaterial3D.new()
		if lit:
			mat.albedo_color = Color(1.0, 0.55, 0.18)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.45, 0.12)
			mat.emission_energy_multiplier = 3.4
		else:
			mat.albedo_color = Color(0.12, 0.1, 0.09)
			mat.emission_enabled = true
			mat.emission = Color(0.15, 0.08, 0.04)
			mat.emission_energy_multiplier = 0.05
		mat.roughness = 0.3
		eye.material_override = mat


func _set_experts_emerged(emerged: bool, animate: bool) -> void:
	if emerged == _experts_emerged and animate:
		return
	var was := _experts_emerged
	_experts_emerged = emerged

	var slides: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("hestia_expert_slide"):
		if node is Node3D:
			slides.append(node as Node3D)
	if slides.is_empty():
		_refresh_gating()
		return

	if _expert_tween != null and _expert_tween.is_valid():
		_expert_tween.kill()

	if animate and emerged and not was:
		_apply_expert_interactable(false)
		_expert_tween = create_tween()
		_expert_tween.set_parallel(true)
		_expert_tween.set_ease(Tween.EASE_OUT)
		_expert_tween.set_trans(Tween.TRANS_CUBIC)
		for slide in slides:
			var raised: float = float(slide.get_meta("revealed_z", slide.position.z))
			_expert_tween.tween_property(slide, "position:z", raised, EXPERT_EMERGE_SEC)
			if slide is StaticBody3D:
				(slide as StaticBody3D).collision_layer = 1
		_expert_tween.chain().tween_callback(_on_experts_emerged_finished)
	else:
		for slide in slides:
			var target: float = float(
				slide.get_meta("revealed_z" if emerged else "embedded_z", slide.position.z)
			)
			slide.position.z = target
			if slide is StaticBody3D:
				(slide as StaticBody3D).collision_layer = 1 if emerged else 0
		_apply_expert_interactable(emerged)
		_refresh_gating()


func _on_experts_emerged_finished() -> void:
	_apply_expert_interactable(_experts_emerged)
	_refresh_gating()


func _apply_expert_interactable(enabled: bool) -> void:
	for id in EXPERT:
		if not _panels.has(id):
			continue
		var panel := _panels[id] as LineTracePanel
		if not panel.has_meta("expert_panel"):
			continue
		if enabled:
			panel.collision_layer = 1
			panel.monitorable = true
			panel.set_solid_enabled(true)
		else:
			panel.collision_layer = 0
			panel.monitorable = false
			panel.set_solid_enabled(false)
		var remote := panel.get_node_or_null("RemoteInteract")
		if remote is Area3D:
			var area := remote as Area3D
			area.collision_layer = 1 if enabled else 0
			area.monitorable = enabled


func _refresh_fire_fx() -> void:
	var adv_done := _all_solved(ADVANCED)
	var expert_done := _all_solved(EXPERT)

	for i in 3:
		var pid := "1.%d" % (i + 1)
		var lit := GameState.is_puzzle_solved(ZONE_ID, pid)
		_set_conduit_lit("PillarConduit_1_%d" % (i + 1), lit)

	var side_map := {
		"TabletConduit_1_4": "1.4",
		"TabletConduit_1_5": "1.5",
		"TabletConduit_1_6": "1.6",
		"TabletConduit_1_7": "1.7",
	}
	for seg_name in side_map.keys():
		var pid: String = side_map[seg_name]
		_set_conduit_lit(seg_name, GameState.is_puzzle_solved(ZONE_ID, pid))

	_set_conduit_lit("Altar", adv_done or expert_done)
	_set_altar_flame(expert_done)
	_update_hearth_flame()
	if _adv_enabled_count > 0:
		_apply_advanced_torch_state()
	elif not _all_solved(INTERMEDIATE):
		_set_all_advanced_torches(false)


func _set_conduit_lit(seg_name: String, lit: bool) -> void:
	var node := _find_generated(seg_name)
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = _conduit_hot if lit else _conduit_cold


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
