extends Area2D

signal destroyed(world_position: Vector2)

@export var chase_speed := 120.0
@export var chase_acceleration := 3.2
@export var wobble_radius := 12.0
@export var wobble_speed := 2.2

@onready var body_visual: Polygon2D = $Body
@onready var core_visual: Polygon2D = $Core
@onready var collision: CollisionShape2D = $CollisionShape2D

var alive := true
var origin := Vector2.ZERO
var phase := 0.0
var current_velocity := Vector2.ZERO
var player_ref: Node2D

func _ready() -> void:
	origin = global_position
	phase = randf() * TAU

func _process(delta: float) -> void:
	if not alive:
		return
	phase += delta * wobble_speed
	if is_instance_valid(player_ref):
		var to_player := player_ref.global_position - global_position
		if to_player != Vector2.ZERO:
			var target_velocity := to_player.normalized() * chase_speed
			current_velocity = current_velocity.lerp(target_velocity, clampf(chase_acceleration * delta, 0.0, 1.0))
			global_position += current_velocity * delta
	else:
		current_velocity = current_velocity.lerp(Vector2.ZERO, clampf(chase_acceleration * delta, 0.0, 1.0))
	global_position += Vector2(cos(phase), sin(phase * 1.3)) * wobble_radius * delta
	rotation += delta * 1.2
	core_visual.scale = Vector2.ONE * (1.0 + sin(phase * 3.0) * 0.08)

func on_hit() -> void:
	if not alive:
		return
	alive = false
	body_visual.visible = false
	core_visual.visible = false
	collision.disabled = true
	emit_signal("destroyed", global_position)

func reset_target(new_origin: Vector2 = global_position) -> void:
	origin = new_origin
	global_position = new_origin
	phase = randf() * TAU
	current_velocity = Vector2.ZERO
	alive = true
	body_visual.visible = true
	core_visual.visible = true
	collision.disabled = false

func set_player(player_node: Node2D) -> void:
	player_ref = player_node
