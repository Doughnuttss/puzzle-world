extends Node3D
class_name GodShrine

## Olympian statue with a pressure-plate approach that raises a stele to enter.

@export var court_id: String = "hestia"

@onready var _approach: Area3D = $Approach
@onready var _name_label: Label3D = $NameLabel
@onready var _title_label: Label3D = $TitleLabel
@onready var _aura: OmniLight3D = $AuraLight
@onready var _body_mesh: MeshInstance3D = $Statue/Body
@onready var _head_mesh: MeshInstance3D = $Statue/Head
@onready var _shoulders_mesh: MeshInstance3D = $Statue/Shoulders
@onready var _plinth_mesh: MeshInstance3D = $Plinth

var _configured: bool = false


func _ready() -> void:
	if not _configured:
		refresh_from_court_id()
	if not GameState.zone_unlocked.is_connected(_on_progress):
		GameState.zone_unlocked.connect(_on_progress)
	if not GameState.zone_completed.is_connected(_on_progress):
		GameState.zone_completed.connect(_on_progress)


func setup(p_court_id: String) -> void:
	court_id = p_court_id
	refresh_from_court_id()


func refresh_from_court_id() -> void:
	_configured = true
	_apply_meta()
	_configure_portal()
	_refresh_aura()


func _on_progress(_zone_id: String = "") -> void:
	_configure_portal()
	_refresh_aura()


func _apply_meta() -> void:
	var meta: Dictionary = GameState.get_court_meta(court_id)
	var god_name := str(meta.get("name", court_id))
	var title := str(meta.get("title", ""))
	var color: Color = meta.get("color", Color.WHITE)

	_name_label.text = god_name
	_title_label.text = title

	var statue_mat := StandardMaterial3D.new()
	statue_mat.albedo_color = color.lerp(Color(0.84, 0.8, 0.72), 0.4)
	statue_mat.roughness = 0.62
	statue_mat.metallic = 0.12
	_body_mesh.material_override = statue_mat
	_head_mesh.material_override = statue_mat
	_shoulders_mesh.material_override = statue_mat

	var plinth_mat := StandardMaterial3D.new()
	plinth_mat.albedo_color = Color(0.7, 0.66, 0.58)
	plinth_mat.roughness = 0.92
	_plinth_mesh.material_override = plinth_mat

	_aura.light_color = color
	if _approach and _approach.has_method("apply_god_color"):
		_approach.call("apply_god_color", color)


func _configure_portal() -> void:
	if _approach == null:
		return
	var meta: Dictionary = GameState.get_court_meta(court_id)
	var god_name := str(meta.get("name", court_id))
	_approach.set("destination_scene_id", court_id)
	_approach.set("destination_spawn_id", "from_hub")
	_approach.set("require_unlocked", true)
	_approach.set("open_prompt", "Press E — Enter %s" % god_name)
	_approach.set("locked_prompt", "%s — Sealed" % god_name)
	_approach.set("cleared_prompt", "Cleared — Press E to re-enter %s" % god_name)
	if _approach.has_method("apply_god_color"):
		_approach.call("apply_god_color", meta.get("color", Color.WHITE))
	if _approach.has_method("refresh_visuals"):
		_approach.call("refresh_visuals")


func _refresh_aura() -> void:
	var unlocked := GameState.is_zone_unlocked(court_id)
	var completed := court_id in GameState.completed_zones
	if completed:
		_aura.light_energy = 2.8
	elif unlocked:
		_aura.light_energy = 2.0
	else:
		_aura.light_energy = 0.15
