extends Area3D

## Floor pad: stepping here raises a rectangular stele from flush-with-ground to upright.
## Press E while on the pad (or looking at the stele) to teleport.
## Cleared courts keep the stele permanently risen (no proximity animation).

@export var destination_scene_id: String = "hestia"
@export var destination_spawn_id: String = "from_hub"
@export var require_unlocked: bool = true
@export var open_prompt: String = "Press E — Enter"
@export var locked_prompt: String = "Sealed"
@export var cleared_prompt: String = ""
@export var stele_height: float = 1.35
@export var rise_seconds: float = 0.45

@onready var _stele: StaticBody3D = $Stele
@onready var _stele_mesh: MeshInstance3D = $Stele/MeshInstance3D
@onready var _label: Label3D = $Stele/Label3D
@onready var _pad_mesh: MeshInstance3D = $PadMesh

## Buried: top of stele flush with pad. Raised: bottom rests on pad (not floating).
var _buried_y: float = 0.0
var _raised_y: float = 0.0
var _players_inside: int = 0
var _raised: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("monument_pad")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false

	_buried_y = -stele_height + 0.04  # top barely flush with surface
	_raised_y = 0.04                  # sits on the pad

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_stele.collision_layer = 0
	_stele.collision_mask = 0
	_stele.position = Vector3(0.0, _buried_y, 0.1)

	_refresh_pad()
	_refresh_label()

	if not GameState.zone_unlocked.is_connected(_on_progress):
		GameState.zone_unlocked.connect(_on_progress)
	if not GameState.zone_completed.is_connected(_on_progress):
		GameState.zone_completed.connect(_on_progress)
	# Permanent-raised state is applied from GodShrine.setup → refresh_visuals
	# (destination_scene_id is configured after this node enters the tree).


func _on_progress(_zone_id: String = "") -> void:
	_refresh_pad()
	_refresh_label()
	if _is_locked() and _raised:
		_set_raised(false)
	elif _stays_raised():
		_set_raised(true, false)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside += 1
	if _stays_raised():
		return
	if _players_inside == 1:
		_set_raised(not _is_locked())


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside = maxi(_players_inside - 1, 0)
	if _stays_raised():
		return
	if _players_inside == 0:
		_set_raised(false)


func _set_raised(should_raise: bool, animate: bool = true) -> void:
	if should_raise == _raised and animate:
		_stele.collision_layer = 4 if should_raise else 0
		_refresh_label()
		return
	_raised = should_raise

	var target_y := _raised_y if should_raise else _buried_y
	if _tween:
		_tween.kill()
		_tween = null

	if animate:
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(_stele, "position:y", target_y, rise_seconds)
	else:
		_stele.position.y = target_y

	# Raycast can hit the stone while risen (backup to pad E).
	_stele.collision_layer = 4 if should_raise else 0
	_refresh_label()


func _is_locked() -> bool:
	if not require_unlocked:
		return false
	if destination_scene_id == GameState.ZONE_HUB:
		return false
	return not GameState.is_zone_unlocked(destination_scene_id)


func _is_cleared() -> bool:
	if destination_scene_id == GameState.ZONE_HUB:
		return false
	return destination_scene_id in GameState.completed_zones


func _stays_raised() -> bool:
	return _is_cleared() and not _is_locked()


func is_ready_to_enter() -> bool:
	return _raised and not _is_locked() and not SceneRouter.is_busy()


func can_interact(_player: Node) -> bool:
	return is_ready_to_enter()


func get_prompt() -> String:
	if _is_locked():
		return locked_prompt
	if not _raised:
		return ""
	if _is_cleared() and cleared_prompt != "":
		return cleared_prompt
	return open_prompt


func interact(_player: Node) -> void:
	if not is_ready_to_enter():
		return
	SceneRouter.go_to(destination_scene_id, destination_spawn_id)


func _refresh_label() -> void:
	if _label == null:
		return
	if _is_locked():
		_label.text = locked_prompt
		_label.modulate = Color(0.85, 0.45, 0.4)
		_label.visible = _raised
	elif _raised:
		_label.text = cleared_prompt if (_is_cleared() and cleared_prompt != "") else open_prompt
		_label.modulate = Color(0.75, 1.0, 0.8)
		_label.visible = true
	else:
		_label.text = ""
		_label.visible = false


func _refresh_pad() -> void:
	if _pad_mesh == null:
		return
	var mat := _pad_mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		_pad_mesh.material_override = mat
	mat.roughness = 0.85
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if _is_locked():
		mat.albedo_color = Color(0.28, 0.26, 0.24, 0.9)
		mat.emission_enabled = false
	elif _is_cleared():
		mat.albedo_color = Color(0.55, 0.5, 0.4, 0.75)
		mat.emission_enabled = true
		mat.emission = Color(0.7, 0.6, 0.35)
		mat.emission_energy_multiplier = 0.7
	else:
		mat.albedo_color = Color(0.55, 0.5, 0.4, 0.75)
		mat.emission_enabled = true
		mat.emission = Color(0.7, 0.6, 0.35)
		mat.emission_energy_multiplier = 0.45


func apply_god_color(color: Color) -> void:
	var stele_mat := StandardMaterial3D.new()
	stele_mat.albedo_color = color.lerp(Color(0.78, 0.74, 0.66), 0.5)
	stele_mat.roughness = 0.82
	stele_mat.metallic = 0.04
	_stele_mesh.material_override = stele_mat

	if not _is_locked():
		var pad := _pad_mesh.material_override as StandardMaterial3D
		if pad == null:
			pad = StandardMaterial3D.new()
			_pad_mesh.material_override = pad
		pad.albedo_color = Color(color.r, color.g, color.b, 0.55)
		pad.emission_enabled = true
		pad.emission = color
		pad.emission_energy_multiplier = 0.7 if _is_cleared() else 0.55
		pad.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func refresh_visuals() -> void:
	_refresh_pad()
	_refresh_label()
	if _stays_raised():
		_set_raised(true, false)
	elif _players_inside == 0:
		_set_raised(false, false)
