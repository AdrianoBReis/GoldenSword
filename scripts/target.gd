extends StaticBody3D

signal destroyed

@export var drift_radius := 1.4
@export var drift_speed := 1.8

@onready var mesh: MeshInstance3D = $MeshInstance3D

var alive := true
var origin := Vector3.ZERO
var phase := 0.0

func _ready() -> void:
	origin = position
	phase = randf() * TAU

func _process(delta: float) -> void:
	if not alive:
		return
	phase += delta * drift_speed
	position.x = origin.x + cos(phase) * drift_radius
	position.z = origin.z + sin(phase) * drift_radius

func on_hit() -> void:
	if not alive:
		return
	alive = false
	mesh.visible = false
	$CollisionShape3D.disabled = true
	emit_signal("destroyed")

func reset_target() -> void:
	origin = position
	phase = randf() * TAU
	alive = true
	mesh.visible = true
	$CollisionShape3D.disabled = false
