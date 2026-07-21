extends CanvasLayer
class_name LineTraceSession

## Zooms the camera to a stone panel and forwards mouse input onto its board.

signal closed
signal solved(puzzle_id: String)

const ZOOM_DISTANCE := 1.85
const ZOOM_SECONDS := 0.35

var _panel: LineTracePanel
var _player: Node
var _player_camera: Camera3D
var _puzzle_camera: Camera3D
var _status: Label
var _hint: Label
var _drawing: bool = false
var _busy: bool = false


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
	if _busy or panel == null or panel.defs == null:
		return
	_panel = panel
	_player = player
	_busy = true
	_drawing = false
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
	_hint.text = "Yellow spark = start · Orange = fuel · Cyan square = exit · LMB drag · R reset · Esc"

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
	await _zoom_out()
	visible = false
	_panel = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _player != null and _player.has_method("set_puzzle_mode"):
		_player.call("set_puzzle_mode", false)
	_player = null
	if emit_closed:
		closed.emit()


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
	var target := _panel.get_zoom_transform(ZOOM_DISTANCE)
	_puzzle_camera = Camera3D.new()
	_puzzle_camera.name = "PuzzleZoomCamera"
	_puzzle_camera.fov = _player_camera.fov
	_puzzle_camera.near = _player_camera.near
	_puzzle_camera.far = _player_camera.far
	_puzzle_camera.global_transform = _player_camera.global_transform
	get_tree().current_scene.add_child(_puzzle_camera)
	_puzzle_camera.current = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_puzzle_camera, "global_transform", target, ZOOM_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


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
	var cam := _puzzle_camera if _puzzle_camera else _player_camera
	if cam == null:
		return
	var local := _panel.screen_to_board(cam, screen_pos)
	if local.x < 0.0:
		return
	_panel.handle_board_pointer(local, pressed, moving)
