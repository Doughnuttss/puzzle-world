extends Node
class_name PuzzleBase

## Base class for future zone puzzle mechanics.

signal solved

@export var puzzle_id: String = "puzzle"
var is_solved: bool = false


func check_solved() -> bool:
	return false


func try_complete() -> void:
	if is_solved:
		return
	if check_solved():
		is_solved = true
		on_solved()
		solved.emit()


func on_solved() -> void:
	pass
