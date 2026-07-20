extends Node3D

## Shared world bootstrap: spawn player at the active SpawnPoint.

const PLAYER_SCENE := preload("res://player/player.tscn")


func _ready() -> void:
	# Defer so sibling SpawnPoints have entered the tree/groups.
	call_deferred("_spawn_player")


func _spawn_player() -> void:
	var existing := get_tree().get_first_node_in_group("player")
	if existing:
		existing.queue_free()

	var player: Node3D = PLAYER_SCENE.instantiate()
	var spawn := _find_spawn(GameState.spawn_point_id)
	if spawn:
		player.global_transform = spawn.global_transform
	else:
		player.global_position = Vector3(0, 1.0, 0)

	get_tree().current_scene.add_child(player)


func _find_spawn(spawn_id: String) -> Node3D:
	var fallback: Node3D = null
	for node in get_tree().get_nodes_in_group("spawn_point"):
		if not (node is Node3D):
			continue
		var sp := node as Node3D
		var id := str(sp.get("spawn_id"))
		if id == spawn_id:
			return sp
		if id == "default":
			fallback = sp
	return fallback
