extends RefCounted
class_name HestiaPuzzleData

## Layouts for Hestia 1.1–1.9 (Witness-style branching lines).


static func all_defs() -> Array[LineTraceDefs]:
	var out: Array[LineTraceDefs] = []
	out.append(make_1_1())
	out.append(make_1_2())
	out.append(make_1_3())
	out.append(make_1_4())
	out.append(make_1_5())
	out.append(make_1_6())
	out.append(make_1_7())
	out.append(make_1_8())
	out.append(make_1_9())
	return out


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
	fuels: Array,
	blocked: Array = []
) -> LineTraceDefs:
	var d := LineTraceDefs.new()
	d.puzzle_id = id
	d.title = title
	d.grid_w = w
	d.grid_h = h
	d.starts = _pack(starts)
	d.exits = _pack(exits)
	d.fuels = _pack(fuels)
	d.blocked = _pack(blocked)
	return d


static func make_1_1() -> LineTraceDefs:
	return _def("1.1", "1.1 — First Spark", 3, 3,
		[Vector2i(0, 1)], [Vector2i(2, 1)], [Vector2i(1, 1)])


static func make_1_2() -> LineTraceDefs:
	return _def("1.2", "1.2 — Bent Flame", 3, 3,
		[Vector2i(0, 0)], [Vector2i(2, 2)], [Vector2i(2, 0)])


static func make_1_3() -> LineTraceDefs:
	return _def("1.3", "1.3 — Twin Kindling", 3, 3,
		[Vector2i(0, 2)], [Vector2i(2, 0)], [Vector2i(0, 0), Vector2i(2, 2)])


static func make_1_4() -> LineTraceDefs:
	# 5x5 — center column barrier with a gap; loop to both fuels then exit
	# ..F..
	# ..#..
	# S...E
	# ..#..
	# ..F..
	return _def("1.4", "1.4 — Cold Channel", 5, 5,
		[Vector2i(0, 2)], [Vector2i(4, 2)],
		[Vector2i(2, 0), Vector2i(2, 4)],
		[Vector2i(2, 1), Vector2i(2, 3)])


static func make_1_5() -> LineTraceDefs:
	return _def("1.5", "1.5 — Dead Stone", 5, 5,
		[Vector2i(0, 0)], [Vector2i(4, 4)],
		[Vector2i(4, 0), Vector2i(0, 4)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)])


static func make_1_6() -> LineTraceDefs:
	# 5x5 — known solution snakes through three fuels
	# ....E
	# .F...
	# ..#F.
	# .#...
	# S.F..
	return _def("1.6", "1.6 — Spreading Heat", 5, 5,
		[Vector2i(0, 4)], [Vector2i(4, 0)],
		[Vector2i(1, 1), Vector2i(3, 2), Vector2i(2, 4)],
		[Vector2i(2, 2), Vector2i(1, 3)])


static func make_1_7() -> LineTraceDefs:
	return _def("1.7", "1.7 — Ring of Coals", 5, 5,
		[Vector2i(0, 2)], [Vector2i(4, 2)],
		[Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 3), Vector2i(3, 3)],
		[Vector2i(2, 2), Vector2i(2, 1), Vector2i(2, 3)])


static func make_1_8() -> LineTraceDefs:
	# Two sparks shown; ONLY (0,5) clears every fuel. (0,0) is a false spark.
	return _def("1.8", "1.8 — False Spark", 6, 6,
		[Vector2i(0, 0), Vector2i(0, 5)],
		[Vector2i(5, 5)],
		[Vector2i(2, 5), Vector2i(4, 5), Vector2i(5, 2), Vector2i(3, 3)],
		[
			Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(2, 3), Vector2i(1, 3),
			Vector2i(4, 4),
		])


static func make_1_9() -> LineTraceDefs:
	# One spark; two exits. ONLY (5,0) clears all fuels. (5,5) is a false exit.
	return _def("1.9", "1.9 — Eternal Flame", 6, 6,
		[Vector2i(0, 3)],
		[Vector2i(5, 0), Vector2i(5, 5)],
		[Vector2i(1, 1), Vector2i(3, 1), Vector2i(2, 3), Vector2i(4, 4), Vector2i(1, 5)],
		[
			Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
			Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
			Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4),
			Vector2i(3, 4),
		])
