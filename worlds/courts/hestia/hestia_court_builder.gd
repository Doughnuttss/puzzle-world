extends Node3D

## Procedural greybox for Hestia — The Hearth Megaron (concept art layout).
## Puzzles 1.1–1.9: Witness-style branching lines on stone panels.

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

const ALCOVE_DEPTH := 3.4
const ALCOVE_BACK_HALF_W := 1.45
const ALCOVE_SLANT_INSET := 1.45
const ALCOVE_OPENING_HALF_W := 3.5
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
const ALTAR_Z := BACK_Z - ALCOVE_DEPTH * 0.55


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
	_build_sunken_hearth(stone_dark, iron)
	for i in 3:
		var angle: float = PILLAR_ARC_ANGLES[i]
		var pid := "1.%d" % (i + 1)
		_build_pillar(_pillar_point(angle), pid, stone, conduit_cold)
	_build_eternal_flame_altar(Vector3(0.0, 0.0, ALTAR_Z), stone, terracotta, _mat_emissive(Color(1.0, 0.5, 0.15), 1.4))
	_build_conduit_network(conduit_cold)
	_build_torches_on_supports(stone_dark)


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
	var hall_depth := ARC_CENTER.z - BACK_Z
	var hall_center_z := BACK_Z + hall_depth * 0.5

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


func _build_interior_walls(stone: Material, stone_dark: Material, trim: Material, brick: Material, panel_mat: Material) -> void:
	_build_back_wall_with_alcove(stone, stone_dark, trim, brick)
	_build_side_wall_with_arches(-1, stone, stone_dark, trim, brick, panel_mat)
	_build_side_wall_with_arches(1, stone, stone_dark, trim, brick, panel_mat)
	_build_arc_barrier(stone_dark)


func _wall_inner_x(side: int) -> float:
	return float(side) * (room_width * 0.5 - 0.4)


func _wall_room_face_x(side: int) -> float:
	return _wall_inner_x(side) - float(side) * WALL_THICKNESS * 0.5


func _build_back_wall_with_alcove(stone: Material, stone_dark: Material, trim: Material, brick: Material) -> void:
	var half_w := room_width * 0.5
	var wing_w := half_w - ALCOVE_OPENING_HALF_W

	_add_wall("BackWallLeft", Vector3(-half_w + wing_w * 0.5, wall_height * 0.5, BACK_Z), Vector3(wing_w, wall_height, WALL_THICKNESS), stone)
	_add_wall("BackWallRight", Vector3(half_w - wing_w * 0.5, wall_height * 0.5, BACK_Z), Vector3(wing_w, wall_height, WALL_THICKNESS), stone)

	_build_half_octagon_alcove(stone, stone_dark)
	_build_back_alcove_arch(brick, trim, -ALCOVE_OPENING_HALF_W, ALCOVE_OPENING_HALF_W, BACK_Z + 0.15)

	for x in [-half_w + wing_w * 0.5, half_w - wing_w * 0.5]:
		var lintel := MeshInstance3D.new()
		lintel.name = "BackLintel_%d" % int(x)
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(wing_w - 0.5, 0.5, 0.55)
		lintel.mesh = lintel_mesh
		lintel.material_override = trim
		lintel.position = Vector3(x, 5.6, BACK_Z + 0.2)
		_mark(lintel)


func _alcove_back_z() -> float:
	return BACK_Z - ALCOVE_DEPTH


func _alcove_slant_point(side: int) -> Vector3:
	var x_sign := float(side)
	return Vector3(
		x_sign * (ALCOVE_OPENING_HALF_W - ALCOVE_SLANT_INSET),
		0.0,
		BACK_Z - ALCOVE_SLANT_INSET
	)


func _build_half_octagon_alcove(stone: Material, stone_dark: Material) -> void:
	var back_z := _alcove_back_z()
	var alcove_center_z := BACK_Z - ALCOVE_DEPTH * 0.5

	var floor_body := StaticBody3D.new()
	floor_body.name = "AlcoveFloor"
	floor_body.collision_layer = 1
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(ALCOVE_OPENING_HALF_W * 2.05, FLOOR_THICKNESS, ALCOVE_DEPTH + 0.35)
	floor_mesh.mesh = floor_box
	floor_mesh.material_override = stone_dark
	floor_mesh.position = Vector3(0.0, FLOOR_TOP_Y - FLOOR_THICKNESS * 0.5, alcove_center_z)
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

	_add_oriented_wall("AlcoveSlantLeft", front_l, slant_l, wall_height, 0.8, stone)
	_add_oriented_wall("AlcoveRearLeft", slant_l, back_l, wall_height, 0.8, stone)
	_add_wall("AlcoveBackWall", Vector3(0.0, wall_height * 0.5, back_z), Vector3(ALCOVE_BACK_HALF_W * 2.0, wall_height, 0.8), stone)
	_add_oriented_wall("AlcoveRearRight", back_r, slant_r, wall_height, 0.8, stone)
	_add_oriented_wall("AlcoveSlantRight", slant_r, front_r, wall_height, 0.8, stone)

	var dais := MeshInstance3D.new()
	dais.name = "AltarDais"
	var dais_mesh := BoxMesh.new()
	dais_mesh.size = Vector3(2.4, 0.35, 1.8)
	dais.mesh = dais_mesh
	dais.material_override = stone_dark
	dais.position = Vector3(0.0, 0.18, ALTAR_Z - 0.15)
	_mark(dais)


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
		# Left: 1.4 rear, 1.5 outer | Right: 1.6 rear, 1.7 outer
		var puzzle_id := ""
		if side < 0:
			puzzle_id = "1.4" if arch_i == 0 else "1.5"
		else:
			puzzle_id = "1.6" if arch_i == 0 else "1.7"
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
	var body := StaticBody3D.new()
	body.name = "ArcBarrier"
	body.collision_layer = 1
	var segments := 18
	var arc_span := 180.0
	for i in segments:
		var a0 := -90.0 + arc_span * float(i) / float(segments)
		var a1 := -90.0 + arc_span * float(i + 1) / float(segments)
		var p0 := _arc_point(a0, ARC_RADIUS + 0.2)
		var p1 := _arc_point(a1, ARC_RADIUS + 0.2)
		var mid := (p0 + p1) * 0.5
		var seg_len := p0.distance_to(p1)
		var mesh := MeshInstance3D.new()
		mesh.name = "ArcBarrierMesh_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(seg_len + 0.12, ARC_BARRIER_HEIGHT, 0.55)
		mesh.mesh = box
		mesh.material_override = stone_dark
		mesh.position = Vector3(mid.x, ARC_BARRIER_HEIGHT * 0.5, mid.z)
		mesh.rotation.y = atan2(p1.x - p0.x, p1.z - p0.z)
		body.add_child(mesh)
		var shape := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = box.size
		shape.shape = cs
		shape.position = mesh.position
		shape.rotation = mesh.rotation
		body.add_child(shape)
	_mark(body)


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


func _build_sunken_hearth(stone_dark: Material, iron: Material) -> void:
	var root := StaticBody3D.new()
	root.name = "CentralHearth"
	root.position = HEARTH_CENTER
	root.collision_layer = 1

	var outer := MeshInstance3D.new()
	var outer_mesh := CylinderMesh.new()
	outer_mesh.top_radius = HEARTH_RADIUS + 0.85
	outer_mesh.bottom_radius = HEARTH_RADIUS + 0.95
	outer_mesh.height = 0.2
	outer.mesh = outer_mesh
	outer.material_override = stone_dark
	outer.position = Vector3(0.0, 0.02, 0.0)
	root.add_child(outer)

	var pit := MeshInstance3D.new()
	var pit_mesh := CylinderMesh.new()
	pit_mesh.top_radius = HEARTH_RADIUS
	pit_mesh.bottom_radius = HEARTH_RADIUS - 0.2
	pit_mesh.height = 0.55
	pit.mesh = pit_mesh
	pit.material_override = iron
	pit.position = Vector3(0.0, -0.12, 0.0)
	root.add_child(pit)

	var coals := MeshInstance3D.new()
	var coal_mesh := CylinderMesh.new()
	coal_mesh.top_radius = HEARTH_RADIUS - 0.35
	coal_mesh.bottom_radius = HEARTH_RADIUS - 0.35
	coal_mesh.height = 0.08
	coals.mesh = coal_mesh
	coals.material_override = _mat_stone(Color(0.12, 0.1, 0.08))
	coals.position = Vector3(0.0, -0.28, 0.0)
	root.add_child(coals)

	var ring := StaticBody3D.new()
	ring.name = "HearthRingCollider"
	ring.collision_layer = 1
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
		ring.add_child(seg)
	root.add_child(ring)

	_mark(root)


func _build_pillar(pos: Vector3, puzzle_id: String, stone: Material, panel_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "Pillar_%s" % puzzle_id
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

	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.5
	shaft_mesh.bottom_radius = 0.52
	shaft_mesh.height = 3.5
	shaft.mesh = shaft_mesh
	shaft.material_override = stone
	shaft.position = Vector3(0.0, 2.1, 0.0)
	root.add_child(shaft)

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
	panel.position = Vector3(0.0, 2.0, 0.58)
	root.add_child(panel)
	panel.setup(_defs_for(puzzle_id), Vector3(0.95, 0.95, 0.1), Vector3(0.0, 0.0, 1.0), panel_mat)

	_mark(root)


func _build_eternal_flame_altar(pos: Vector3, stone: Material, trim: Material, flame_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "EternalFlameAltar"
	root.position = pos

	for i in 2:
		var step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		var w := 5.2 - float(i) * 0.9
		step_mesh.size = Vector3(w, 0.3, 2.4 - float(i) * 0.35)
		step.mesh = step_mesh
		step.material_override = stone
		step.position = Vector3(0.0, 0.15 + float(i) * 0.3, float(i) * 0.12)
		root.add_child(step)

	var altar := MeshInstance3D.new()
	var altar_mesh := BoxMesh.new()
	altar_mesh.size = Vector3(2.6, 0.85, 1.3)
	altar.mesh = altar_mesh
	altar.material_override = trim
	altar.position = Vector3(0.0, 0.72, 0.3)
	root.add_child(altar)

	var altar_ids := ["1.8", "1.9"]
	var slate_x := [-0.7, 0.7]
	for i in 2:
		var slate := LineTracePanel.new()
		slate.name = "LinePanel_%s" % altar_ids[i]
		slate.position = Vector3(slate_x[i], 1.35, 0.55)
		# Stand upright facing the hearth (+Z toward court entrance is - wait: altar at back, hearth at +Z from altar... ALTAR_Z is more negative than hearth, so toward hearth is +Z)
		slate.rotation.x = deg_to_rad(-18.0)
		root.add_child(slate)
		slate.setup(_defs_for(altar_ids[i]), Vector3(0.85, 0.85, 0.12), Vector3(0.0, 0.0, 1.0))

	var flame := MeshInstance3D.new()
	flame.name = "AltarFlame"
	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 0.22
	flame_mesh.bottom_radius = 0.08
	flame_mesh.height = 0.55
	flame.mesh = flame_mesh
	flame.material_override = flame_mat
	flame.position = Vector3(0.0, 1.55, 0.3)
	root.add_child(flame)

	var light := OmniLight3D.new()
	light.name = "AltarLight"
	light.light_color = Color(1.0, 0.5, 0.18)
	light.light_energy = 0.6
	light.omni_range = 10.0
	light.position = Vector3(0.0, 2.0, 0.3)
	root.add_child(light)

	var label := Label3D.new()
	label.text = "1.8–1.9 Eternal Flame"
	label.font_size = 32
	label.pixel_size = 0.008
	label.position = Vector3(0.0, 3.0, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

	_mark(root)


func _build_conduit_network(mat: Material) -> void:
	var y := 0.045
	var hearth := Vector3(HEARTH_CENTER.x, y, HEARTH_CENTER.z)
	var altar := Vector3(0.0, y, ALTAR_Z)

	for i in 3:
		var pillar := _pillar_point(PILLAR_ARC_ANGLES[i])
		_add_conduit_segment(Vector3(pillar.x, y, pillar.z), hearth, mat, "Pillar_1_%d" % (i + 1))

	for side: int in [-1, 1]:
		for arch_i in SIDE_ARCH_Z.size():
			var anchor := _panel_world_pos(side, arch_i)
			_add_conduit_segment(anchor, hearth, mat, "Panel_%d_%d" % [side, arch_i])
			_add_conduit_riser(anchor, FLOOR_BASE_Y + PANEL_FLOAT_H, mat, "PanelRiser_%d_%d" % [side, arch_i])

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
	var z_positions := _arch_support_z_positions()
	var torch_y := 3.6
	for side: int in [-1, 1]:
		var support_x := _wall_room_face_x(side) - float(side) * 0.22
		for i in z_positions.size():
			var pos := Vector3(support_x - float(side) * 0.18, torch_y, z_positions[i])
			var holder := MeshInstance3D.new()
			holder.name = "TorchHolder_%s_%d" % [side, i]
			var holder_mesh := BoxMesh.new()
			holder_mesh.size = Vector3(0.2, 0.65, 0.2)
			holder.mesh = holder_mesh
			holder.material_override = stone_dark
			holder.position = pos
			_mark(holder)

			var fire := MeshInstance3D.new()
			var fire_mesh := SphereMesh.new()
			fire_mesh.radius = 0.11
			fire_mesh.height = 0.22
			fire.mesh = fire_mesh
			fire.material_override = flame
			fire.position = pos + Vector3(0.0, 0.48, 0.0)
			fire.add_to_group("hestia_torch_flame")
			_mark(fire)

			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.45, 0.15)
			light.light_energy = 0.15
			light.omni_range = 8.0
			light.position = pos + Vector3(0.0, 0.5, 0.0)
			light.add_to_group("hestia_torch_light")
			_mark(light)


func _defs_for(puzzle_id: String) -> LineTraceDefs:
	for d in HestiaPuzzleData.all_defs():
		if d.puzzle_id == puzzle_id:
			return d
	var fallback := LineTraceDefs.new()
	fallback.puzzle_id = puzzle_id
	fallback.title = puzzle_id
	fallback.grid_w = 3
	fallback.grid_h = 3
	fallback.starts = [Vector2i(0, 1)]
	fallback.exits = [Vector2i(2, 1)]
	fallback.fuels = [Vector2i(1, 1)]
	return fallback


func _add_puzzle_marker(parent: Node3D, puzzle_id: String, local_pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = "PuzzleMarker_%s" % puzzle_id
	marker.position = local_pos
	marker.add_to_group(MARKER_GROUP)
	marker.set_meta("puzzle_id", "1.%s" % puzzle_id.replace("_", "."))
	parent.add_child(marker)
