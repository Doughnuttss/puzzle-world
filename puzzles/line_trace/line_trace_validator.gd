extends RefCounted
class_name LineTraceValidator

## Pure rules for continuous branching lines.


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


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
		if defs.is_blocked(cell):
			return {"ok": false, "reason": "Dead stone blocks the fire."}
		var key := "%d,%d" % [cell.x, cell.y]
		if seen.has(key):
			return {"ok": false, "reason": "Fire cannot cross its own path."}
		seen[key] = true
		if i > 0 and not is_adjacent(path[i - 1], cell):
			return {"ok": false, "reason": "Path must stay connected."}

	for fuel in defs.fuels:
		var fkey := "%d,%d" % [fuel.x, fuel.y]
		if not seen.has(fkey):
			return {"ok": false, "reason": "Kindling remains unburned."}

	return {"ok": true, "reason": "The hearth accepts the path."}


static func can_extend(defs: LineTraceDefs, path: Array[Vector2i], next: Vector2i) -> bool:
	if defs == null:
		return false
	if not defs.in_bounds(next) or defs.is_blocked(next):
		return false
	if path.is_empty():
		return defs.is_start(next)
	for cell in path:
		if cell == next:
			return false
	return is_adjacent(path[path.size() - 1], next)
