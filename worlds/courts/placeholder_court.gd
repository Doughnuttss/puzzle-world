extends Node3D

## Shared stub for courts not yet uniquely built.
## Reads GameState.current_zone_id for title/palette.

const SHRINE_META_FALLBACK := {
	"name": "Court",
	"title": "Under construction",
	"color": Color(0.5, 0.5, 0.55),
}

@onready var _title: Label3D = $Title
@onready var _subtitle: Label3D = $Subtitle
@onready var _floor_mesh: MeshInstance3D = $Floor/MeshInstance3D
@onready var _portal: Area3D = $PortalToHub
@onready var _hint: Label3D = $Hint


func _ready() -> void:
	var court_id := GameState.current_zone_id
	var meta: Dictionary = GameState.get_court_meta(court_id)
	if meta.is_empty():
		meta = SHRINE_META_FALLBACK

	var color: Color = meta.get("color", Color(0.5, 0.5, 0.55))
	_title.text = str(meta.get("name", court_id))
	_subtitle.text = str(meta.get("title", ""))
	_hint.text = "Placeholder court · Walk back through the arch to the hub\n(Dev: press C to mark cleared and unlock the next gate)"

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = color.darkened(0.45)
	floor_mat.roughness = 0.9
	_floor_mesh.material_override = floor_mat

	_portal.set("destination_scene_id", GameState.ZONE_HUB)
	_portal.set("destination_spawn_id", "from_%s" % court_id)
	_portal.set("require_unlocked", false)
	_portal.set("open_prompt", "Return to Hub")
	_portal.set("locked_prompt", "Return to Hub")
	_portal.set("auto_enter", true)

	if $WorldEnvironment.environment:
		$WorldEnvironment.environment.background_color = color.darkened(0.55)
		$WorldEnvironment.environment.ambient_light_color = color.lightened(0.2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			GameState.complete_zone(GameState.current_zone_id)
			_hint.text = "Court cleared · Next gate unlocked in the hub · Return through the arch"
			_hint.modulate = Color(0.7, 1.0, 0.75)
