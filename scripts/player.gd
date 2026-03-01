extends CharacterBody2D

signal shot_fired(from_pos: Vector2, to_pos: Vector2, hit_position: Vector2, did_hit: bool)

@export var move_speed := 340.0
@export var acceleration := 11.5
@export var friction := 9.5
@export var dash_speed := 860.0
@export var dash_duration := 0.13
@export var dash_cooldown := 0.5
@export var shot_range := 620.0
@export var mobile_joystick_radius := 140.0
@export var mobile_fire_interval := 0.16
@export var mobile_dash_double_tap_window := 0.4

var dash_time := 0.0
var dash_cooldown_time := 0.0
var dash_direction := Vector2.RIGHT
var last_move_direction := Vector2.ZERO
var touch_controls_enabled := OS.has_feature("mobile")
var touch_move_id := -1
var touch_aim_id := -1
var move_touch_origin := Vector2.ZERO
var mobile_move_vector := Vector2.ZERO
var mobile_aim_position := Vector2.ZERO
var mobile_aim_active := false
var mobile_fire_cooldown := 0.0
var last_left_touch_time := -10.0
var mobile_dash_requested := false

func _ready() -> void:
	add_to_group("player")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return

	if event.is_action_pressed("fire"):
		_shoot()

func _physics_process(delta: float) -> void:
	var input_dir := _get_move_input()
	if input_dir != Vector2.ZERO:
		dash_direction = input_dir.normalized()
		last_move_direction = dash_direction

	dash_cooldown_time = maxf(dash_cooldown_time - delta, 0.0)
	mobile_fire_cooldown = maxf(mobile_fire_cooldown - delta, 0.0)

	var did_dash := false
	if Input.is_action_just_pressed("dash") and dash_cooldown_time == 0.0 and input_dir != Vector2.ZERO:
		dash_time = dash_duration
		dash_cooldown_time = dash_cooldown
		did_dash = true

	if mobile_dash_requested and dash_cooldown_time == 0.0 and not did_dash:
		if input_dir != Vector2.ZERO:
			dash_direction = input_dir.normalized()
		elif last_move_direction != Vector2.ZERO:
			dash_direction = last_move_direction

		if dash_direction != Vector2.ZERO:
			dash_time = dash_duration
			dash_cooldown_time = dash_cooldown
	mobile_dash_requested = false

	if dash_time > 0.0:
		dash_time -= delta
		velocity = dash_direction * dash_speed
	else:
		var target_velocity := input_dir * move_speed
		var blend := acceleration if input_dir != Vector2.ZERO else friction
		velocity = velocity.lerp(target_velocity, clampf(blend * delta, 0.0, 1.0))

	move_and_slide()
	if touch_controls_enabled and mobile_aim_active:
		look_at(mobile_aim_position)
		if mobile_fire_cooldown == 0.0:
			_shoot_to(mobile_aim_position)
			mobile_fire_cooldown = mobile_fire_interval
	elif touch_controls_enabled and input_dir != Vector2.ZERO:
		look_at(global_position + input_dir)
	else:
		look_at(get_global_mouse_position())

func _shoot() -> void:
	_shoot_to(get_global_mouse_position())

func _shoot_to(target_pos: Vector2) -> void:
	var aim := target_pos - global_position
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

func _get_move_input() -> Vector2:
	var keyboard_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if keyboard_dir != Vector2.ZERO:
		return keyboard_dir
	return mobile_move_vector

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	touch_controls_enabled = true
	var is_left_side := event.position.x < (get_viewport_rect().size.x * 0.5)

	if event.pressed:
		if is_left_side and touch_move_id == -1:
			touch_move_id = event.index
			move_touch_origin = event.position
			mobile_move_vector = Vector2.ZERO

			var now := Time.get_ticks_msec() / 1000.0
			if now - last_left_touch_time <= mobile_dash_double_tap_window:
				mobile_dash_requested = true
			last_left_touch_time = now
			return

		if not is_left_side and touch_aim_id == -1:
			touch_aim_id = event.index
			mobile_aim_active = true
			mobile_aim_position = _screen_to_world(event.position)
			_shoot_to(mobile_aim_position)
			mobile_fire_cooldown = mobile_fire_interval
			return
	else:
		if event.index == touch_move_id:
			touch_move_id = -1
			mobile_move_vector = Vector2.ZERO
			return

		if event.index == touch_aim_id:
			touch_aim_id = -1
			mobile_aim_active = false
			return

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	touch_controls_enabled = true

	if event.index == touch_move_id:
		var offset := event.position - move_touch_origin
		if offset == Vector2.ZERO:
			mobile_move_vector = Vector2.ZERO
		else:
			mobile_move_vector = offset.limit_length(mobile_joystick_radius) / mobile_joystick_radius
		return

	if event.index == touch_aim_id:
		mobile_aim_active = true
		mobile_aim_position = _screen_to_world(event.position)
		return

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos
