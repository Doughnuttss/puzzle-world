extends RefCounted
class_name HermesPuzzleData

## Sandwich layouts for Hermes anamorph stations.


static func _pack(cells: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in cells:
		out.append(c as Vector2i)
	return out


static func _def(
	id: String,
	title: String,
	w: int,
	h: int,
	starts: Array,
	exits: Array,
	blacks: Array,
	blocked: Array = []
) -> LineTraceDefs:
	var d := LineTraceDefs.new()
	d.puzzle_id = id
	d.title = title
	d.grid_w = w
	d.grid_h = h
	d.starts = _pack(starts)
	d.exits = _pack(exits)
	d.black_pieces = _pack(blacks)
	d.blocked = _pack(blocked)
	return d


static func make_z1_intro() -> LineTraceDefs:
	## Gentle Zone 1 teach: U-turn sandwich once the slab is readable.
	# S . . E
	# . B . .
	# . . . .
	# . . . .
	return _def(
		"z1.1",
		"Zone 1 — Wind Sight",
		4,
		4,
		[Vector2i(0, 0)],
		[Vector2i(3, 0)],
		[Vector2i(1, 1)]
	)
