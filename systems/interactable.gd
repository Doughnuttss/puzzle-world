extends Node
class_name Interactable

## Base for anything the player can use with Interact (E).

@export var prompt_text: String = "Press E"
@export var enabled: bool = true


func can_interact(_player: Node) -> bool:
	return enabled


func get_prompt() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	pass
