extends Node3D
class_name SpawnPoint

## Marker where the player is placed when arriving via SceneRouter.

@export var spawn_id: String = "default"


func _enter_tree() -> void:
	add_to_group("spawn_point")
