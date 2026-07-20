extends StaticBody3D

## Forwards interact calls to the approach pad portal.


func can_interact(player: Node) -> bool:
	var portal := get_parent()
	return portal != null and portal.has_method("can_interact") and portal.can_interact(player)


func get_prompt() -> String:
	var portal := get_parent()
	if portal == null or not portal.has_method("get_prompt"):
		return ""
	return str(portal.get_prompt())


func interact(player: Node) -> void:
	var portal := get_parent()
	if portal and portal.has_method("interact"):
		portal.interact(player)
