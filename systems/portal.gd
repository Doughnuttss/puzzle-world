extends Area3D
class_name Portal

## Walk-in portal that routes to another scene via SceneRouter.

@export var destination_scene_id: String = "hestia"
@export var destination_spawn_id: String = "from_hub"
@export var require_unlocked: bool = true
@export var locked_prompt: String = "Locked"
@export var open_prompt: String = "Enter (E)"
@export var auto_enter: bool = true

@onready var _label: Label3D = $Label3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 4  # interactable
	collision_mask = 2   # player
	_refresh_label()
	if not GameState.zone_unlocked.is_connected(_on_zone_unlocked):
		GameState.zone_unlocked.connect(_on_zone_unlocked)


func _on_zone_unlocked(_zone_id: String) -> void:
	_refresh_label()


func _refresh_label() -> void:
	if _label == null:
		return
	if _is_locked():
		_label.text = locked_prompt
		_label.modulate = Color(1.0, 0.45, 0.35)
	else:
		_label.text = open_prompt
		_label.modulate = Color(0.55, 1.0, 0.75)


func _is_locked() -> bool:
	if not require_unlocked:
		return false
	if destination_scene_id == GameState.ZONE_HUB:
		return false
	return not GameState.is_zone_unlocked(destination_scene_id)


func can_interact(_player: Node) -> bool:
	return not _is_locked() and not SceneRouter.is_busy()


func get_prompt() -> String:
	return locked_prompt if _is_locked() else open_prompt


func interact(player: Node) -> void:
	_try_travel(player)


func _on_body_entered(body: Node3D) -> void:
	if not auto_enter:
		return
	if body.is_in_group("player"):
		_try_travel(body)


func _try_travel(_player: Node) -> void:
	if SceneRouter.is_busy():
		return
	if _is_locked():
		_refresh_label()
		return
	SceneRouter.go_to(destination_scene_id, destination_spawn_id)
