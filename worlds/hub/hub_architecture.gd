extends Node3D

## Procedural Greek circular peristyle: open sky center, colonnade, outer wall, ring roof.
## Center stays uncovered — no dome over the spawn.

@export var column_count: int = 24
@export var column_radius: float = 14.0
@export var outer_wall_radius: float = 20.5
@export var column_height: float = 5.2
@export var roof_height: float = 5.5


func _ready() -> void:
	_build_architecture()


func _build_architecture() -> void:
	for child in get_children():
		if child.has_meta("generated_arch"):
			child.queue_free()

	var stone := _make_stone(Color(0.78, 0.74, 0.66))
	var stone_dark := _make_stone(Color(0.62, 0.58, 0.5))
	var marble := _make_stone(Color(0.88, 0.85, 0.78))
	var marble_warm := _make_stone(Color(0.82, 0.76, 0.66))

	_add_pavement_rings(marble, marble_warm, stone_dark)
	_add_colonnade(stone, marble)
	_add_outer_wall(stone_dark, stone)
	_add_ring_roof(stone)
	_add_center_fountain(marble_warm)


func _make_stone(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	mat.metallic = 0.02
	return mat


func _mark(node: Node) -> void:
	node.set_meta("generated_arch", true)
	add_child(node)


func _add_pavement_rings(marble: Material, warm: Material, dark: Material) -> void:
	# Inner court disc (open plaza under open sky).
	var inner := MeshInstance3D.new()
	var inner_mesh := CylinderMesh.new()
	inner_mesh.top_radius = 12.0
	inner_mesh.bottom_radius = 12.0
	inner_mesh.height = 0.12
	inner.mesh = inner_mesh
	inner.material_override = marble
	inner.position = Vector3(0.0, 0.28, 0.0)
	_mark(inner)

	# Walkway ring under colonnade (visual only; main collision is hub floor).
	var walk := MeshInstance3D.new()
	var walk_mesh := CylinderMesh.new()
	walk_mesh.top_radius = outer_wall_radius - 0.4
	walk_mesh.bottom_radius = outer_wall_radius - 0.4
	walk_mesh.height = 0.1
	walk.mesh = walk_mesh
	walk.material_override = warm
	walk.position = Vector3(0.0, 0.26, 0.0)
	_mark(walk)

	# Raised stylobate step under the columns.
	var step := MeshInstance3D.new()
	var step_mesh := CylinderMesh.new()
	step_mesh.top_radius = column_radius + 0.7
	step_mesh.bottom_radius = column_radius + 0.9
	step_mesh.height = 0.28
	step.mesh = step_mesh
	step.material_override = dark
	step.position = Vector3(0.0, 0.35, 0.0)
	_mark(step)


func _add_colonnade(shaft_mat: Material, capital_mat: Material) -> void:
	for i in column_count:
		var angle := float(i) * TAU / float(column_count)
		var pos := Vector3(sin(angle) * column_radius, 0.0, cos(angle) * column_radius)
		_add_doric_column(pos, shaft_mat, capital_mat)

		# Architrave beam to next column (ring of lintels — open center).
		var next_angle := float(i + 1) * TAU / float(column_count)
		var next_pos := Vector3(sin(next_angle) * column_radius, 0.0, cos(next_angle) * column_radius)
		var mid := (pos + next_pos) * 0.5
		var span := pos.distance_to(next_pos)

		var lintel := MeshInstance3D.new()
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(0.55, 0.4, span * 0.92)
		lintel.mesh = lintel_mesh
		lintel.material_override = capital_mat
		lintel.position = Vector3(mid.x, roof_height - 0.15, mid.z)
		lintel.rotation.y = atan2(next_pos.x - pos.x, next_pos.z - pos.z)
		_mark(lintel)


func _add_doric_column(pos: Vector3, shaft_mat: Material, capital_mat: Material) -> void:
	var base_y := 0.5

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.48
	base_mesh.bottom_radius = 0.55
	base_mesh.height = 0.28
	base.mesh = base_mesh
	base.material_override = capital_mat
	base.position = pos + Vector3(0.0, base_y, 0.0)
	_mark(base)

	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.32
	shaft_mesh.bottom_radius = 0.38
	shaft_mesh.height = column_height
	shaft.mesh = shaft_mesh
	shaft.material_override = shaft_mat
	shaft.position = pos + Vector3(0.0, base_y + 0.14 + column_height * 0.5, 0.0)
	_mark(shaft)

	var capital := MeshInstance3D.new()
	var capital_mesh := BoxMesh.new()
	capital_mesh.size = Vector3(0.95, 0.28, 0.95)
	capital.mesh = capital_mesh
	capital.material_override = capital_mat
	capital.position = pos + Vector3(0.0, base_y + 0.14 + column_height + 0.14, 0.0)
	_mark(capital)

	var abacus := MeshInstance3D.new()
	var abacus_mesh := BoxMesh.new()
	abacus_mesh.size = Vector3(1.15, 0.16, 1.15)
	abacus.mesh = abacus_mesh
	abacus.material_override = capital_mat
	abacus.position = pos + Vector3(0.0, base_y + 0.14 + column_height + 0.36, 0.0)
	_mark(abacus)


func _add_outer_wall(wall_mat: Material, trim_mat: Material) -> void:
	var segments := column_count
	for i in segments:
		var angle := float(i) * TAU / float(segments)
		var next_angle := float(i + 1) * TAU / float(segments)
		var pos := Vector3(sin(angle) * outer_wall_radius, 0.0, cos(angle) * outer_wall_radius)
		var next_pos := Vector3(sin(next_angle) * outer_wall_radius, 0.0, cos(next_angle) * outer_wall_radius)
		var mid := (pos + next_pos) * 0.5
		var span := pos.distance_to(next_pos)

		var wall := MeshInstance3D.new()
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(0.55, 4.2, span * 1.02)
		wall.mesh = wall_mesh
		wall.material_override = wall_mat
		wall.position = Vector3(mid.x, 2.3, mid.z)
		wall.rotation.y = atan2(next_pos.x - pos.x, next_pos.z - pos.z)
		_mark(wall)

		# Coping / cornice on top of wall.
		var cope := MeshInstance3D.new()
		var cope_mesh := BoxMesh.new()
		cope_mesh.size = Vector3(0.75, 0.28, span * 1.02)
		cope.mesh = cope_mesh
		cope.material_override = trim_mat
		cope.position = Vector3(mid.x, 4.5, mid.z)
		cope.rotation.y = wall.rotation.y
		_mark(cope)

		# Simple collision for the wall segment.
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.position = wall.position
		body.rotation = wall.rotation
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall_mesh.size
		shape.shape = box
		body.add_child(shape)
		_mark(body)


func _add_ring_roof(roof_mat: Material) -> void:
	# Roof ONLY over the ambulatory (between columns and outer wall).
	# Center courtyard stays open to the sky — not a dome.
	var slabs := column_count
	var inner_r := column_radius - 0.2
	var outer_r := outer_wall_radius - 0.15
	var mid_r := (inner_r + outer_r) * 0.5
	var depth := outer_r - inner_r

	for i in slabs:
		var angle := (float(i) + 0.5) * TAU / float(slabs)
		var pos := Vector3(sin(angle) * mid_r, roof_height + 0.2, cos(angle) * mid_r)
		var chord := 2.0 * mid_r * sin(TAU / float(slabs) / 2.0)

		var slab := MeshInstance3D.new()
		var slab_mesh := BoxMesh.new()
		slab_mesh.size = Vector3(depth, 0.35, chord * 2.05)
		slab.mesh = slab_mesh
		slab.material_override = roof_mat
		slab.position = pos
		slab.rotation.y = angle
		_mark(slab)


func _add_center_fountain(stone_mat: Material) -> void:
	# Circular Greek courtyard fountain (open center — not a dome).
	var rim := MeshInstance3D.new()
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 2.4
	rim_mesh.bottom_radius = 2.55
	rim_mesh.height = 0.45
	rim.mesh = rim_mesh
	rim.material_override = stone_mat
	rim.position = Vector3(0.0, 0.35, 0.0)
	_mark(rim)

	var inner_wall := MeshInstance3D.new()
	var inner_mesh := CylinderMesh.new()
	inner_mesh.top_radius = 1.85
	inner_mesh.bottom_radius = 1.9
	inner_mesh.height = 0.55
	inner_wall.mesh = inner_mesh
	inner_wall.material_override = stone_mat
	inner_wall.position = Vector3(0.0, 0.4, 0.0)
	_mark(inner_wall)

	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 1.75
	water_mesh.bottom_radius = 1.75
	water_mesh.height = 0.12
	water.mesh = water_mesh
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.25, 0.45, 0.65, 0.7)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.15
	water_mat.metallic = 0.35
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.15, 0.35, 0.55)
	water_mat.emission_energy_multiplier = 0.4
	water.material_override = water_mat
	water.position = Vector3(0.0, 0.52, 0.0)
	_mark(water)

	var pedestal := MeshInstance3D.new()
	var ped_mesh := CylinderMesh.new()
	ped_mesh.top_radius = 0.35
	ped_mesh.bottom_radius = 0.45
	ped_mesh.height = 0.9
	pedestal.mesh = ped_mesh
	pedestal.material_override = stone_mat
	pedestal.position = Vector3(0.0, 0.75, 0.0)
	_mark(pedestal)

	var spout := MeshInstance3D.new()
	var spout_mesh := CylinderMesh.new()
	spout_mesh.top_radius = 0.08
	spout_mesh.bottom_radius = 0.12
	spout_mesh.height = 0.7
	spout.mesh = spout_mesh
	spout.material_override = water_mat
	spout.position = Vector3(0.0, 1.4, 0.0)
	_mark(spout)

	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 0.75, 1.0)
	light.light_energy = 1.4
	light.omni_range = 12.0
	light.position = Vector3(0.0, 1.8, 0.0)
	_mark(light)
