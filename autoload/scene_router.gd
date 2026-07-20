extends Node

## Loads hub / court scenes with a short fade and spawn-point handoff.

signal transition_started(scene_id: String)
signal transition_finished(scene_id: String)

const HUB_PATH := "res://worlds/hub/hub.tscn"
const PLACEHOLDER_COURT_PATH := "res://worlds/courts/placeholder_court.tscn"

const FADE_SECONDS := 0.35

var _busy: bool = false
var _overlay: ColorRect
var _layer: CanvasLayer


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_overlay)
	add_child(_layer)


func go_to(scene_id: String, spawn_point_id: String = "default") -> void:
	if _busy:
		return
	if scene_id != GameState.ZONE_HUB and not GameState.is_zone_unlocked(scene_id):
		push_warning("Zone locked: %s" % scene_id)
		return

	var path := _path_for(scene_id)
	if path.is_empty():
		push_error("Unknown scene id: %s" % scene_id)
		return

	_busy = true
	transition_started.emit(scene_id)
	GameState.current_zone_id = scene_id
	GameState.set_spawn_point(spawn_point_id)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_SECONDS)
	await tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_SECONDS)
	await tween.finished

	_busy = false
	transition_finished.emit(scene_id)


func _path_for(scene_id: String) -> String:
	if scene_id == GameState.ZONE_HUB:
		return HUB_PATH
	if scene_id in GameState.COURT_ORDER:
		# Unique scene if present; otherwise shared placeholder.
		var unique := "res://worlds/courts/%s/%s.tscn" % [scene_id, scene_id]
		if ResourceLoader.exists(unique):
			return unique
		return PLACEHOLDER_COURT_PATH
	return ""


func is_busy() -> bool:
	return _busy
