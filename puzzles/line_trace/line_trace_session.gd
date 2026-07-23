extends CanvasLayer
class_name LineTraceSession

## Zooms the camera to a stone panel and forwards mouse input onto its board.

signal closed
signal solved(puzzle_id: String)

const ZOOM_DISTANCE := 1.85
const ZOOM_SECONDS := 0.35
const ANAMORPH_YAW_SPEED := 0.85
const ANAMORPH_PITCH_SPEED := 0.7
const ANAMORPH_PITCH_MIN := deg_to_rad(-80.0)
const ANAMORPH_PITCH_MAX := deg_to_rad(80.0)
## Soft-snap only inside this tiny window, then hard-lock.
const ANAMORPH_ALIGN_RAD := deg_to_rad(0.5)
const ANAMORPH_SNAP_RAD := deg_to_rad(0.5)
const ANAMORPH_SNAP_SPEED := 8.0

var _panel: LineTracePanel
var _player: Node
var _player_camera: Camera3D
var _puzzle_camera: Camera3D
var _status: Label
var _hint: Label
var _drawing: bool = false
var _busy: bool = false
## Hermes anamorph: locked sky cam + WASD rotates scatter mount.
var _anamorph_active: bool = false
var _anamorph_mount: Node3D = null
var _anamorph_solve_xform := Transform3D.IDENTITY
var _anamorph_truth := Vector3.ZERO
var _anamorph_locked: bool = false


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_hud()


func _build_hud() -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 24)
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_status.add_theme_constant_override("outline_size", 5)
	_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -110.0
	_status.offset_bottom = -70.0
	root.add_child(_status)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.text = "LMB drag on the stone · R reset · Esc back away"
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -60.0
	_hint.offset_bottom = -28.0
	root.add_child(_hint)


func is_active() -> bool:
	return _busy


func open_on_panel(panel: LineTracePanel, player: Node) -> void:
	await _begin_session(panel, player, false, null, Transform3D.IDENTITY)


func open_anamorph(
	panel: LineTracePanel,
	player: Node,
	mount: Node3D,
	solve_camera_xform: Transform3D
) -> void:
	## Locked sky solve cam; WASD rotates scatter until fragments fuse; then draw.
	await _begin_session(panel, player, true, mount, solve_camera_xform)


func _begin_session(
	panel: LineTracePanel,
	player: Node,
	anamorph: bool,
	mount: Node3D,
	solve_camera_xform: Transform3D
) -> void:
	if _busy or panel == null or panel.defs == null:
		return
	_panel = panel
	_player = player
	_busy = true
	_drawing = false
	_anamorph_active = anamorph
	_anamorph_mount = mount if anamorph else null
	_anamorph_solve_xform = solve_camera_xform
	_anamorph_truth = Vector3.ZERO
	_anamorph_locked = false
	if mount != null and mount.has_meta("anamorph_truth_rotation"):
		_anamorph_truth = mount.get_meta("anamorph_truth_rotation") as Vector3
	visible = true

	if player != null and player.has_method("set_puzzle_mode"):
		player.call("set_puzzle_mode", true)

	_player_camera = null
	if player != null and player.has_node("Head/Camera3D"):
		_player_camera = player.get_node("Head/Camera3D") as Camera3D

	panel.prepare_for_session()
	if not panel.board_status_changed.is_connected(_on_status):
		panel.board_status_changed.connect(_on_status)
	if not panel.board_solved.is_connected(_on_board_solved):
		panel.board_solved.connect(_on_board_solved)

	_status.text = panel.defs.title
	_status.add_theme_color_override("font_color", Color(1.0, 0.88, 0.6))
	_hint.text = "Yellow = start · Orange coal = sandwich both sides · Cyan = exit · LMB drag · R reset · Esc"

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if anamorph:
		_hint.text = "WASD — spin the sky pieces until they fuse · then LMB draw · Esc"
		await _zoom_in()
	elif panel.keep_player_camera:
		if _player_camera:
			_player_camera.current = true
		_hint.text = "Yellow = start · Orange coal = sandwich · Cyan = exit · LMB drag · R reset · Esc"
	else:
		await _zoom_in()


func close_session(emit_closed: bool = true) -> void:
	if not _busy:
		return
	_busy = false
	_drawing = false
	if _panel:
		_panel.end_session()
		if _panel.board_status_changed.is_connected(_on_status):
			_panel.board_status_changed.disconnect(_on_status)
		if _panel.board_solved.is_connected(_on_board_solved):
			_panel.board_solved.disconnect(_on_board_solved)
		if _panel.has_meta("anamorph_composite"):
			var grid := _panel.get_node_or_null("GridVisual")
			if grid:
				grid.visible = _panel.is_solved
	if _anamorph_active or (_panel and not _panel.keep_player_camera) or _puzzle_camera != null:
		await _zoom_out()
	visible = false
	_panel = null
	_anamorph_active = false
	_anamorph_mount = null
	_anamorph_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _player != null and _player.has_method("set_puzzle_mode"):
		_player.call("set_puzzle_mode", false)
	_player = null
	if emit_closed:
		closed.emit()


func _process(delta: float) -> void:
	if not _busy or not _anamorph_active or _anamorph_mount == null:
		return
	if not _anamorph_locked:
		var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if move.length_squared() >= 0.0001:
			# A/D yaw, W/S pitch only — no roll, so every axis the player can move can fully align.
			_anamorph_mount.rotation.y -= move.x * ANAMORPH_YAW_SPEED * delta
			_anamorph_mount.rotation.x = clampf(
				_anamorph_mount.rotation.x + move.y * ANAMORPH_PITCH_SPEED * delta,
				ANAMORPH_PITCH_MIN,
				ANAMORPH_PITCH_MAX
			)
			_anamorph_mount.rotation.z = _anamorph_truth.z
		_try_soft_snap(delta)
		_try_auto_lock()
	_refresh_anamorph_hint()


func _try_soft_snap(delta: float) -> void:
	## Only eases in the last 0.5° — no pull from farther away.
	if _anamorph_mount == null or _anamorph_locked:
		return
	var err := _align_error()
	if err > ANAMORPH_SNAP_RAD or err < 0.0005:
		return
	_anamorph_mount.rotation.x = lerp_angle(
		_anamorph_mount.rotation.x, _anamorph_truth.x, clampf(ANAMORPH_SNAP_SPEED * delta, 0.0, 1.0)
	)
	_anamorph_mount.rotation.y = lerp_angle(
		_anamorph_mount.rotation.y, _anamorph_truth.y, clampf(ANAMORPH_SNAP_SPEED * delta, 0.0, 1.0)
	)
	_anamorph_mount.rotation.z = _anamorph_truth.z


func _try_auto_lock() -> void:
	## Hard-lock once inside the align margin — freezes WASD on the fused board.
	if _anamorph_locked or _anamorph_mount == null:
		return
	if _align_error() > ANAMORPH_ALIGN_RAD:
		return
	_anamorph_mount.rotation = _anamorph_truth
	_anamorph_locked = true
	_set_composite_grid_visible(true)
	_status.text = "Aligned — board locked"
	_status.add_theme_color_override("font_color", Color(0.55, 0.92, 0.55))


func _align_error() -> float:
	if _anamorph_mount == null:
		return 999.0
	var r := _anamorph_mount.rotation
	## Roll is locked to truth — only yaw/pitch matter.
	return maxf(
		absf(angle_difference(r.x, _anamorph_truth.x)),
		absf(angle_difference(r.y, _anamorph_truth.y))
	)


func _refresh_anamorph_hint() -> void:
	if _hint == null or not _anamorph_active:
		return
	## Never show the stone back-grid; only enable the ink overlay after lock.
	_set_composite_grid_visible(_anamorph_locked)
	if _anamorph_locked:
		_hint.text = "Locked — LMB draw the path · R reset · Esc"
		_hint.add_theme_color_override("font_color", Color(0.75, 0.92, 0.7))
	elif _scatter_aligned():
		_hint.text = "Fusing — hold steady…"
		_hint.add_theme_color_override("font_color", Color(0.85, 0.92, 0.55))
	else:
		_hint.text = "Scattered — WASD until the pieces fuse · Esc"
		_hint.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))


func _set_composite_grid_visible(visible_grid: bool) -> void:
	if _panel == null or not _panel.has_meta("anamorph_composite"):
		return
	var grid := _panel.get_node_or_null("GridVisual")
	if grid:
		grid.visible = visible_grid


func _scatter_aligned() -> bool:
	return _align_error() <= ANAMORPH_ALIGN_RAD


func _on_status(text: String, ok: bool) -> void:
	_status.text = text
	_status.add_theme_color_override(
		"font_color",
		Color(0.55, 0.92, 0.55) if ok else Color(1.0, 0.55, 0.4)
	)


func _on_board_solved(puzzle_id: String) -> void:
	await get_tree().create_timer(0.4, true, false, true).timeout
	solved.emit(puzzle_id)
	await close_session(false)


func _zoom_in() -> void:
	if _panel == null or _player_camera == null:
		return
	var target := _anamorph_solve_xform if _anamorph_active else _panel.get_zoom_transform(ZOOM_DISTANCE)
	_puzzle_camera = Camera3D.new()
	_puzzle_camera.name = "PuzzleZoomCamera"
	_puzzle_camera.fov = _player_camera.fov
	_puzzle_camera.near = _player_camera.near
	_puzzle_camera.far = maxf(_player_camera.far, 200.0)
	_puzzle_camera.global_transform = _player_camera.global_transform
	get_tree().current_scene.add_child(_puzzle_camera)
	_puzzle_camera.current = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_puzzle_camera, "global_transform", target, ZOOM_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	if _anamorph_active:
		_refresh_anamorph_hint()


func _zoom_out() -> void:
	if _puzzle_camera == null:
		return
	if _player_camera:
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_puzzle_camera, "global_transform", _player_camera.global_transform, ZOOM_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		_player_camera.current = true
	_puzzle_camera.queue_free()
	_puzzle_camera = null


func _unhandled_input(event: InputEvent) -> void:
	if not _busy:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close_session()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		if _panel:
			_panel.reset_board_path()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drawing = event.pressed
		_forward_pointer(event.position, event.pressed, false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _drawing:
		_forward_pointer(event.position, true, true)
		get_viewport().set_input_as_handled()


func _forward_pointer(screen_pos: Vector2, pressed: bool, moving: bool) -> void:
	if _panel == null:
		return
	if _anamorph_active and not _anamorph_locked:
		if pressed and not moving:
			_status.text = "Align the sky pieces first"
			_status.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
		return
	var cam := _player_camera if _panel.keep_player_camera else (_puzzle_camera if _puzzle_camera else _player_camera)
	if cam == null:
		return
	var local := _panel.screen_to_board(cam, screen_pos)
	if local.x < 0.0:
		return
	_panel.handle_board_pointer(local, pressed, moving)
