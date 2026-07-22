extends RefCounted
class_name LineTraceBoardLogic

## Pure line-trace board state (no UI). Used by in-world 3D panels.

signal solved(puzzle_id: String)
signal status_changed(text: String, ok: bool)
signal path_changed

var defs: LineTraceDefs
var path: Array[Vector2i] = []
var drawing: bool = false
var active: bool = false


func configure(p_defs: LineTraceDefs) -> void:
	defs = p_defs
	path.clear()
	drawing = false
	path_changed.emit()
	_emit_status(_default_status(), true)


func reset_path() -> void:
	path.clear()
	drawing = false
	path_changed.emit()
	_emit_status("Path cleared.", true)


func handle_cell(cell: Vector2i, pressed: bool, moving: bool) -> void:
	if not active or defs == null or cell.x < 0:
		return
	if pressed and not moving:
		if defs.is_start(cell):
			path = [cell]
			drawing = true
			_emit_status("Trace the fire…", true)
			path_changed.emit()
		elif not path.is_empty() and LineTraceValidator.can_extend(defs, path, cell):
			path.append(cell)
			drawing = true
			_after_extend()
	elif not pressed and not moving:
		drawing = false
	elif moving and drawing:
		if LineTraceValidator.can_extend(defs, path, cell):
			path.append(cell)
			_after_extend()


func captured_count() -> int:
	if defs == null:
		return 0
	var occupied := LineTraceValidator.path_occupied(path)
	var n := 0
	for piece in defs.black_pieces:
		if LineTraceValidator.is_captured(piece, occupied, defs):
			n += 1
	return n


func _default_status() -> String:
	if defs == null:
		return ""
	var n := defs.black_pieces.size()
	if n <= 0:
		return "Trace from spark to exit."
	if n == 1:
		return "Flank the coal on both sides, then reach the exit."
	return "Sandwich every coal, then dock at the exit."


func _emit_status(text: String, ok: bool) -> void:
	status_changed.emit(text, ok)


func _after_extend() -> void:
	path_changed.emit()
	var n := defs.black_pieces.size()
	var got := captured_count()
	if got < n:
		_emit_status("Coals flanked: %d / %d" % [got, n], true)
	if defs.is_exit(path[path.size() - 1]):
		var result := LineTraceValidator.validate(defs, path)
		_emit_status(str(result.reason), bool(result.ok))
		if result.ok:
			drawing = false
			active = false
			solved.emit(defs.puzzle_id)
