extends Node
class_name HermesCourtController

## Wires Hermes anamorph panels to GameState progress.

const ZONE_ID := "hermes"


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("line_trace_panel"):
		if node is LineTracePanel:
			var panel := node as LineTracePanel
			if not panel.puzzle_solved.is_connected(_on_panel_solved):
				panel.puzzle_solved.connect(_on_panel_solved)
			if GameState.is_puzzle_solved(ZONE_ID, panel.puzzle_id):
				panel.mark_solved(true)
				var saved := GameState.get_puzzle_path(ZONE_ID, panel.puzzle_id)
				if not saved.is_empty():
					panel.set_solved_path(saved)
				_solidify_completed_anamorph(panel)


func _on_panel_solved(puzzle_id: String) -> void:
	var panel: LineTracePanel = null
	for node in get_tree().get_nodes_in_group("line_trace_panel"):
		if node is LineTracePanel and (node as LineTracePanel).puzzle_id == puzzle_id:
			panel = node as LineTracePanel
			break
	if panel != null:
		var path := panel.get_display_path()
		if not path.is_empty():
			GameState.set_puzzle_path(ZONE_ID, puzzle_id, path)
		_solidify_completed_anamorph(panel)
	GameState.mark_puzzle_solved(ZONE_ID, puzzle_id)


func _solidify_completed_anamorph(panel: LineTracePanel) -> void:
	## Hide depth-scattered chips and reveal one coplanar stone board with the burned path.
	if panel == null:
		return
	var mount := _find_scatter_mount(panel.puzzle_id)
	if mount != null:
		mount.visible = false
	if panel.has_method("solidify_anamorph_display"):
		panel.solidify_anamorph_display()


func _find_scatter_mount(puzzle_id: String) -> Node3D:
	var sky := get_tree().get_first_node_in_group("hermes_sky_constellation")
	var roots: Array[Node] = []
	if sky != null:
		roots.append(sky)
	var scene := get_tree().current_scene
	if scene != null:
		roots.append(scene)
	for root in roots:
		var mount := _find_mount_under(root, puzzle_id)
		if mount != null:
			return mount
	return null


func _find_mount_under(node: Node, puzzle_id: String) -> Node3D:
	if node is Node3D and node.name == "ScatterMount":
		if not node.has_meta("anamorph_panel_id") or str(node.get_meta("anamorph_panel_id")) == puzzle_id:
			return node as Node3D
	for child in node.get_children():
		var found := _find_mount_under(child, puzzle_id)
		if found != null:
			return found
	return null
