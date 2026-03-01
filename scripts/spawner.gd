extends Node2D

signal coin_collected(world_position: Vector2)
signal target_hit(world_position: Vector2)

const COIN_SCENE := preload("res://scenes/Coin.tscn")
const TARGET_SCENE := preload("res://scenes/Target.tscn")

@export var arena_size := Vector2(1020, 540)
@export var coin_count := 14
@export var target_count := 7
@export var coin_min_spacing := 140.0
@export var target_min_spacing := 170.0
@export var coin_player_min_distance := 130.0
@export var target_start_min_distance := 320.0
@export var target_respawn_min_distance := 180.0

var player_ref: Node2D
var coins: Array[Node2D] = []
var targets: Array[Node2D] = []

func _ready() -> void:
	randomize()
	player_ref = get_tree().get_first_node_in_group("player") as Node2D
	_spawn_coins()
	_spawn_targets()

func _spawn_coins() -> void:
	for _idx in range(coin_count):
		var coin := COIN_SCENE.instantiate()
		add_child(coin)
		coins.append(coin)
		coin.call("place_at", _random_position(40.0, _collect_positions(coins, coin), coin_min_spacing, coin_player_min_distance, 48))
		coin.connect("picked", _on_coin_picked.bind(coin))

func _spawn_targets() -> void:
	for _idx in range(target_count):
		var target := TARGET_SCENE.instantiate()
		add_child(target)
		targets.append(target)
		target.reset_target(_random_position(80.0, _collect_positions(targets, target), target_min_spacing, target_start_min_distance, 160))
		target.connect("destroyed", _on_target_destroyed.bind(target))

func _random_position(
	margin: float,
	avoid_positions: Array[Vector2] = [],
	min_spacing: float = 0.0,
	player_min_distance: float = 110.0,
	max_tries: int = 24
) -> Vector2:
	var tries := 0
	var best_candidate := global_position
	var best_score := -INF
	while tries < max_tries:
		var candidate := global_position + Vector2(
			randf_range(-arena_size.x * 0.5 + margin, arena_size.x * 0.5 - margin),
			randf_range(-arena_size.y * 0.5 + margin, arena_size.y * 0.5 - margin)
		)
		var dist_player := INF if player_ref == null else candidate.distance_to(player_ref.global_position)
		var nearest_other := _nearest_distance(candidate, avoid_positions)
		var far_from_player := player_ref == null or dist_player > player_min_distance
		if far_from_player and _respects_spacing(candidate, avoid_positions, min_spacing):
			return candidate

		var spacing_penalty := 0.0 if min_spacing <= 0.0 else maxf(min_spacing - nearest_other, 0.0) * 3.0
		var player_penalty := 0.0 if player_ref == null else maxf(player_min_distance - dist_player, 0.0) * 2.5
		var score := dist_player + nearest_other - spacing_penalty - player_penalty
		if score > best_score:
			best_score = score
			best_candidate = candidate
		tries += 1
	return best_candidate

func _collect_positions(nodes: Array[Node2D], skip_node: Node2D) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for node in nodes:
		if is_instance_valid(node) and node != skip_node:
			positions.append(node.global_position)
	return positions

func _respects_spacing(candidate: Vector2, avoid_positions: Array[Vector2], min_spacing: float) -> bool:
	if min_spacing <= 0.0:
		return true
	for pos in avoid_positions:
		if candidate.distance_to(pos) < min_spacing:
			return false
	return true

func _nearest_distance(candidate: Vector2, avoid_positions: Array[Vector2]) -> float:
	if avoid_positions.is_empty():
		return INF
	var nearest := INF
	for pos in avoid_positions:
		nearest = minf(nearest, candidate.distance_to(pos))
	return nearest

func _on_coin_picked(world_position: Vector2, coin: Node2D) -> void:
	emit_signal("coin_collected", world_position)
	coin.call("place_at", _random_position(40.0, _collect_positions(coins, coin), coin_min_spacing, coin_player_min_distance, 32))

func _on_target_destroyed(world_position: Vector2, target: Node2D) -> void:
	emit_signal("target_hit", world_position)
	target.reset_target(_random_position(80.0, _collect_positions(targets, target), target_min_spacing, target_respawn_min_distance, 80))
