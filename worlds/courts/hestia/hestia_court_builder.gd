extends Node3D

## Procedural greybox for Hestia — The Hearth Megaron (concept art layout).
## Puzzles 1.1–1.13: sandwich-capture lines on stone panels.

@export var room_width: float = 26.0
@export var wall_height: float = 7.0

const FLOOR_TOP_Y := 0.0
const FLOOR_THICKNESS := 0.5

const BACK_Z := -14.0
const ARCH_REAR_Z := -8.0
const ARCH_OUTER_Z := 0.5
const SIDE_ARCH_Z := [ARCH_REAR_Z, ARCH_OUTER_Z]
const ARCH_OPENING_W := 3.6
const ARCH_OPENING_H := 4.2
const ARCH_RECESS_DEPTH := 1.2
const WALL_THICKNESS := 0.85

const ALCOVE_DEPTH := 7.6
const ALCOVE_BACK_HALF_W := 6.6
## Wide mouth + shallow side pinch so diagonals flare open and don't occlude back-wall panels.
const ALCOVE_OPENING_HALF_W := 10.5
const ALCOVE_SLANT_X_INSET := 1.1
const ALCOVE_SLANT_Z_DEPTH := 3.8
const ARCH_SUPPORT_HALF_W := 0.42
const ARCH_ELEMENT_GAP := 0.5
const FLOOR_BASE_Y := FLOOR_TOP_Y
const PANEL_FLOAT_H := 0.42
const PANEL_SIZE := Vector2(2.35, 2.15)
const ARC_CENTER := Vector3(0.0, 0.0, 8.0)
const ARC_RADIUS := 10.5
const PILLAR_RADIUS := 7.0
const PILLAR_ARC_ANGLES := [-52.0, 0.0, 52.0]
const ARC_BARRIER_HEIGHT := 1.45

const MARKER_GROUP := "hestia_puzzle_marker"
const HEARTH_CENTER := Vector3(0.0, 0.0, ARCH_OUTER_Z)
const HEARTH_RADIUS := 2.5
const HEARTH_PLATFORM_SUNK_Y := -0.15
const HEARTH_PLATFORM_RAISED_Y := 0.82
const HEARTH_TABLETS_SUNK_Y := -1.15
const HEARTH_TABLETS_RAISED_Y := 0.42
const ALTAR_Z := BACK_Z - ALCOVE_DEPTH * 0.55
## High enough to read as a reveal, low enough that rising steps stay jump-reachable.
const ALTAR_RISE_HEIGHT := 1.15
const ALTAR_SHAFT_HEIGHT := 4.6


func _ready() -> void:
	_build_court()


func _build_court() -> void:
	for child in get_children():
		if child.has_meta("generated_hestia"):
			child.queue_free()

	var stone := _mat_stone(Color(0.72, 0.68, 0.62))
	var stone_dark := _mat_stone(Color(0.38, 0.34, 0.3))
	var cobble := _mat_stone(Color(0.28, 0.26, 0.24), 0.95)
	var wood := _mat_stone(Color(0.32, 0.22, 0.14), 0.88)
	var terracotta := _mat_stone(Color(0.55, 0.3, 0.18))
	var iron := _mat_stone(Color(0.2, 0.18, 0.16), 0.75, 0.4)
	var conduit_cold := _mat_emissive(Color(0.55, 0.28, 0.1), 0.22)

	var brick := _mat_stone(Color(0.62, 0.28, 0.18), 0.82)
	var panel_mat := _mat_stone(Color(0.58, 0.56, 0.54), 0.9)

	_build_floor(cobble)
	_build_interior_walls(stone, stone_dark, terracotta, brick, panel_mat)
	_build_side_roofs(wood)
	_build_sunken_hearth(stone_dark, iron, panel_mat, conduit_cold)
	for i in 3:
		var angle: float = PILLAR_ARC_ANGLES[i]
		var pid := "1.%d" % (i + 1)
		_build_pillar(_pillar_point(angle), pid, stone, conduit_cold)
	_build_eternal_flame_altar(Vector3(0.0, 0.0, ALTAR_Z), stone, terracotta, _mat_emissive(Color(1.0, 0.5, 0.15), 1.4))
	_build_conduit_network(conduit_cold)
	_build_torches_on_supports(stone_dark)
	_build_plantations(terracotta, stone_dark)


func _mark(node: Node) -> void:
	node.set_meta("generated_hestia", true)
	add_child(node)


func _mat_stone(color: Color, rough: float = 0.88, metallic: float = 0.05) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	return m


func _mat_emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.35
	return m


func _arc_point(deg: float, radius: float = ARC_RADIUS) -> Vector3:
	var rad := deg_to_rad(deg)
	return ARC_CENTER + Vector3(sin(rad) * radius, 0.0, cos(rad) * radius)


func _pillar_point(deg: float) -> Vector3:
	return _arc_point(deg, PILLAR_RADIUS)


func _build_floor(mat: Material) -> void:
	var floor_y := FLOOR_TOP_Y - FLOOR_THICKNESS * 0.5
	# Stop short of BACK_Z so the terracotta alcove floor owns the Expert zone (no overlap).
	var hall_north_z := BACK_Z + 0.08
	var hall_depth := ARC_CENTER.z - hall_north_z
	var hall_center_z := hall_north_z + hall_depth * 0.5

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1

	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(room_width, FLOOR_THICKNESS, hall_depth)
	floor_mesh.mesh = floor_box
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0.0, floor_y, hall_center_z)
	floor_body.add_child(floor_mesh)

	var floor_shape := CollisionShape3D.new()
	var floor_cs := BoxShape3D.new()
	floor_cs.size = Vector3(room_width, FLOOR_THICKNESS, hall_depth)
	floor_shape.shape = floor_cs
	floor_shape.position = floor_mesh.position
	floor_body.add_child(floor_shape)
	_mark(floor_body)

	_build_semicircle_floor(mat, floor_y)


func _build_semicircle_floor(mat: Material, floor_y: float) -> void:
	var body := StaticBody3D.new()
	body.name = "SemicircleFloor"
	body.collision_layer = 1
	var segments := 16
	var arc_span := 180.0
	for i in segments:
		var a0_deg := -90.0 + arc_span * float(i) / float(segments)
		var a1_deg := -90.0 + arc_span * float(i + 1) / float(segments)
		var a_mid_rad := deg_to_rad((a0_deg + a1_deg) * 0.5)
		var p0 := _arc_point(a0_deg)
		var p1 := _arc_point(a1_deg)
		var chord := p0.distance_to(p1) + 0.35
		var radial := ARC_RADIUS + 1.5
		var center := ARC_CENTER + Vector3(sin(a_mid_rad), 0.0, cos(a_mid_rad)) * (radial * 0.5)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(chord, FLOOR_THICKNESS, radial)
		mesh.mesh = box
		mesh.material_override = mat
		mesh.position = Vector3(center.x, floor_y, center.z)
		mesh.rotation.y = a_mid_rad
		body.add_child(mesh)
		var shape := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = box.size
		shape.shape = cs
		shape.position = mesh.position
		shape.rotation = mesh.rotation
		body.add_child(shape)
	_mark(body)


func _build_interior_walls(stone: Material, stone_dark: Material, terracotta: Material, brick: Material, panel_mat: Material) -> void:
	_build_back_wall_with_alcove(stone, stone_dark, terracotta, brick)
	_build_side_wall_with_arches(-1, stone, stone_dark, terracotta, brick, panel_mat)
	_build_side_wall_with_arches(1, stone, stone_dark, terracotta, brick, panel_mat)
	_build_arc_barrier(stone_dark)


func _wall_inner_x(side: int) -> float:
	return float(side) * (room_width * 0.5 - 0.4)


func _wall_room_face_x(side: int) -> float:
	return _wall_inner_x(side) - float(side) * WALL_THICKNESS * 0.5


func _build_back_wall_with_alcove(stone: Material, stone_dark: Material, terracotta: Material, brick: Material) -> void:
	var half_w := room_width * 0.5
	var wing_w := half_w - ALCOVE_OPENING_HALF_W

	_add_wall("BackWallLeft", Vector3(-half_w + wing_w * 0.5, wall_height * 0.5, BACK_Z), Vector3(wing_w, wall_height, WALL_THICKNESS), stone)
	_add_wall("BackWallRight", Vector3(half_w - wing_w * 0.5, wall_height * 0.5, BACK_Z), Vector3(wing_w, wall_height, WALL_THICKNESS), stone)

	_build_half_octagon_alcove(stone, stone_dark, terracotta)
	_build_back_alcove_arch(brick, terracotta, -ALCOVE_OPENING_HALF_W, ALCOVE_OPENING_HALF_W, BACK_Z + 0.15)

	for x in [-half_w + wing_w * 0.5, half_w - wing_w * 0.5]:
		var lintel := MeshInstance3D.new()
		lintel.name = "BackLintel_%d" % int(x)
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(maxf(0.5, wing_w - 0.5), 0.5, 0.55)
		lintel.mesh = lintel_mesh
		lintel.material_override = terracotta
		lintel.position = Vector3(x, 5.6, BACK_Z + 0.2)
		_mark(lintel)


func _alcove_back_z() -> float:
	return BACK_Z - ALCOVE_DEPTH


func _alcove_slant_point(side: int) -> Vector3:
	## Bend point of the flared diagonal: stays wide so panels on the back wall stay visible.
	var x_sign := float(side)
	return Vector3(
		x_sign * (ALCOVE_OPENING_HALF_W - ALCOVE_SLANT_X_INSET),
		0.0,
		BACK_Z - ALCOVE_SLANT_Z_DEPTH
	)


func _build_half_octagon_alcove(stone: Material, stone_dark: Material, terracotta: Material) -> void:
	var back_z := _alcove_back_z()
	var alcove_center_z := BACK_Z - ALCOVE_DEPTH * 0.5

	# Terracotta floor strictly inside the alcove (south edge at BACK_Z) — no hall overlap.
	var floor_body := StaticBody3D.new()
	floor_body.name = "AlcoveFloor"
	floor_body.collision_layer = 1
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(ALCOVE_OPENING_HALF_W * 2.05, FLOOR_THICKNESS, ALCOVE_DEPTH)
	floor_mesh.mesh = floor_box
	floor_mesh.material_override = terracotta
	floor_mesh.position = Vector3(0.0, FLOOR_TOP_Y - FLOOR_THICKNESS * 0.5 + 0.002, alcove_center_z)
	floor_body.add_child(floor_mesh)
	var floor_shape := CollisionShape3D.new()
	var floor_cs := BoxShape3D.new()
	floor_cs.size = floor_box.size
	floor_shape.shape = floor_cs
	floor_shape.position = floor_mesh.position
	floor_body.add_child(floor_shape)
	_mark(floor_body)

	var front_l := Vector3(-ALCOVE_OPENING_HALF_W, 0.0, BACK_Z)
	var front_r := Vector3(ALCOVE_OPENING_HALF_W, 0.0, BACK_Z)
	var slant_l := _alcove_slant_point(-1)
	var slant_r := _alcove_slant_point(1)
	var back_l := Vector3(-ALCOVE_BACK_HALF_W, 0.0, back_z)
	var back_r := Vector3(ALCOVE_BACK_HALF_W, 0.0, back_z)

	_add_oriented_wall("AlcoveSlantLeft", front_l, slant_l, wall_height, 0.85, stone)
	_add_oriented_wall("AlcoveRearLeft", slant_l, back_l, wall_height, 0.85, stone)
	_add_wall("AlcoveBackWall", Vector3(0.0, wall_height * 0.5, back_z), Vector3(ALCOVE_BACK_HALF_W * 2.0, wall_height, 0.85), stone)
	_add_oriented_wall("AlcoveRearRight", back_r, slant_r, wall_height, 0.85, stone)
	_add_oriented_wall("AlcoveSlantRight", slant_r, front_r, wall_height, 0.85, stone)

	_build_altar_guardian_statues(stone, stone_dark)

	# Raised dais under the altar only (panels live on the back wall now).
	var dais_body := StaticBody3D.new()
	dais_body.name = "AltarDais"
	dais_body.collision_layer = 1
	var dais := MeshInstance3D.new()
	var dais_mesh := BoxMesh.new()
	dais_mesh.size = Vector3(6.5, 0.4, 4.0)
	dais.mesh = dais_mesh
	dais.material_override = stone_dark
	dais.position = Vector3(0.0, 0.2, ALTAR_Z + 0.55)
	dais_body.add_child(dais)
	var dais_shape := CollisionShape3D.new()
	var dais_box := BoxShape3D.new()
	dais_box.size = dais_mesh.size
	dais_shape.shape = dais_box
	dais_shape.position = dais.position
	dais_body.add_child(dais_shape)
	_mark(dais_body)


func _build_altar_guardian_statues(stone: Material, stone_dark: Material) -> void:
	## Greybox guardians on the flared diagonal walls; four eyes track Advanced clears.
	var front_l := Vector3(-ALCOVE_OPENING_HALF_W, 0.0, BACK_Z)
	var front_r := Vector3(ALCOVE_OPENING_HALF_W, 0.0, BACK_Z)
	var slant_l := _alcove_slant_point(-1)
	var slant_r := _alcove_slant_point(1)
	_build_guardian_statue("AltarGuardian_L", front_l, slant_l, stone, stone_dark, ["1.8", "1.9"])
	_build_guardian_statue("AltarGuardian_R", slant_r, front_r, stone, stone_dark, ["1.10", "1.11"])


func _build_guardian_statue(
	statue_name: String,
	wall_a: Vector3,
	wall_b: Vector3,
	stone: Material,
	stone_dark: Material,
	eye_ids: Array
) -> void:
	var mid := (wall_a + wall_b) * 0.5
	var tangent := Vector3(wall_b.x - wall_a.x, 0.0, wall_b.z - wall_a.z)
	if tangent.length_squared() < 0.0001:
		return
	tangent = tangent.normalized()
	var inward := Vector3(-tangent.z, 0.0, tangent.x)
	var alcove_center := Vector3(0.0, 0.0, BACK_Z - ALCOVE_DEPTH * 0.45)
	if inward.dot(alcove_center - mid) < 0.0:
		inward = -inward

	# Slightly taller than the side arches; stand clear of the diagonal wall.
	const STATUE_SCALE := 1.22
	var root := Node3D.new()
	root.name = statue_name
	root.position = mid + inward * 1.45
	root.position.y = 0.0
	root.scale = Vector3.ONE * STATUE_SCALE
	# Face the central hearth — same forward sense as the Expert panels (+Z into the court).
	var to_hearth := HEARTH_CENTER - root.position
	to_hearth.y = 0.0
	if to_hearth.length_squared() > 0.001:
		root.rotation.y = atan2(to_hearth.x, to_hearth.z)
	else:
		root.rotation.y = 0.0

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.05
	base_mesh.bottom_radius = 1.25
	base_mesh.height = 0.55
	base.mesh = base_mesh
	base.material_override = stone_dark
	base.position = Vector3(0.0, 0.28, 0.0)
	root.add_child(base)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.55, 2.85, 1.05)
	body.mesh = body_mesh
	body.material_override = stone
	body.position = Vector3(0.0, 1.95, 0.0)
	root.add_child(body)

	var shoulders := MeshInstance3D.new()
	var shoulder_mesh := BoxMesh.new()
	shoulder_mesh.size = Vector3(2.05, 0.55, 0.85)
	shoulders.mesh = shoulder_mesh
	shoulders.material_override = stone
	shoulders.position = Vector3(0.0, 3.25, 0.0)
	root.add_child(shoulders)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.58
	head_mesh.height = 1.05
	head.mesh = head_mesh
	head.material_override = stone
	head.position = Vector3(0.0, 3.95, 0.12)
	root.add_child(head)

	# Two eyes — lit by matching Advanced panel clears.
	var eye_offsets := [Vector3(-0.22, 4.05, 0.58), Vector3(0.22, 4.05, 0.58)]
	for i in mini(2, eye_ids.size()):
		var eye := MeshInstance3D.new()
		eye.name = "StatueEye_%s" % str(eye_ids[i]).replace(".", "_")
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.1
		eye_mesh.height = 0.18
		eye.mesh = eye_mesh
		eye.position = eye_offsets[i]
		eye.set_meta("advanced_id", eye_ids[i])
		eye.add_to_group("hestia_statue_eye")
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.12, 0.1, 0.09)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(0.15, 0.08, 0.04)
		eye_mat.emission_energy_multiplier = 0.05
		eye_mat.roughness = 0.35
		eye.material_override = eye_mat
		root.add_child(eye)

	_mark(root)


func _build_back_alcove_arch(brick: Material, trim: Material, opening_left_x: float, opening_right_x: float, arch_z: float) -> void:
	var half_opening := (opening_right_x - opening_left_x) * 0.5
	var center_x := (opening_left_x + opening_right_x) * 0.5
	var depth := 0.45
	_add_arch_frame_yz(null, center_x, arch_z, half_opening, ARCH_OPENING_H, depth, brick, trim, true, 0)


func _build_side_wall_with_arches(side: int, stone: Material, stone_dark: Material, trim: Material, brick: Material, panel_mat: Material) -> void:
	var wall_x := _wall_inner_x(side)
	var wall_z_end := ARC_CENTER.z + 2.0
	var side_len := wall_z_end - BACK_Z + 0.5
	var side_z := BACK_Z + side_len * 0.5 - 0.25
	var side_name := "Left" if side < 0 else "Right"

	_add_wall("%sWall" % side_name, Vector3(wall_x, wall_height * 0.5, side_z), Vector3(WALL_THICKNESS, wall_height, side_len), stone)

	for arch_i in SIDE_ARCH_Z.size():
		var arch_z: float = SIDE_ARCH_Z[arch_i]
		# Left: 1.8 rear, 1.9 outer | Right: 1.10 rear, 1.11 outer
		var puzzle_id := ""
		if side < 0:
			puzzle_id = "1.8" if arch_i == 0 else "1.9"
		else:
			puzzle_id = "1.10" if arch_i == 0 else "1.11"
		_build_wall_arch(side, arch_z, stone, stone_dark, trim, brick, panel_mat, puzzle_id, "%s_%d" % [side_name, arch_i])
		_build_arch_supports_for_arch(side, arch_z, stone)


func _arch_flank_support_z(arch_z: float, flank: int) -> float:
	var arch_half := ARCH_OPENING_W * 0.5
	return arch_z + float(flank) * (arch_half + ARCH_ELEMENT_GAP + ARCH_SUPPORT_HALF_W)


func _arch_support_z_positions() -> Array[float]:
	var positions: Array[float] = []
	for arch_z: float in SIDE_ARCH_Z:
		for flank: int in [-1, 1]:
			positions.append(_arch_flank_support_z(arch_z, flank))
	return positions


func _build_arch_supports_for_arch(side: int, arch_z: float, stone: Material) -> void:
	var room_face_x := _wall_room_face_x(side)
	var support_x := room_face_x - float(side) * 0.22
	var support_h := wall_height - 0.25
	for flank: int in [-1, 1]:
		var z_pos := _arch_flank_support_z(arch_z, flank)
		var body := StaticBody3D.new()
		body.name = "ArchSupport_%s_%.1f_%d" % [side, arch_z, flank]
		body.collision_layer = 1
		_add_box_to_body(
			body,
			"Support",
			Vector3(0.52, support_h, ARCH_SUPPORT_HALF_W * 2.0),
			Vector3(support_x, FLOOR_BASE_Y + support_h * 0.5, z_pos),
			stone
		)
		_mark(body)


func _build_wall_arch(side: int, arch_z: float, stone: Material, stone_dark: Material, trim: Material, brick: Material, panel_mat: Material, puzzle_id: String, arch_name: String) -> void:
	var room_face_x := _wall_room_face_x(side)
	var back_x := room_face_x + float(side) * ARCH_RECESS_DEPTH
	var panel_x := room_face_x - float(side) * 0.1
	var panel_h := PANEL_SIZE.y
	var panel_w := PANEL_SIZE.x
	var panel_y := FLOOR_BASE_Y + PANEL_FLOAT_H + panel_h * 0.5
	var arch_face_x := room_face_x - float(side) * 0.06

	var root := StaticBody3D.new()
	root.name = "WallArch_%s" % arch_name
	root.collision_layer = 1

	_add_box_to_body(root, "NicheBackWall", Vector3(0.42, ARCH_OPENING_H + 0.35, ARCH_OPENING_W + 0.1), Vector3(back_x, FLOOR_BASE_Y + (ARCH_OPENING_H + 0.35) * 0.5, arch_z), stone_dark)

	_add_arch_frame_yz(root, arch_face_x, arch_z, ARCH_OPENING_W * 0.5, ARCH_OPENING_H, 0.42, brick, trim, false, side)

	if puzzle_id != "":
		var defs := _defs_for(puzzle_id)
		var panel := LineTracePanel.new()
		panel.name = "LinePanel_%s" % puzzle_id
		panel.position = Vector3(panel_x, panel_y, arch_z)
		root.add_child(panel)
		panel.setup(defs, Vector3(0.18, panel_h, panel_w), Vector3(-float(side), 0.0, 0.0), panel_mat)

	_mark(root)


func _add_box_to_body(body: StaticBody3D, box_name: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "%sMesh" % box_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	shape.name = "%sShape" % box_name
	var cs := BoxShape3D.new()
	cs.size = size
	shape.shape = cs
	shape.position = pos
	body.add_child(shape)


func _add_arch_frame_yz(
	parent: Node3D,
	face_x: float,
	center_z: float,
	half_w: float,
	opening_h: float,
	depth: float,
	brick: Material,
	trim: Material,
	is_back_wall: bool,
	wall_side: int = 0
) -> void:
	var jamb_h := opening_h
	var jamb_y := FLOOR_BASE_Y + jamb_h * 0.5
	var spring_y := FLOOR_BASE_Y + opening_h
	var arch_r := half_w

	for z_sign: int in [-1, 1]:
		var jamb := MeshInstance3D.new()
		jamb.name = "Jamb_%d" % z_sign
		var jamb_mesh := BoxMesh.new()
		if is_back_wall:
			jamb_mesh.size = Vector3(0.4, jamb_h, depth)
			jamb.position = Vector3(face_x + float(z_sign) * half_w, jamb_y, center_z)
		else:
			jamb_mesh.size = Vector3(depth, jamb_h, 0.4)
			jamb.position = Vector3(face_x, jamb_y, center_z + float(z_sign) * half_w)
		jamb.mesh = jamb_mesh
		jamb.material_override = brick
		_attach_arch_part(parent, jamb)

	var arch_segments := 11
	for i in arch_segments:
		var t0 := float(i) / float(arch_segments)
		var t1 := float(i + 1) / float(arch_segments)
		var a0 := lerpf(PI, 0.0, t0)
		var a1 := lerpf(PI, 0.0, t1)
		var span0 := cos(a0) * arch_r
		var span1 := cos(a1) * arch_r
		var y0 := sin(a0) * arch_r
		var y1 := sin(a1) * arch_r

		var p0: Vector3
		var p1: Vector3
		if is_back_wall:
			p0 = Vector3(face_x + span0, spring_y + y0, center_z)
			p1 = Vector3(face_x + span1, spring_y + y1, center_z)
		else:
			p0 = Vector3(face_x, spring_y + y0, center_z + span0)
			p1 = Vector3(face_x, spring_y + y1, center_z + span1)

		_add_voussoir(parent, p0, p1, depth, brick, is_back_wall, wall_side)

	var keystone := MeshInstance3D.new()
	keystone.name = "Keystone"
	var key_mesh := BoxMesh.new()
	if is_back_wall:
		key_mesh.size = Vector3(0.5, 0.28, depth + 0.06)
		keystone.position = Vector3(face_x, spring_y + arch_r, center_z)
	else:
		key_mesh.size = Vector3(depth + 0.06, 0.28, 0.5)
		keystone.position = Vector3(face_x, spring_y + arch_r, center_z)
	keystone.mesh = key_mesh
	keystone.material_override = trim
	_attach_arch_part(parent, keystone)


func _add_voussoir(
	parent: Node3D,
	p0: Vector3,
	p1: Vector3,
	depth: float,
	mat: Material,
	is_back_wall: bool,
	wall_side: int
) -> void:
	var tangent := p1 - p0
	var seg_len := tangent.length() + 0.12
	if seg_len < 0.05:
		return
	tangent /= seg_len

	var depth_dir: Vector3
	if is_back_wall:
		depth_dir = Vector3(0.0, 0.0, 1.0)
	else:
		depth_dir = Vector3(float(-wall_side), 0.0, 0.0)

	var up_dir := depth_dir.cross(tangent)
	if up_dir.length_squared() < 0.0001:
		return
	up_dir = up_dir.normalized()
	depth_dir = tangent.cross(up_dir).normalized()

	var voussoir := MeshInstance3D.new()
	voussoir.name = "Voussoir"
	var v_mesh := BoxMesh.new()
	var thickness := 0.34
	v_mesh.size = Vector3(seg_len, thickness, depth)
	voussoir.mesh = v_mesh
	voussoir.material_override = mat
	voussoir.position = (p0 + p1) * 0.5
	voussoir.basis = Basis(tangent, up_dir, depth_dir).orthonormalized()
	_attach_arch_part(parent, voussoir)


func _attach_arch_part(parent: Node3D, node: MeshInstance3D) -> void:
	if parent:
		parent.add_child(node)
	else:
		_mark(node)


func _panel_world_pos(side: int, arch_index: int) -> Vector3:
	var panel_x := _wall_room_face_x(side) - float(side) * 0.1
	return Vector3(panel_x, 0.045, SIDE_ARCH_Z[arch_index])


func _build_arc_barrier(stone_dark: Material) -> void:
	## Rim barrier on the semicircle floor edge, sealed into both side walls.
	var body := StaticBody3D.new()
	body.name = "ArcBarrier"
	body.collision_layer = 1
	# Match the semicircle floor outer radius (see _build_semicircle_floor).
	var barrier_r := ARC_RADIUS + 1.35
	var segments := 22
	var arc_span := 180.0
	for i in segments:
		var a0 := -90.0 + arc_span * float(i) / float(segments)
		var a1 := -90.0 + arc_span * float(i + 1) / float(segments)
		var p0 := _arc_point(a0, barrier_r)
		var p1 := _arc_point(a1, barrier_r)
		_add_arc_barrier_segment(body, p0, p1, stone_dark, i)

	# Close the gaps between the ±90° arc ends and the side-wall inner faces.
	for side in [-1, 1]:
		var angle := 90.0 * float(side)
		var arc_end := _arc_point(angle, barrier_r)
		var wall_x := _wall_room_face_x(side)
		# Overlap into the wall a bit so nothing slips through.
		var wall_end := Vector3(wall_x + float(side) * 0.35, 0.0, arc_end.z)
		_add_arc_barrier_segment(body, arc_end, wall_end, stone_dark, 100 + side)

	_mark(body)


func _add_arc_barrier_segment(
	body: StaticBody3D,
	p0: Vector3,
	p1: Vector3,
	stone_dark: Material,
	seg_id: int
) -> void:
	var mid := (p0 + p1) * 0.5
	var seg_len := p0.distance_to(p1)
	if seg_len < 0.05:
		return
	var mesh := MeshInstance3D.new()
	mesh.name = "ArcBarrierMesh_%d" % seg_id
	var box := BoxMesh.new()
	box.size = Vector3(seg_len + 0.2, ARC_BARRIER_HEIGHT, 0.65)
	mesh.mesh = box
	mesh.material_override = stone_dark
	mesh.position = Vector3(mid.x, ARC_BARRIER_HEIGHT * 0.5, mid.z)
	# Align local +X (segment length) with the run direction.
	mesh.rotation.y = atan2(p1.x - p0.x, p1.z - p0.z) - PI * 0.5
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = box.size
	shape.shape = cs
	shape.position = mesh.position
	shape.rotation = mesh.rotation
	body.add_child(shape)


func _add_wall(wall_name: String, pos: Vector3, size: Vector3, mat: Material, rot_y: float = 0.0) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = 1
	body.rotation.y = rot_y
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	shape.shape = cs
	body.add_child(shape)
	body.position = pos
	_mark(body)


func _add_oriented_wall(wall_name: String, v0: Vector3, v1: Vector3, height: float, thickness: float, mat: Material) -> void:
	var edge := v1 - v0
	var edge_len := Vector2(edge.x, edge.z).length()
	var mid := (v0 + v1) * 0.5
	var angle := atan2(edge.x, edge.z)
	_add_wall(wall_name, Vector3(mid.x, height * 0.5, mid.z), Vector3(thickness, height, edge_len + 0.08), mat, angle)


func _build_side_roofs(wood: Material) -> void:
	var half_w := room_width * 0.5
	var roof_width := 5.5
	var roof_length := ARC_CENTER.z - BACK_Z + 6.0
	var roof_z := BACK_Z + roof_length * 0.5
	var roof_mat := _mat_stone(Color(0.25, 0.17, 0.11), 0.92)
	var pitch := deg_to_rad(14.0)

	for side: int in [-1, 1]:
		var wall_x: float = float(side) * (half_w - 0.4)
		var inner_x: float = wall_x - float(side) * roof_width * 0.5

		var roof := MeshInstance3D.new()
		roof.name = "SideRoof_%s" % ("Left" if side < 0 else "Right")
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(roof_width, 0.18, roof_length)
		roof.mesh = roof_mesh
		roof.material_override = roof_mat
		roof.position = Vector3(inner_x, wall_height + 0.25, roof_z)
		roof.rotation.z = side * pitch
		_mark(roof)

		for i in 8:
			var t := float(i) / 7.0
			var z := lerpf(BACK_Z + 1.0, ARC_CENTER.z + 4.0, t)
			var rafter := MeshInstance3D.new()
			rafter.name = "SideRafter_%s_%d" % [side, i]
			var rafter_mesh := BoxMesh.new()
			rafter_mesh.size = Vector3(0.24, 0.2, roof_width - 0.4)
			rafter.mesh = rafter_mesh
			rafter.material_override = wood
			rafter.position = Vector3(inner_x, wall_height - 0.35, z)
			rafter.rotation.z = side * pitch
			_mark(rafter)

		# Beam running along the wall top.
		var wall_beam := MeshInstance3D.new()
		wall_beam.name = "WallBeam_%s" % side
		var beam_mesh := BoxMesh.new()
		beam_mesh.size = Vector3(0.32, 0.38, roof_length)
		wall_beam.mesh = beam_mesh
		wall_beam.material_override = wood
		wall_beam.position = Vector3(wall_x, wall_height + 0.05, roof_z)
		_mark(wall_beam)


func _build_sunken_hearth(stone_dark: Material, iron: Material, panel_mat: Material, conduit_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "CentralHearth"
	root.position = HEARTH_CENTER

	# Fixed outer stone lip + ring barrier.
	var outer_body := StaticBody3D.new()
	outer_body.name = "OuterRing"
	outer_body.collision_layer = 1
	var outer := MeshInstance3D.new()
	var outer_mesh := CylinderMesh.new()
	outer_mesh.top_radius = HEARTH_RADIUS + 0.85
	outer_mesh.bottom_radius = HEARTH_RADIUS + 0.95
	outer_mesh.height = 0.2
	outer.mesh = outer_mesh
	outer.material_override = stone_dark
	outer.position = Vector3(0.0, 0.02, 0.0)
	outer_body.add_child(outer)
	for i in 8:
		var angle := float(i) * TAU / 8.0
		var next := float(i + 1) * TAU / 8.0
		var mid := (Vector3(cos(angle), 0, sin(angle)) + Vector3(cos(next), 0, sin(next))) * 0.5
		mid = mid.normalized() * (HEARTH_RADIUS + 0.35)
		var seg := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 0.8, 0.5)
		seg.shape = box
		seg.position = Vector3(mid.x, 0.15, mid.z)
		seg.rotation.y = atan2(mid.x, mid.z)
		outer_body.add_child(seg)
	root.add_child(outer_body)

	# Rising inner platform (pit + coals + walkable top).
	var platform := AnimatableBody3D.new()
	platform.name = "InnerPlatform"
	platform.collision_layer = 1
	platform.collision_mask = 0
	platform.position = Vector3(0.0, HEARTH_PLATFORM_SUNK_Y, 0.0)
	platform.set_meta("sunk_y", HEARTH_PLATFORM_SUNK_Y)
	platform.set_meta("raised_y", HEARTH_PLATFORM_RAISED_Y)

	var pit := MeshInstance3D.new()
	var pit_mesh := CylinderMesh.new()
	pit_mesh.top_radius = HEARTH_RADIUS
	pit_mesh.bottom_radius = HEARTH_RADIUS - 0.2
	pit_mesh.height = 0.55
	pit.mesh = pit_mesh
	pit.material_override = iron
	pit.position = Vector3(0.0, -0.12, 0.0)
	platform.add_child(pit)

	var coals := MeshInstance3D.new()
	coals.name = "HearthCoals"
	var coal_mesh := CylinderMesh.new()
	coal_mesh.top_radius = HEARTH_RADIUS - 0.35
	coal_mesh.bottom_radius = HEARTH_RADIUS - 0.35
	coal_mesh.height = 0.08
	coals.mesh = coal_mesh
	coals.material_override = _mat_stone(Color(0.12, 0.1, 0.08))
	coals.position = Vector3(0.0, -0.28, 0.0)
	platform.add_child(coals)

	var cap := MeshInstance3D.new()
	cap.name = "PlatformCap"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = HEARTH_RADIUS - 0.15
	cap_mesh.bottom_radius = HEARTH_RADIUS - 0.15
	cap_mesh.height = 0.12
	cap.mesh = cap_mesh
	cap.material_override = stone_dark
	cap.position = Vector3(0.0, 0.18, 0.0)
	platform.add_child(cap)

	var platform_shape := CollisionShape3D.new()
	var platform_cyl := CylinderShape3D.new()
	platform_cyl.radius = HEARTH_RADIUS - 0.1
	platform_cyl.height = 0.35
	platform_shape.shape = platform_cyl
	platform_shape.position = Vector3(0.0, 0.05, 0.0)
	platform.add_child(platform_shape)

	# Center flame — lit when platform finishes rising; grows with Intermediate clears.
	var flame := MeshInstance3D.new()
	flame.name = "HearthFlame"
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.18
	flame_mesh.height = 0.42
	flame.mesh = flame_mesh
	var flame_mat := _mat_emissive(Color(1.0, 0.45, 0.12), 0.15)
	flame.material_override = flame_mat
	flame.position = Vector3(0.0, 0.45, 0.0)
	flame.scale = Vector3(0.01, 0.01, 0.01)
	flame.visible = false
	platform.add_child(flame)

	var flame_light := OmniLight3D.new()
	flame_light.name = "HearthFlameLight"
	flame_light.light_color = Color(1.0, 0.48, 0.15)
	flame_light.light_energy = 0.0
	flame_light.omni_range = 6.0
	flame_light.position = Vector3(0.0, 0.7, 0.0)
	platform.add_child(flame_light)

	root.add_child(platform)

	# Four tilted console tablets on the outer ring (Intermediate 1.4–1.7).
	var tablets := Node3D.new()
	tablets.name = "HearthTablets"
	tablets.position = Vector3(0.0, HEARTH_TABLETS_SUNK_Y, 0.0)
	tablets.set_meta("sunk_y", HEARTH_TABLETS_SUNK_Y)
	tablets.set_meta("raised_y", HEARTH_TABLETS_RAISED_Y)

	var tablet_ids := ["1.4", "1.5", "1.6", "1.7"]
	# Offset 45° so mounts sit between pillar sightlines.
	var tablet_angles_deg := [45.0, 135.0, 225.0, 315.0]
	var mount_r := HEARTH_RADIUS + 0.55
	for i in tablet_ids.size():
		var pid: String = tablet_ids[i]
		var ang := deg_to_rad(tablet_angles_deg[i])
		# XZ ring: +Z toward entrance arc.
		var outward := Vector3(sin(ang), 0.0, cos(ang))
		var mount := Node3D.new()
		mount.name = "TabletMount_%s" % pid.replace(".", "_")
		mount.position = outward * mount_r
		# Face outward; tilt like a control tablet toward the standing player.
		mount.rotation.y = atan2(outward.x, outward.z)
		mount.rotation.x = deg_to_rad(-40.0)

		var bezel := MeshInstance3D.new()
		var bezel_mesh := BoxMesh.new()
		bezel_mesh.size = Vector3(1.75, 1.75, 0.16)
		bezel.mesh = bezel_mesh
		bezel.material_override = stone_dark
		bezel.position = Vector3(0.0, 0.0, -0.02)
		mount.add_child(bezel)

		var panel := LineTracePanel.new()
		panel.name = "LinePanel_%s" % pid
		panel.position = Vector3(0.0, 0.0, 0.08)
		mount.add_child(panel)
		panel.setup(_defs_for(pid), Vector3(1.55, 1.55, 0.1), Vector3(0.0, 0.0, 1.0), panel_mat)
		# Buried until hearth reveal — not interactable / not solid yet.
		panel.collision_layer = 0
		panel.monitorable = false
		panel.set_solid_enabled(false)
		panel.set_meta("hearth_tablet", true)

		tablets.add_child(mount)

		var world_anchor := HEARTH_CENTER + outward * mount_r
		_add_conduit_segment(
			Vector3(world_anchor.x, 0.045, world_anchor.z),
			Vector3(HEARTH_CENTER.x, 0.045, HEARTH_CENTER.z),
			conduit_mat,
			"TabletConduit_%s" % pid.replace(".", "_")
		)

	root.add_child(tablets)
	_mark(root)


func _build_pillar(pos: Vector3, puzzle_id: String, stone: Material, panel_mat: Material) -> void:
	var root := StaticBody3D.new()
	root.name = "Pillar_%s" % puzzle_id
	root.collision_layer = 1
	root.collision_mask = 0
	root.position = pos
	var to_hearth := HEARTH_CENTER - pos
	to_hearth.y = 0.0
	if to_hearth.length_squared() > 0.001:
		root.rotation.y = atan2(to_hearth.x, to_hearth.z)

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.15, 0.35, 1.15)
	base.mesh = base_mesh
	base.material_override = stone
	base.position = Vector3(0.0, 0.18, 0.0)
	root.add_child(base)

	var base_shape := CollisionShape3D.new()
	var base_box := BoxShape3D.new()
	base_box.size = Vector3(1.15, 0.35, 1.15)
	base_shape.shape = base_box
	base_shape.position = Vector3(0.0, 0.18, 0.0)
	root.add_child(base_shape)

	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.5
	shaft_mesh.bottom_radius = 0.52
	shaft_mesh.height = 3.5
	shaft.mesh = shaft_mesh
	shaft.material_override = stone
	shaft.position = Vector3(0.0, 2.1, 0.0)
	root.add_child(shaft)

	var shaft_shape := CollisionShape3D.new()
	var shaft_cyl := CylinderShape3D.new()
	shaft_cyl.radius = 0.52
	shaft_cyl.height = 3.5
	shaft_shape.shape = shaft_cyl
	shaft_shape.position = Vector3(0.0, 2.1, 0.0)
	root.add_child(shaft_shape)

	for i in 4:
		var flute := MeshInstance3D.new()
		var f_mesh := BoxMesh.new()
		f_mesh.size = Vector3(0.08, 3.2, 0.18)
		flute.mesh = f_mesh
		flute.material_override = _mat_stone(Color(0.65, 0.6, 0.55))
		flute.position = Vector3(0.0, 2.05, 0.48)
		flute.rotation.y = float(i) * TAU / 4.0
		root.add_child(flute)

	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(1.3, 0.3, 1.3)
	cap.mesh = cap_mesh
	cap.material_override = stone
	cap.position = Vector3(0.0, 3.85, 0.0)
	root.add_child(cap)

	var panel := LineTracePanel.new()
	panel.name = "LinePanel_%s" % puzzle_id
	panel.position = Vector3(0.0, 2.05, 0.72)
	root.add_child(panel)
	panel.setup(_defs_for(puzzle_id), Vector3(1.35, 1.35, 0.12), Vector3(0.0, 0.0, 1.0), panel_mat)

	_mark(root)


func _build_eternal_flame_altar(pos: Vector3, stone: Material, trim: Material, flame_mat: Material) -> void:
	## Expert zone: whole podium rises on a deep shaft (never floats); portal opens in the altar middle after rise.
	var root := Node3D.new()
	root.name = "EternalFlameAltar"
	root.position = pos

	var rising := StaticBody3D.new()
	rising.name = "AltarRising"
	rising.collision_layer = 1
	rising.collision_mask = 0
	rising.position = Vector3.ZERO
	rising.set_meta("sunk_y", 0.0)
	rising.set_meta("raised_y", ALTAR_RISE_HEIGHT)

	# Deep stone shaft under the whole footprint so the raised altar stays grounded.
	var shaft := MeshInstance3D.new()
	shaft.name = "AltarShaft"
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(3.4, ALTAR_SHAFT_HEIGHT, 3.2)
	shaft.mesh = shaft_mesh
	shaft.material_override = stone
	# Top flush with altar underside; body extends deep below the floor.
	shaft.position = Vector3(0.0, 0.42 - ALTAR_SHAFT_HEIGHT * 0.5, 0.35)
	rising.add_child(shaft)
	var shaft_shape := CollisionShape3D.new()
	var shaft_box := BoxShape3D.new()
	shaft_box.size = shaft_mesh.size
	shaft_shape.shape = shaft_box
	shaft_shape.position = shaft.position
	rising.add_child(shaft_shape)

	# Approach steps toward the hall (+Z) — rise with the altar so the portal stays reachable.
	for i in 3:
		var step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		var w := 4.0 - float(i) * 0.5
		var d := 1.2 - float(i) * 0.1
		step_mesh.size = Vector3(w, 0.28, d)
		step.mesh = step_mesh
		step.material_override = stone
		step.position = Vector3(0.0, 0.14 + float(i) * 0.28, 1.65 - float(i) * 0.32)
		rising.add_child(step)
		var step_shape := CollisionShape3D.new()
		var step_box := BoxShape3D.new()
		step_box.size = step_mesh.size
		step_shape.shape = step_box
		step_shape.position = step.position
		rising.add_child(step_shape)

	var altar := MeshInstance3D.new()
	altar.name = "AltarTop"
	var altar_mesh := BoxMesh.new()
	altar_mesh.size = Vector3(2.35, 1.05, 1.55)
	altar.mesh = altar_mesh
	altar.material_override = trim
	altar.position = Vector3(0.0, 0.95, -0.15)
	rising.add_child(altar)
	var altar_shape := CollisionShape3D.new()
	var altar_box := BoxShape3D.new()
	altar_box.size = altar_mesh.size
	altar_shape.shape = altar_box
	altar_shape.position = altar.position
	rising.add_child(altar_shape)

	var bowl := MeshInstance3D.new()
	bowl.name = "AltarBowl"
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 0.42
	bowl_mesh.bottom_radius = 0.48
	bowl_mesh.height = 0.16
	bowl.mesh = bowl_mesh
	bowl.material_override = _mat_stone(Color(0.22, 0.18, 0.14), 0.8)
	bowl.position = Vector3(0.0, 1.55, -0.15)
	rising.add_child(bowl)

	var flame := MeshInstance3D.new()
	flame.name = "AltarFlame"
	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 0.28
	flame_mesh.bottom_radius = 0.1
	flame_mesh.height = 0.7
	flame.mesh = flame_mesh
	flame.material_override = flame_mat
	flame.position = Vector3(0.0, 1.95, -0.15)
	rising.add_child(flame)

	var light := OmniLight3D.new()
	light.name = "AltarLight"
	light.light_color = Color(1.0, 0.5, 0.18)
	light.light_energy = 0.6
	light.omni_range = 12.0
	light.position = Vector3(0.0, 2.4, -0.15)
	rising.add_child(light)

	var label := Label3D.new()
	label.name = "AltarLabel"
	label.text = "1.12–1.13 Eternal Flame"
	label.font_size = 32
	label.pixel_size = 0.008
	label.position = Vector3(0.0, 3.35, -0.15)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rising.add_child(label)

	_build_altar_hub_portal(rising)

	root.add_child(rising)
	_mark(root)

	# Expert panels mounted on the flat back wall (left / right), facing into the alcove.
	_build_expert_back_wall_panels(stone)


func _build_altar_hub_portal(rising: Node3D) -> void:
	## Portal sits in the altar middle; inactive until the rise finishes.
	var portal := Area3D.new()
	portal.name = "AltarHubPortal"
	portal.collision_layer = 4
	portal.collision_mask = 2
	portal.monitoring = false
	portal.monitorable = false
	# Centered on the altar top (same XZ as the bowl/flame).
	portal.position = Vector3(0.0, 1.48, -0.15)
	portal.set_script(load("res://systems/portal.gd"))
	portal.set("destination_scene_id", "hub")
	portal.set("destination_spawn_id", "from_hestia")
	portal.set("require_unlocked", false)
	portal.set("open_prompt", "Return to Hub")
	portal.set("locked_prompt", "Sealed")
	portal.set("auto_enter", true)
	portal.visible = false
	portal.set_meta("portal_ready", false)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.55, 2.2, 0.85)
	shape.shape = box
	shape.position = Vector3(0.0, 1.05, 0.15)
	portal.add_child(shape)

	var frame_mat := _mat_stone(Color(0.45, 0.22, 0.12), 0.7, 0.15)
	for side in [-1, 1]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.18, 2.2, 0.28)
		post.mesh = post_mesh
		post.material_override = frame_mat
		post.position = Vector3(float(side) * 0.78, 1.05, 0.1)
		portal.add_child(post)

	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(1.75, 0.2, 0.28)
	lintel.mesh = lintel_mesh
	lintel.material_override = frame_mat
	lintel.position = Vector3(0.0, 2.2, 0.1)
	portal.add_child(lintel)

	var gate := MeshInstance3D.new()
	gate.name = "PortalGate"
	var gate_mesh := BoxMesh.new()
	gate_mesh.size = Vector3(1.35, 1.95, 0.12)
	gate.mesh = gate_mesh
	var gate_mat := StandardMaterial3D.new()
	gate_mat.albedo_color = Color(1.0, 0.55, 0.2, 0.5)
	gate_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gate_mat.emission_enabled = true
	gate_mat.emission = Color(1.0, 0.45, 0.12)
	gate_mat.emission_energy_multiplier = 0.0
	gate_mat.roughness = 0.25
	gate.material_override = gate_mat
	gate.position = Vector3(0.0, 1.05, 0.1)
	gate.scale = Vector3(0.05, 0.05, 0.05)
	portal.add_child(gate)

	var label := Label3D.new()
	label.name = "Label3D"
	label.text = "Return to Hub"
	label.font_size = 28
	label.pixel_size = 0.009
	label.position = Vector3(0.0, 2.55, 0.25)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visible = false
	portal.add_child(label)

	rising.add_child(portal)


func _build_expert_back_wall_panels(stone: Material) -> void:
	var back_z := _alcove_back_z()
	var panel_mat := _mat_stone(Color(0.58, 0.56, 0.54), 0.9)
	var altar_ids := ["1.12", "1.13"]
	var panel_x := [-3.55, 3.55]
	var panel_size := Vector3(4.05, 4.05, 0.24)
	var panel_y := 4.15
	# Reach well past the alcove mouth into the main hall.
	var remote_reach := ALCOVE_DEPTH + 9.0
	# Embedded flush in the back wall until Advanced clears awaken the guardians.
	const EMBEDDED_Z := -0.55
	const REVEALED_Z := 0.55
	for i in 2:
		var mount := Node3D.new()
		mount.name = "ExpertPanelMount_%s" % altar_ids[i].replace(".", "_")
		mount.position = Vector3(panel_x[i], 0.0, back_z)

		var slide := StaticBody3D.new()
		slide.name = "ExpertPanelSlide"
		slide.collision_layer = 0
		slide.position = Vector3(0.0, 0.0, EMBEDDED_Z)
		slide.set_meta("embedded_z", EMBEDDED_Z)
		slide.set_meta("revealed_z", REVEALED_Z)
		slide.add_to_group("hestia_expert_slide")
		mount.add_child(slide)

		var bezel := MeshInstance3D.new()
		var bezel_mesh := BoxMesh.new()
		bezel_mesh.size = Vector3(panel_size.x + 0.32, panel_size.y + 0.32, 0.24)
		bezel.mesh = bezel_mesh
		bezel.material_override = stone
		bezel.position = Vector3(0.0, panel_y, -0.06)
		slide.add_child(bezel)
		var bezel_shape := CollisionShape3D.new()
		var bezel_box := BoxShape3D.new()
		bezel_box.size = bezel_mesh.size
		bezel_shape.shape = bezel_box
		bezel_shape.position = bezel.position
		slide.add_child(bezel_shape)

		var slate := LineTracePanel.new()
		slate.name = "LinePanel_%s" % altar_ids[i]
		slate.position = Vector3(0.0, panel_y, 0.14)
		slate.set_meta("expert_panel", true)
		slide.add_child(slate)
		slate.setup(_defs_for(altar_ids[i]), panel_size, Vector3(0.0, 0.0, 1.0), panel_mat)
		slate.enable_remote_play(remote_reach)
		# Buried: not solid / not interactable until emerged.
		slate.collision_layer = 0
		slate.monitorable = false
		slate.set_solid_enabled(false)

		_mark(mount)

	_build_altar_entry_barrier()


func _build_altar_entry_barrier() -> void:
	## Invisible wall across the alcove mouth — blocks the player, not interact rays.
	var barrier := StaticBody3D.new()
	barrier.name = "AltarEntryBarrier"
	barrier.collision_layer = 4
	barrier.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ALCOVE_OPENING_HALF_W * 2.2, wall_height, 0.35)
	shape.shape = box
	shape.position = Vector3(0.0, wall_height * 0.5, BACK_Z + 0.12)
	barrier.add_child(shape)
	_mark(barrier)


func _build_conduit_network(mat: Material) -> void:
	var y := 0.045
	var hearth := Vector3(HEARTH_CENTER.x, y, HEARTH_CENTER.z)
	var altar := Vector3(0.0, y, ALTAR_Z)

	for i in 3:
		var pillar := _pillar_point(PILLAR_ARC_ANGLES[i])
		_add_conduit_segment(Vector3(pillar.x, y, pillar.z), hearth, mat, "PillarConduit_1_%d" % (i + 1))

	# Advanced side arches intentionally have no floor conduits to the hearth —
	# they unlock via the hearth-fire / torch lighting sequence instead.

	_add_conduit_segment(altar, hearth, mat, "Altar")


func _add_conduit_segment(from: Vector3, to: Vector3, mat: Material, seg_name: String) -> void:
	var delta := to - from
	delta.y = 0.0
	var length := delta.length()
	if length < 0.05:
		return
	var dir := delta / length
	var seg := MeshInstance3D.new()
	seg.name = seg_name
	var box := BoxMesh.new()
	box.size = Vector3(0.24, 0.055, length)
	seg.mesh = box
	seg.material_override = mat
	seg.position = Vector3((from.x + to.x) * 0.5, 0.045, (from.z + to.z) * 0.5)
	seg.rotation.y = atan2(dir.x, dir.z)
	_mark(seg)


func _add_conduit_riser(anchor: Vector3, top_y: float, mat: Material, seg_name: String) -> void:
	var height := top_y - anchor.y
	if height < 0.05:
		return
	var seg := MeshInstance3D.new()
	seg.name = seg_name
	var box := BoxMesh.new()
	box.size = Vector3(0.18, height, 0.18)
	seg.mesh = box
	seg.material_override = mat
	seg.position = Vector3(anchor.x, anchor.y + height * 0.5, anchor.z)
	_mark(seg)


func _build_torches_on_supports(stone_dark: Material) -> void:
	var flame := _mat_emissive(Color(1.0, 0.45, 0.12), 1.8)
	var torch_y := 3.6
	for side: int in [-1, 1]:
		var support_x := _wall_room_face_x(side) - float(side) * 0.22
		for arch_i in SIDE_ARCH_Z.size():
			var arch_z: float = SIDE_ARCH_Z[arch_i]
			var puzzle_id := ""
			if side < 0:
				puzzle_id = "1.8" if arch_i == 0 else "1.9"
			else:
				puzzle_id = "1.10" if arch_i == 0 else "1.11"
			for flank: int in [-1, 1]:
				var z_pos := _arch_flank_support_z(arch_z, flank)
				var pos := Vector3(support_x - float(side) * 0.18, torch_y, z_pos)

				var holder := MeshInstance3D.new()
				holder.name = "TorchHolder_%s_%s_%d" % [puzzle_id.replace(".", "_"), side, flank]
				var holder_mesh := BoxMesh.new()
				holder_mesh.size = Vector3(0.2, 0.65, 0.2)
				holder.mesh = holder_mesh
				holder.material_override = stone_dark
				holder.position = pos
				_mark(holder)

				var fire := MeshInstance3D.new()
				fire.name = "TorchFlame_%s_%d" % [puzzle_id.replace(".", "_"), flank]
				var fire_mesh := SphereMesh.new()
				fire_mesh.radius = 0.11
				fire_mesh.height = 0.22
				fire.mesh = fire_mesh
				fire.material_override = flame
				fire.position = pos + Vector3(0.0, 0.48, 0.0)
				fire.add_to_group("hestia_torch_flame")
				fire.set_meta("advanced_id", puzzle_id)
				_mark(fire)

				var light := OmniLight3D.new()
				light.name = "TorchLight_%s_%d" % [puzzle_id.replace(".", "_"), flank]
				light.light_color = Color(1.0, 0.45, 0.15)
				light.light_energy = 0.08
				light.omni_range = 8.0
				light.position = pos + Vector3(0.0, 0.5, 0.0)
				light.add_to_group("hestia_torch_light")
				light.set_meta("advanced_id", puzzle_id)
				_mark(light)


func _build_plantations(terracotta: Material, _stone_dark: Material) -> void:
	## Urns along each side wall: between Advanced arches, altar-corner, and arc-side gap.
	var leaf := _mat_stone(Color(0.28, 0.42, 0.22), 0.92)
	var leaf_deep := _mat_stone(Color(0.18, 0.32, 0.16), 0.95)
	var leaf_warm := _mat_stone(Color(0.38, 0.48, 0.2), 0.9)
	var soil := _mat_stone(Color(0.22, 0.16, 0.1), 0.98)

	var mid_z: float = (ARCH_REAR_Z + ARCH_OUTER_Z) * 0.5
	# Corner between the rear Advanced support pillar and the altar alcove mouth.
	var altar_corner_z: float = (_arch_flank_support_z(ARCH_REAR_Z, -1) + BACK_Z) * 0.5
	# Gap between the outer Advanced support pillar and the half-circle rim.
	var arc_gap_z: float = (_arch_flank_support_z(ARCH_OUTER_Z, 1) + ARC_CENTER.z) * 0.5
	var slots: Array[float] = [altar_corner_z, mid_z, arc_gap_z]
	var slot_names := ["Altar", "Mid", "Arc"]

	var root := Node3D.new()
	root.name = "Plantations"
	for side: int in [-1, 1]:
		var wall_x := _wall_room_face_x(side) - float(side) * 0.55
		for i in slots.size():
			var plant := _make_planter(terracotta, leaf, leaf_deep, leaf_warm, soil, 1.1)
			plant.name = "Planter_%s_%s" % [("L" if side < 0 else "R"), slot_names[i]]
			plant.position = Vector3(wall_x, 0.0, slots[i])
			plant.rotation.y = float(side) * 0.12
			root.add_child(plant)
	_mark(root)


func _make_planter(
	terracotta: Material,
	leaf: Material,
	leaf_deep: Material,
	leaf_warm: Material,
	soil: Material,
	scale_mul: float
) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * scale_mul
	_add_pot(root, terracotta, 0.42, 0.55, 0.62, 0.0)
	_add_soil_disk(root, soil, 0.38, 0.58)
	_add_foliage_clump(root, leaf, leaf_deep, Vector3(0.0, 0.95, 0.0), 0.55, 0.7)
	_add_foliage_clump(root, leaf_warm, leaf, Vector3(0.18, 1.15, 0.1), 0.32, 0.45)
	return root


func _add_pot(parent: Node3D, mat: Material, bottom_r: float, top_r: float, height: float, y: float) -> void:
	var pot := MeshInstance3D.new()
	var pot_mesh := CylinderMesh.new()
	pot_mesh.bottom_radius = bottom_r
	pot_mesh.top_radius = top_r
	pot_mesh.height = height
	pot.mesh = pot_mesh
	pot.material_override = mat
	pot.position = Vector3(0.0, y + height * 0.5, 0.0)
	parent.add_child(pot)
	var lip := MeshInstance3D.new()
	var lip_mesh := CylinderMesh.new()
	lip_mesh.bottom_radius = top_r * 1.08
	lip_mesh.top_radius = top_r * 1.12
	lip_mesh.height = 0.06
	lip.mesh = lip_mesh
	lip.material_override = mat
	lip.position = Vector3(0.0, y + height + 0.02, 0.0)
	parent.add_child(lip)


func _add_soil_disk(parent: Node3D, mat: Material, radius: float, y: float) -> void:
	var soil := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = 0.05
	soil.mesh = disk
	soil.material_override = mat
	soil.position = Vector3(0.0, y, 0.0)
	parent.add_child(soil)


func _add_foliage_clump(
	parent: Node3D,
	mat_a: Material,
	mat_b: Material,
	pos: Vector3,
	radius: float,
	height: float
) -> void:
	var canopy := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = height
	canopy.mesh = sphere
	canopy.material_override = mat_a
	canopy.position = pos
	parent.add_child(canopy)
	var puff := MeshInstance3D.new()
	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = radius * 0.62
	puff_mesh.height = height * 0.7
	puff.mesh = puff_mesh
	puff.material_override = mat_b
	puff.position = pos + Vector3(radius * 0.35, height * 0.12, -radius * 0.2)
	parent.add_child(puff)


func _defs_for(puzzle_id: String) -> LineTraceDefs:
	for d in HestiaPuzzleData.all_defs():
		if d.puzzle_id == puzzle_id:
			return d
	var fallback := LineTraceDefs.new()
	fallback.puzzle_id = puzzle_id
	fallback.title = puzzle_id
	fallback.grid_w = 4
	fallback.grid_h = 4
	fallback.starts = [Vector2i(0, 0)]
	fallback.exits = [Vector2i(3, 0)]
	fallback.black_pieces = [Vector2i(1, 1)]
	return fallback


func _add_puzzle_marker(parent: Node3D, puzzle_id: String, local_pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = "PuzzleMarker_%s" % puzzle_id
	marker.position = local_pos
	marker.add_to_group(MARKER_GROUP)
	marker.set_meta("puzzle_id", "1.%s" % puzzle_id.replace("_", "."))
	parent.add_child(marker)
