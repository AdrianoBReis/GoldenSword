extends CharacterBody3D

@export var move_speed := 7.5
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025
@export var gravity := 12.0
@export var max_pitch := 75.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))

	if event.is_action_pressed("fire"):
		_shoot()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	move_dir.y = 0
	move_dir = move_dir.normalized()

	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

func _shoot() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * 120.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result and result.collider and result.collider.has_method("on_hit"):
		result.collider.on_hit()
