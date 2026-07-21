extends Node3D

## Builds the pantheon ring from GameState.COURT_ORDER (index 0 = south / first court).

const SHRINE_SCENE := preload("res://systems/god_shrine.tscn")

@export var ring_radius: float = 11.5
@export var start_angle_offset: float = 0.0


func _ready() -> void:
	# After GameState finishes loading / migrating the save file.
	call_deferred("_build_ring")


func _build_ring() -> void:
	for child in get_children():
		if child.has_meta("generated_shrine"):
			child.queue_free()

	var count := GameState.COURT_ORDER.size()
	for i in count:
		var court_id: String = GameState.COURT_ORDER[i]
		var angle := start_angle_offset + float(i) * TAU / float(count)
		# i=0 Hestia at +Z (south, first court). i=6 opposite side. i=11 Zeus.
		var pos := Vector3(sin(angle) * ring_radius, 0.0, cos(angle) * ring_radius)
		if court_id == "zeus":
			pos.y = 0.35

		var shrine: Node3D = SHRINE_SCENE.instantiate()
		shrine.set_meta("generated_shrine", true)
		shrine.position = pos
		shrine.rotation.y = atan2(pos.x, pos.z) + PI
		add_child(shrine)

		if shrine.has_method("setup"):
			shrine.setup(court_id)
		else:
			shrine.set("court_id", court_id)

		var spawn := Node3D.new()
		spawn.name = "Spawn_From_%s" % court_id
		spawn.set_script(load("res://systems/spawn_point.gd"))
		spawn.set("spawn_id", "from_%s" % court_id)
		var inward := Vector3(pos.x, 0.0, pos.z).normalized() * maxf(ring_radius - 4.0, 3.5)
		spawn.position = Vector3(inward.x, 0.55, inward.z)
		spawn.rotation.y = atan2(pos.x - inward.x, pos.z - inward.z)
		spawn.set_meta("generated_shrine", true)
		add_child(spawn)
