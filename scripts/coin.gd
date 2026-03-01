extends Area2D

signal picked(world_position: Vector2)

@export var spin_speed := 3.4
@export var bob_speed := 4.2
@export var bob_height := 7.0

@onready var disk: Polygon2D = $Disk

var base_position := Vector2.ZERO
var elapsed := 0.0

func _ready() -> void:
	base_position = position
	elapsed = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	elapsed += delta
	rotation += spin_speed * delta
	position.y = base_position.y + sin(elapsed * bob_speed) * bob_height
	var pulse := 1.0 + sin(elapsed * 6.0) * 0.06
	disk.scale = Vector2.ONE * pulse

func place_at(world_position: Vector2) -> void:
	global_position = world_position
	base_position = position
	elapsed = randf() * TAU

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("picked", global_position)
