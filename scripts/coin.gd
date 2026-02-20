extends Area3D

signal picked

@export var spin_speed := 2.2
@export var bob_speed := 3.5
@export var bob_height := 0.25

var base_y := 0.0
var elapsed := 0.0

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	elapsed += delta
	rotate_y(spin_speed * delta)
	position.y = base_y + sin(elapsed * bob_speed) * bob_height

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("picked")
