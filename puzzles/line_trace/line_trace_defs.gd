extends Resource
class_name LineTraceDefs

## Data for one sandwich-capture line panel (Hestia hearth rules).

@export var puzzle_id: String = "1.1"
@export var title: String = ""
@export var grid_w: int = 4
@export var grid_h: int = 4
@export var starts: Array[Vector2i] = []
@export var exits: Array[Vector2i] = []
@export var black_pieces: Array[Vector2i] = []
@export var blocked: Array[Vector2i] = []


func is_blocked(cell: Vector2i) -> bool:
	return cell in blocked


func is_black(cell: Vector2i) -> bool:
	return cell in black_pieces


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_w and cell.y < grid_h


func is_start(cell: Vector2i) -> bool:
	return cell in starts


func is_exit(cell: Vector2i) -> bool:
	return cell in exits


func is_impassable(cell: Vector2i) -> bool:
	return is_blocked(cell) or is_black(cell)
