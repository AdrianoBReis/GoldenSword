extends CharacterBody2D

signal shot_fired(from_pos: Vector2, to_pos: Vector2, hit_position: Vector2, did_hit: bool)

@export var move_speed := 340.0
@export var acceleration := 11.5
@export var friction := 9.5
@export var dash_speed := 860.0
@export var dash_duration := 0.13
@export var dash_cooldown := 0.5
@export var shot_range := 620.0

var dash_time := 0.0
var dash_cooldown_time := 0.0
var dash_direction := Vector2.RIGHT

func _ready() -> void:
	add_to_group("player")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		_shoot()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO:
		dash_direction = input_dir.normalized()

	dash_cooldown_time = maxf(dash_cooldown_time - delta, 0.0)

	if Input.is_action_just_pressed("dash") and dash_cooldown_time == 0.0 and input_dir != Vector2.ZERO:
		dash_time = dash_duration
		dash_cooldown_time = dash_cooldown

	if dash_time > 0.0:
		dash_time -= delta
		velocity = dash_direction * dash_speed
	else:
		var target_velocity := input_dir * move_speed
		var blend := acceleration if input_dir != Vector2.ZERO else friction
		velocity = velocity.lerp(target_velocity, clampf(blend * delta, 0.0, 1.0))

	move_and_slide()
	look_at(get_global_mouse_position())

func _shoot() -> void:
	var aim := get_global_mouse_position() - global_position
	if aim == Vector2.ZERO:
		return

	var direction := aim.normalized()
	var from_pos := global_position
	var to_pos := from_pos + direction * shot_range
	var hit_position := to_pos
	var did_hit := false
	var excludes: Array = [self]
	var ray_from := from_pos
	var space_state := get_world_2d().direct_space_state

	for _attempt in range(8):
		var query := PhysicsRayQueryParameters2D.create(ray_from, to_pos)
		query.exclude = excludes
		query.collide_with_bodies = true
		query.collide_with_areas = true

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			break

		var collider: Object = result.get("collider") as Object
		hit_position = result.position
		if collider and collider.has_method("on_hit"):
			collider.on_hit()
			did_hit = true
			break

		if collider is Area2D:
			excludes.append(collider)
			ray_from = result.position + direction * 0.5
			continue

		break

	emit_signal("shot_fired", from_pos, to_pos, hit_position, did_hit)
