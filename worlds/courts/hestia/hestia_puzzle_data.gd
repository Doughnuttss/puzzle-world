extends RefCounted
class_name HestiaPuzzleData

## Layouts for Hestia 1.1–1.13 — orthogonal sandwich-capture lines.


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
	out.append(make_1_10())
	out.append(make_1_11())
	out.append(make_1_12())
	out.append(make_1_13())
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


# --- Basic 4x4 (1 coal) — pillars ---

static func make_1_1() -> LineTraceDefs:
	# Teach U-turn / horizontal sandwich.
	# S . . E
	# . B . .
	# . . . .
	# . . . .
	return _def("1.1", "1.1 — First Flank", 4, 4,
		[Vector2i(0, 0)], [Vector2i(3, 0)], [Vector2i(1, 1)])


static func make_1_2() -> LineTraceDefs:
	# Edge coal (left rim) — only vertical sandwich works.
	# S . . .
	# B . . .
	# . . . .
	# . . . E
	return _def("1.2", "1.2 — Rim Coal", 4, 4,
		[Vector2i(0, 0)], [Vector2i(3, 3)], [Vector2i(0, 1)])


static func make_1_3() -> LineTraceDefs:
	# Bent path forces a detour past the coal.
	return _def("1.3", "1.3 — Bent Embers", 4, 4,
		[Vector2i(0, 1)], [Vector2i(3, 2)], [Vector2i(1, 2)])


# --- Intermediate 5x5 (2 coals) — aisle pedestals ---

static func make_1_4() -> LineTraceDefs:
	return _def("1.4", "1.4 — Twin Coals", 5, 5,
		[Vector2i(0, 2)], [Vector2i(4, 2)],
		[Vector2i(1, 1), Vector2i(3, 3)])


static func make_1_5() -> LineTraceDefs:
	# Shared vertical channel between two coals.
	return _def("1.5", "1.5 — Shared Wall", 5, 5,
		[Vector2i(0, 0)], [Vector2i(4, 4)],
		[Vector2i(2, 1), Vector2i(2, 3)])


static func make_1_6() -> LineTraceDefs:
	return _def("1.6", "1.6 — Cross Draft", 5, 5,
		[Vector2i(0, 4)], [Vector2i(4, 0)],
		[Vector2i(1, 2), Vector2i(3, 2)])


static func make_1_7() -> LineTraceDefs:
	return _def("1.7", "1.7 — Dead End Heat", 5, 5,
		[Vector2i(2, 0)], [Vector2i(2, 4)],
		[Vector2i(1, 2), Vector2i(3, 2)])


# --- Advanced 6x6 (3–4 coals) — side arches ---

static func make_1_8() -> LineTraceDefs:
	return _def("1.8", "1.8 — Three Flues", 6, 6,
		[Vector2i(0, 0)], [Vector2i(5, 5)],
		[Vector2i(1, 2), Vector2i(3, 1), Vector2i(4, 3)],
		[Vector2i(2, 2), Vector2i(3, 3)])


static func make_1_9() -> LineTraceDefs:
	return _def("1.9", "1.9 — Flow Split", 6, 6,
		[Vector2i(0, 3)], [Vector2i(5, 3)],
		[Vector2i(2, 1), Vector2i(2, 4), Vector2i(4, 2)])


static func make_1_10() -> LineTraceDefs:
	return _def("1.10", "1.10 — Diagonal Coals", 6, 6,
		[Vector2i(0, 5)], [Vector2i(5, 0)],
		[Vector2i(1, 1), Vector2i(2, 3), Vector2i(4, 4)])


static func make_1_11() -> LineTraceDefs:
	return _def("1.11", "1.11 — Four Embers", 6, 6,
		[Vector2i(0, 0)], [Vector2i(5, 5)],
		[Vector2i(1, 3), Vector2i(3, 2), Vector2i(3, 4), Vector2i(4, 1)])


# --- Expert 8x8 — altar ---

static func make_1_12() -> LineTraceDefs:
	return _def("1.12", "1.12 — Long Flue", 8, 8,
		[Vector2i(0, 0)], [Vector2i(7, 6)],
		[
			Vector2i(2, 1), Vector2i(5, 1), Vector2i(2, 3),
			Vector2i(4, 4), Vector2i(5, 5), Vector2i(1, 6),
		],
		[
			Vector2i(0, 2), Vector2i(1, 3), Vector2i(6, 3), Vector2i(1, 5),
		])


static func make_1_13() -> LineTraceDefs:
	return _def("1.13", "1.13 — Inner Spark", 8, 8,
		[Vector2i(1, 1)], [Vector2i(3, 5)],
		[
			Vector2i(3, 3), Vector2i(5, 6), Vector2i(5, 3),
			Vector2i(1, 6), Vector2i(5, 2),
		],
		[
			Vector2i(0, 3), Vector2i(0, 4), Vector2i(3, 0),
			Vector2i(5, 7), Vector2i(6, 0), Vector2i(7, 7),
		])
