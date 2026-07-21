extends CharacterBody3D

const SPEED := 5.0
const SPRINT_MULT := 1.45
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.0025
const INTERACT_DISTANCE := 3.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/InteractRay
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var crosshair: Label = $HUD/Crosshair

var _pitch: float = 0.0
var _current_target: Node = null
var _puzzle_mode: bool = false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_ray.target_position = Vector3(0, 0, -INTERACT_DISTANCE)
	interact_ray.collide_with_areas = true
	interact_ray.collide_with_bodies = true
	interact_ray.enabled = true
	prompt_label.visible = false


func set_puzzle_mode(active: bool) -> void:
	_puzzle_mode = active
	if active:
		prompt_label.visible = false
		_current_target = null
		velocity = Vector3.ZERO
		if crosshair:
			crosshair.visible = false
	elif crosshair:
		crosshair.visible = true


func is_in_puzzle_mode() -> bool:
	return _puzzle_mode


func _unhandled_input(event: InputEvent) -> void:
	if _puzzle_mode:
		return

	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, deg_to_rad(-85.0), deg_to_rad(85.0))
		head.rotation.x = _pitch

	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if _puzzle_mode:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= SPRINT_MULT

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
	_update_interact_prompt()


func _update_interact_prompt() -> void:
	_current_target = null
	prompt_label.visible = false
	if _puzzle_mode:
		return

	if interact_ray.is_colliding():
		var target := _find_interactable(interact_ray.get_collider())
		if target != null:
			var prompt := str(target.call("get_prompt"))
			if not prompt.is_empty():
				_current_target = target
				prompt_label.text = prompt
				prompt_label.visible = true
				return

	# Standing on a risen pad: show prompt without aiming.
	for node in get_tree().get_nodes_in_group("monument_pad"):
		if node.has_method("is_ready_to_enter") and node.is_ready_to_enter():
			if int(node.get("_players_inside")) > 0:
				_current_target = node
				prompt_label.text = str(node.call("get_prompt"))
				prompt_label.visible = true
				return


func _try_interact() -> void:
	if _current_target != null:
		if _current_target.has_method("can_interact") and not _current_target.can_interact(self):
			prompt_label.text = str(_current_target.call("get_prompt"))
			prompt_label.visible = true
			return
		_current_target.call("interact", self)
		return

	# Fallback: standing on a risen monument pad (no precise aim needed).
	for node in get_tree().get_nodes_in_group("monument_pad"):
		if node.has_method("is_ready_to_enter") and node.is_ready_to_enter():
			if int(node.get("_players_inside")) > 0:
				node.call("interact", self)
				return


func _find_interactable(node: Object) -> Node:
	var current: Object = node
	while current is Node:
		var as_node := current as Node
		if as_node.has_method("interact") and as_node.has_method("get_prompt"):
			return as_node
		current = as_node.get_parent()
	return null
