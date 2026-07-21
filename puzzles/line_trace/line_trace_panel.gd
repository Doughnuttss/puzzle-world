extends Area3D
class_name LineTracePanel

## Interactable stone panel with an in-world 3D line-trace grid and zoom session.

signal puzzle_solved(puzzle_id: String)
signal board_status_changed(text: String, ok: bool)
signal board_solved(puzzle_id: String)

@export var puzzle_id: String = "1.1"
@export var display_title: String = ""
@export var locked_prompt: String = "Sealed — fire has not reached here yet"
@export var open_prompt: String = "Press E — Trace the fire"
@export var solved_prompt: String = "Embers settled"

var defs: LineTraceDefs
var is_unlocked: bool = true
var is_solved: bool = false
var face_normal: Vector3 = Vector3(0, 0, 1)

var _mesh: MeshInstance3D
var _label: Label3D
var _panel_size: Vector3 = Vector3(1, 1, 0.1)
var _mat_cold: StandardMaterial3D
var _mat_hot: StandardMaterial3D
var _mat_locked: StandardMaterial3D
var _logic: LineTraceBoardLogic
var _grid_root: Node3D
var _u_axis: Vector3 = Vector3(1, 0, 0)
var _v_axis: Vector3 = Vector3(0, 1, 0)
var _face_half_u: float = 0.5
var _face_half_v: float = 0.5


func setup(p_defs: LineTraceDefs, size: Vector3, p_face_normal: Vector3 = Vector3(0, 0, 1), mat_cold: Material = null) -> void:
	defs = p_defs
	puzzle_id = p_defs.puzzle_id
	display_title = p_defs.title if not p_defs.title.is_empty() else p_defs.puzzle_id
	if p_face_normal.length_squared() < 0.0001:
		face_normal = Vector3(0, 0, 1)
	else:
		face_normal = p_face_normal.normalized()
	_panel_size = size
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("line_trace_panel")
	add_to_group("interactable")
	_compute_face_axes()

	_mat_cold = StandardMaterial3D.new()
	_mat_cold.albedo_color = Color(0.58, 0.56, 0.54)
	_mat_cold.roughness = 0.9
	if mat_cold is StandardMaterial3D:
		_mat_cold.albedo_color = (mat_cold as StandardMaterial3D).albedo_color

	_mat_hot = StandardMaterial3D.new()
	_mat_hot.albedo_color = Color(0.72, 0.42, 0.22)
	_mat_hot.emission_enabled = true
	_mat_hot.emission = Color(1.0, 0.45, 0.15)
	_mat_hot.emission_energy_multiplier = 0.85
	_mat_hot.roughness = 0.55

	_mat_locked = StandardMaterial3D.new()
	_mat_locked.albedo_color = Color(0.28, 0.26, 0.24)
	_mat_locked.roughness = 0.95

	_mesh = MeshInstance3D.new()
	_mesh.name = "PanelMesh"
	var box := BoxMesh.new()
	box.size = size
	_mesh.mesh = box
	_mesh.material_override = _mat_cold
	add_child(_mesh)

	var shape := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size * Vector3(1.2, 1.15, 1.35)
	shape.shape = cs
	add_child(shape)

	_logic = LineTraceBoardLogic.new()
	_logic.configure(defs)
	_logic.status_changed.connect(func(t, ok): board_status_changed.emit(t, ok))
	_logic.solved.connect(func(pid): board_solved.emit(pid))
	_logic.path_changed.connect(_rebuild_grid_visual)

	_grid_root = Node3D.new()
	_grid_root.name = "GridVisual"
	_grid_root.position = face_normal * (_thickness() * 0.5 + 0.02)
	add_child(_grid_root)
	_rebuild_grid_visual()

	_label = Label3D.new()
	_label.text = display_title
	_label.font_size = 26
	_label.pixel_size = 0.007
	_label.position = Vector3(0, size.y * 0.55 + 0.2, 0) + face_normal * 0.05
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

	_refresh_visual()


func _compute_face_axes() -> void:
	var n := face_normal
	if n.length_squared() < 0.0001:
		n = Vector3(0, 0, 1)
		face_normal = n
	if absf(n.z) >= absf(n.x) and absf(n.z) >= absf(n.y):
		_u_axis = Vector3(1, 0, 0) if n.z >= 0.0 else Vector3(-1, 0, 0)
		_v_axis = Vector3(0, 1, 0)
		_face_half_u = maxf(0.05, _panel_size.x * 0.5)
		_face_half_v = maxf(0.05, _panel_size.y * 0.5)
	elif absf(n.x) >= absf(n.y):
		_u_axis = Vector3(0, 0, -1) if n.x >= 0.0 else Vector3(0, 0, 1)
		_v_axis = Vector3(0, 1, 0)
		_face_half_u = maxf(0.05, _panel_size.z * 0.5)
		_face_half_v = maxf(0.05, _panel_size.y * 0.5)
	else:
		_u_axis = Vector3(1, 0, 0)
		_v_axis = Vector3(0, 0, -1)
		_face_half_u = maxf(0.05, _panel_size.x * 0.5)
		_face_half_v = maxf(0.05, _panel_size.z * 0.5)


func _thickness() -> float:
	var n := face_normal.abs()
	return absf(_panel_size.x * n.x + _panel_size.y * n.y + _panel_size.z * n.z)


func set_unlocked(value: bool) -> void:
	is_unlocked = value
	_refresh_visual()


func mark_solved(silent: bool = false) -> void:
	if is_solved:
		return
	is_solved = true
	is_unlocked = true
	_refresh_visual()
	if not silent:
		puzzle_solved.emit(puzzle_id)


func get_prompt() -> String:
	if is_solved:
		return solved_prompt
	if not is_unlocked:
		return locked_prompt
	return open_prompt


func can_interact(_player: Node) -> bool:
	return is_unlocked and not is_solved


func interact(player: Node) -> void:
	if is_solved or not is_unlocked or defs == null:
		return
	var session := _find_or_make_session(player)
	if session == null or session.is_active():
		return
	if not session.solved.is_connected(_on_session_solved):
		session.solved.connect(_on_session_solved)
	session.open_on_panel(self, player)


func prepare_for_session() -> void:
	if _logic:
		_logic.configure(defs)
		_logic.active = true


func end_session() -> void:
	if _logic:
		_logic.active = false
		_logic.drawing = false


func reset_board_path() -> void:
	if _logic:
		_logic.reset_path()


func handle_board_pointer(local_board: Vector2, pressed: bool, moving: bool) -> void:
	## local_board is in grid units (0..w, 0..h), top-left origin.
	if _logic == null or defs == null or local_board.x < 0.0:
		return
	var cell := _board_pos_to_cell(local_board)
	_logic.handle_cell(cell, pressed, moving)


func get_zoom_transform(distance: float) -> Transform3D:
	var outward := (global_transform.basis * face_normal).normalized()
	var up := Vector3.UP
	if absf(outward.dot(Vector3.UP)) > 0.85:
		up = global_transform.basis.y.normalized()
	var target := global_position + outward * 0.02
	var origin := target + outward * distance
	return Transform3D(Basis.looking_at(target - origin, up), origin)


func screen_to_board(camera: Camera3D, screen_pos: Vector2) -> Vector2:
	if camera == null or defs == null:
		return Vector2(-1, -1)
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var outward := (global_transform.basis * face_normal).normalized()
	var plane := Plane(outward, global_position + outward * (_thickness() * 0.5 + 0.02))
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		return Vector2(-1, -1)
	var local: Vector3 = to_local(hit as Vector3) - face_normal * (_thickness() * 0.5 + 0.02)
	var u := local.dot(_u_axis) / _face_half_u
	var v := local.dot(_v_axis) / _face_half_v
	# Normalize to 0..1 across face (u right, v up → flip for top-left board space).
	var bu := (u * 0.5 + 0.5) * float(defs.grid_w)
	var bv := (0.5 - v * 0.5) * float(defs.grid_h)
	if bu < 0.0 or bv < 0.0 or bu > float(defs.grid_w) or bv > float(defs.grid_h):
		return Vector2(-1, -1)
	return Vector2(bu, bv)


func _board_pos_to_cell(board_pos: Vector2) -> Vector2i:
	var cell := Vector2i(int(floor(board_pos.x)), int(floor(board_pos.y)))
	if defs == null or not defs.in_bounds(cell):
		return Vector2i(-1, -1)
	return cell


func _cell_center_local(cell: Vector2i) -> Vector3:
	var u := ((float(cell.x) + 0.5) / float(defs.grid_w)) * 2.0 - 1.0
	var v := 1.0 - ((float(cell.y) + 0.5) / float(defs.grid_h)) * 2.0
	return _u_axis * (u * _face_half_u * 0.92) + _v_axis * (v * _face_half_v * 0.92)


func _rebuild_grid_visual() -> void:
	if _grid_root == null or defs == null:
		return
	while _grid_root.get_child_count() > 0:
		var old := _grid_root.get_child(0)
		_grid_root.remove_child(old)
		old.free()

	if not is_unlocked:
		return

	var gw: int = maxi(1, defs.grid_w)
	var gh: int = maxi(1, defs.grid_h)
	var cell_wu := maxf(0.05, (_face_half_u * 1.84) / float(gw))
	var cell_hv := maxf(0.05, (_face_half_v * 1.84) / float(gh))
	var gap := mini(0.05, mini(cell_wu, cell_hv) * 0.18)
	var marker_r := clampf(mini(cell_wu, cell_hv) * 0.32, 0.04, 0.35)

	for y in gh:
		for x in gw:
			var cell := Vector2i(x, y)
			var center := _cell_center_local(cell)
			var col := Color(0.38, 0.34, 0.30)
			if defs.is_blocked(cell):
				col = Color(0.12, 0.10, 0.09)
			elif (x + y) % 2 == 0:
				col = Color(0.44, 0.40, 0.36)
			_add_face_chip(center, maxf(0.04, cell_wu - gap), maxf(0.04, cell_hv - gap), col, 0.012, 0.01)

	if _logic != null and not is_solved and _logic.path.size() >= 2:
		for i in range(_logic.path.size() - 1):
			var a := _cell_center_local(_logic.path[i])
			var b := _cell_center_local(_logic.path[i + 1])
			_add_path_segment(a, b, Color(1.0, 0.55, 0.18))
		for cell in _logic.path:
			_add_marker_chip(_cell_center_local(cell), marker_r * 0.45, Color(1.0, 0.55, 0.18), 0.04)

	if not is_solved:
		for fuel in defs.fuels:
			var visited := false
			if _logic != null:
				for p in _logic.path:
					if p == fuel:
						visited = true
						break
			var c := Color(0.35, 0.95, 0.45) if visited else Color(1.0, 0.4, 0.08)
			_add_marker_chip(_cell_center_local(fuel), marker_r * 0.7, c, 0.05)

		for s in defs.starts:
			_add_marker_chip(_cell_center_local(s), marker_r * 0.95, Color(1.0, 0.88, 0.25), 0.06)
			_add_marker_chip(_cell_center_local(s), marker_r * 0.4, Color(0.15, 0.08, 0.02), 0.08)

		for e in defs.exits:
			_add_exit_marker(_cell_center_local(e), marker_r, Color(0.35, 0.9, 1.0))


func _face_aligned_size(along_u: float, along_v: float, along_n: float) -> Vector3:
	## Map face-local extents onto world axes (panels are axis-aligned).
	var n := face_normal.abs()
	if n.z >= n.x and n.z >= n.y:
		return Vector3(along_u, along_v, along_n)
	if n.x >= n.y:
		return Vector3(along_n, along_v, along_u)
	return Vector3(along_u, along_n, along_v)


func _add_face_chip(center: Vector3, w: float, h: float, color: Color, depth: float, lift: float) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = _face_aligned_size(maxf(0.02, w), maxf(0.02, h), maxf(0.01, depth))
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = center + face_normal * lift
	_grid_root.add_child(mi)


func _add_marker_chip(center: Vector3, radius: float, color: Color, lift: float) -> void:
	## Raised glowing chip — axis-aligned BoxMesh (no SphereMesh / Basis normalize).
	var r := maxf(0.03, radius)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = _face_aligned_size(r * 2.0, r * 2.0, maxf(0.02, lift * 0.4))
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
	mat.roughness = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = center + face_normal * maxf(0.03, lift)
	_grid_root.add_child(mi)


func _add_exit_marker(center: Vector3, radius: float, color: Color) -> void:
	var r := maxf(0.04, radius)

	var outer := MeshInstance3D.new()
	var outer_box := BoxMesh.new()
	outer_box.size = _face_aligned_size(r * 2.1, r * 2.1, 0.03)
	outer.mesh = outer_box
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = color
	outer_mat.emission_enabled = true
	outer_mat.emission = color
	outer_mat.emission_energy_multiplier = 2.0
	outer_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	outer.material_override = outer_mat
	outer.position = center + face_normal * 0.055
	_grid_root.add_child(outer)

	var inner := MeshInstance3D.new()
	var inner_box := BoxMesh.new()
	inner_box.size = _face_aligned_size(r * 1.3, r * 1.3, 0.036)
	inner.mesh = inner_box
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.2, 0.18, 0.16)
	inner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inner.material_override = inner_mat
	inner.position = center + face_normal * 0.06
	_grid_root.add_child(inner)


func _add_path_segment(a: Vector3, b: Vector3, color: Color) -> void:
	var mid := (a + b) * 0.5
	var delta := b - a
	var length := delta.length()
	if length < 0.001:
		return
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	# Thin rod along the longest world axis of the segment (axis-aligned panels).
	var abs_d := delta.abs()
	var thickness := 0.08
	if abs_d.x >= abs_d.y and abs_d.x >= abs_d.z:
		box.size = Vector3(length, thickness, thickness)
	elif abs_d.y >= abs_d.z:
		box.size = Vector3(thickness, length, thickness)
	else:
		box.size = Vector3(thickness, thickness, length)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = mid + face_normal * 0.045
	_grid_root.add_child(mi)


func _on_session_solved(solved_id: String) -> void:
	if solved_id != puzzle_id:
		return
	mark_solved()
	_rebuild_grid_visual()


func _find_or_make_session(player: Node) -> LineTraceSession:
	var tree := get_tree()
	if tree == null:
		return null
	var existing := tree.get_first_node_in_group("line_trace_session")
	if existing is LineTraceSession:
		return existing as LineTraceSession
	var session := LineTraceSession.new()
	session.name = "LineTraceSession"
	session.add_to_group("line_trace_session")
	var host: Node = player
	if player != null and player.has_node("HUD"):
		host = player.get_node("HUD").get_parent()
	host.add_child(session)
	return session


func _refresh_visual() -> void:
	if _mesh == null:
		return
	if is_solved:
		_mesh.material_override = _mat_hot
	elif not is_unlocked:
		_mesh.material_override = _mat_locked
	else:
		_mesh.material_override = _mat_cold
	if _label:
		_label.modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.55, 0.55, 0.55, 1)
		if is_solved:
			_label.modulate = Color(1.0, 0.75, 0.4, 1)
	_rebuild_grid_visual()
