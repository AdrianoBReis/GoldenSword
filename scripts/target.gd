extends Area2D

signal destroyed(world_position: Vector2)

@export var drift_radius := 26.0
@export var drift_speed := 1.8

@onready var body_visual: Polygon2D = $Body
@onready var core_visual: Polygon2D = $Core
@onready var collision: CollisionShape2D = $CollisionShape2D

var alive := true
var origin := Vector2.ZERO
var phase := 0.0

func _ready() -> void:
	origin = global_position
	phase = randf() * TAU

func _process(delta: float) -> void:
	if not alive:
		return
	phase += delta * drift_speed
	global_position = origin + Vector2(cos(phase), sin(phase * 1.1)) * drift_radius
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
	alive = true
	body_visual.visible = true
	core_visual.visible = true
	collision.disabled = false
