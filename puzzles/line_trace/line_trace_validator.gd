extends RefCounted
class_name LineTraceValidator

## Pure rules for continuous sandwich-capture lines.


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


static func path_occupied(path: Array[Vector2i]) -> Dictionary:
	var occupied: Dictionary = {}
	for cell in path:
		occupied["%d,%d" % [cell.x, cell.y]] = true
	return occupied


static func is_captured(piece: Vector2i, occupied: Dictionary, defs: LineTraceDefs) -> bool:
	## Orthogonal sandwich: both opposite neighbors in-bounds and on the path.
	var left := Vector2i(piece.x - 1, piece.y)
	var right := Vector2i(piece.x + 1, piece.y)
	var up := Vector2i(piece.x, piece.y - 1)
	var down := Vector2i(piece.x, piece.y + 1)
	var horiz := (
		defs.in_bounds(left)
		and defs.in_bounds(right)
		and occupied.has("%d,%d" % [left.x, left.y])
		and occupied.has("%d,%d" % [right.x, right.y])
	)
	var vert := (
		defs.in_bounds(up)
		and defs.in_bounds(down)
		and occupied.has("%d,%d" % [up.x, up.y])
		and occupied.has("%d,%d" % [down.x, down.y])
	)
	return horiz or vert


static func all_captured(defs: LineTraceDefs, path: Array[Vector2i]) -> bool:
	var occupied := path_occupied(path)
	for piece in defs.black_pieces:
		if not is_captured(piece, occupied, defs):
			return false
	return true


static func validate(defs: LineTraceDefs, path: Array[Vector2i]) -> Dictionary:
	## Returns { ok: bool, reason: String }
	if defs == null:
		return {"ok": false, "reason": "Missing puzzle data."}
	if path.is_empty():
		return {"ok": false, "reason": "Draw a path from the spark."}
	if not defs.is_start(path[0]):
		return {"ok": false, "reason": "Path must begin at a spark."}
	if not defs.is_exit(path[path.size() - 1]):
		return {"ok": false, "reason": "Path must end at an exit."}

	var seen: Dictionary = {}
	for i in path.size():
		var cell: Vector2i = path[i]
		if not defs.in_bounds(cell):
			return {"ok": false, "reason": "Path left the stone."}
		if defs.is_black(cell):
			return {"ok": false, "reason": "Cannot step onto a coal."}
		if defs.is_blocked(cell):
			return {"ok": false, "reason": "Dead stone blocks the fire."}
		var key := "%d,%d" % [cell.x, cell.y]
		if seen.has(key):
			return {"ok": false, "reason": "Fire cannot cross its own path."}
		seen[key] = true
		if i > 0 and not is_adjacent(path[i - 1], cell):
			return {"ok": false, "reason": "Path must stay connected."}

	for piece in defs.black_pieces:
		if not is_captured(piece, seen, defs):
			return {"ok": false, "reason": "A coal remains unflanked."}

	return {"ok": true, "reason": "The hearth accepts the path."}


static func can_extend(defs: LineTraceDefs, path: Array[Vector2i], next: Vector2i) -> bool:
	if defs == null:
		return false
	if not defs.in_bounds(next) or defs.is_impassable(next):
		return false
	if path.is_empty():
		return defs.is_start(next)
	for cell in path:
		if cell == next:
			return false
	return is_adjacent(path[path.size() - 1], next)
