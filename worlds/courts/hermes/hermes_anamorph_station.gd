extends Area3D
class_name HermesAnamorphStation

## Control stick on a zone disc. Locks a sky solve camera and rotates the scatter mount.

@export var open_prompt: String = "Press E — Align the sky fragments"
@export var solved_prompt: String = "Sky board settled"
@export var locked_prompt: String = "Sealed"

var panel: LineTracePanel
var mount: Node3D
var solve_cam_anchor: Marker3D


func configure(p_panel: LineTracePanel, p_mount: Node3D, p_anchor: Marker3D) -> void:
	panel = p_panel
	mount = p_mount
	solve_cam_anchor = p_anchor
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactable")
	add_to_group("hermes_anamorph_station")


func get_prompt() -> String:
	if panel == null:
		return open_prompt
	if panel.is_solved:
		return solved_prompt
	if not panel.is_unlocked:
		return locked_prompt
	return open_prompt


func can_interact(_player: Node) -> bool:
	return panel != null and panel.is_unlocked and not panel.is_solved


func interact(player: Node) -> void:
	if panel == null or mount == null or solve_cam_anchor == null:
		return
	if not can_interact(player):
		return
	var session := panel.begin_session_from_external(player)
	if session == null:
		return
	await session.open_anamorph(panel, player, mount, solve_cam_anchor.global_transform)
