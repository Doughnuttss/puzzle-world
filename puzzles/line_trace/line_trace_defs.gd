extends Resource
class_name LineTraceDefs

## Data for one Witness-style branching-line panel.

@export var puzzle_id: String = "1.1"
@export var title: String = ""
@export var grid_w: int = 3
@export var grid_h: int = 3
@export var starts: Array[Vector2i] = []
@export var exits: Array[Vector2i] = []
@export var fuels: Array[Vector2i] = []
@export var blocked: Array[Vector2i] = []


func is_blocked(cell: Vector2i) -> bool:
	return cell in blocked


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_w and cell.y < grid_h


func is_start(cell: Vector2i) -> bool:
	return cell in starts


func is_exit(cell: Vector2i) -> bool:
	return cell in exits


func is_fuel(cell: Vector2i) -> bool:
	return cell in fuels
