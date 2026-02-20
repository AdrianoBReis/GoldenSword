extends Node3D

signal coin_collected
signal target_hit

const COIN_SCENE := preload("res://scenes/Coin.tscn")
const TARGET_SCENE := preload("res://scenes/Target.tscn")

@export var arena_size := 16.0
@export var coin_count := 12
@export var target_count := 6

func _ready() -> void:
	randomize()
	_spawn_coins()
	_spawn_targets()

func _spawn_coins() -> void:
	for _idx in coin_count:
		var coin := COIN_SCENE.instantiate()
		coin.position = _random_position(0.8)
		coin.connect("picked", _on_coin_picked.bind(coin))
		add_child(coin)

func _spawn_targets() -> void:
	for _idx in target_count:
		var target := TARGET_SCENE.instantiate()
		target.position = _random_position(1.2)
		target.connect("destroyed", _on_target_destroyed.bind(target))
		add_child(target)

func _random_position(y_height: float) -> Vector3:
	return Vector3(
		randf_range(-arena_size, arena_size),
		y_height,
		randf_range(-arena_size, arena_size)
	)

func _on_coin_picked(coin: Node3D) -> void:
	emit_signal("coin_collected")
	coin.position = _random_position(0.8)

func _on_target_destroyed(target: Node3D) -> void:
	emit_signal("target_hit")
	target.position = _random_position(1.2)
	target.call("reset_target")
