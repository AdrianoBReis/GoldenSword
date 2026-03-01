extends Node2D

@onready var hud_label: Label = $HUD/Info
@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $Spawner
@onready var shots_layer: Node2D = $Shots
@onready var victory_layer: CanvasLayer = $VictoryLayer
@onready var victory_prompt: Label = $VictoryLayer/ExitPrompt
@onready var victory_music: AudioStreamPlayer = $VictoryMusic
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var shot_sfx: AudioStreamPlayer = $ShotSfx
@onready var coin_sfx: AudioStreamPlayer = $CoinSfx
@onready var enemy_destroyed_sfx: AudioStreamPlayer = $EnemyDestroyedSfx

@export var victory_score := 10000
@export var victory_duration := 10.0

var score := 0
var time_left := 90.0
var combo := 1
var combo_timer := 0.0
var game_over := false
var victory_active := false
var victory_timer := 0.0
var victory_can_exit := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spawner.connect("coin_collected", _on_coin_collected)
	spawner.connect("target_hit", _on_target_hit)
	player.connect("shot_fired", _on_shot_fired)
	if background_music.stream != null:
		if not background_music.finished.is_connected(_on_background_music_finished):
			background_music.finished.connect(_on_background_music_finished)
		background_music.play()
	victory_layer.visible = false
	victory_prompt.visible = false
	victory_prompt.text = "Toque para fechar" if OS.has_feature("mobile") else "Pressione qualquer tecla para fechar"
	_update_hud("Colete energia e destrua drones neon!")

func _process(delta: float) -> void:
	if victory_active:
		victory_timer = maxf(victory_timer - delta, 0.0)
		if victory_timer == 0.0 and not victory_can_exit:
			victory_can_exit = true
			victory_prompt.visible = true
		return

	if game_over:
		if Input.is_action_just_pressed("fire"):
			get_tree().reload_current_scene()
		return

	time_left = maxf(time_left - delta, 0.0)
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer == 0.0:
		combo = 1

	if time_left == 0.0:
		game_over = true
		_update_hud("Fim de jogo! Pontos: %d | Clique para reiniciar" % score)
		return

	_update_hud(
		"Tempo: %02d  Pontos: %d  Combo x%d\n%s"
		% [int(ceil(time_left)), score, combo, _get_controls_hint()]
	)

func _input(event: InputEvent) -> void:
	if victory_can_exit and _is_exit_input(event):
		get_tree().quit()
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_coin_collected(world_position: Vector2) -> void:
	score += 10 * combo
	combo_timer = 2.5
	coin_sfx.play()
	_spawn_pulse(world_position, Color(0.2, 0.95, 1, 0.7), 46.0)
	_check_victory()

func _on_target_hit(world_position: Vector2) -> void:
	combo = min(combo + 1, 6)
	combo_timer = 2.0
	score += 25 * combo
	enemy_destroyed_sfx.play()
	_spawn_pulse(world_position, Color(1, 0.28, 0.35, 0.8), 68.0)
	_check_victory()

func _on_shot_fired(from_pos: Vector2, _to_pos: Vector2, hit_position: Vector2, did_hit: bool) -> void:
	shot_sfx.play()
	var tracer := Line2D.new()
	tracer.width = 4.0
	tracer.default_color = Color(0.7, 0.95, 1, 0.9) if did_hit else Color(1, 0.82, 0.35, 0.8)
	tracer.add_point(from_pos)
	tracer.add_point(hit_position)
	shots_layer.add_child(tracer)

	var tween := create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.12)
	tween.finished.connect(tracer.queue_free)

func _spawn_pulse(center: Vector2, color: Color, radius: float) -> void:
	var pulse := Polygon2D.new()
	pulse.color = color
	pulse.polygon = PackedVector2Array([Vector2.ZERO, Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0), Vector2(0, -8)])
	pulse.global_position = center
	shots_layer.add_child(pulse)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector2(radius / 8.0, radius / 8.0), 0.24)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.24)
	tween.finished.connect(pulse.queue_free)

func _update_hud(text_value: String) -> void:
	hud_label.text = text_value

func _check_victory() -> void:
	if victory_active or game_over:
		return
	if score < victory_score:
		return
	_start_victory()

func _start_victory() -> void:
	victory_active = true
	victory_timer = victory_duration
	victory_can_exit = false
	victory_layer.visible = true
	victory_prompt.visible = false
	hud_label.visible = false
	shots_layer.visible = false
	player.set_physics_process(false)
	player.set_process_input(false)
	_stop_gameplay_music()
	if victory_music.stream != null:
		victory_music.play()

func _stop_gameplay_music() -> void:
	if background_music.playing:
		background_music.stop()

func _on_background_music_finished() -> void:
	if victory_active:
		return
	if background_music.stream != null:
		background_music.play()

func _is_exit_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func _get_controls_hint() -> String:
	if OS.has_feature("mobile"):
		return "Toque esquerdo mover | Toque direito mirar/atirar | Toque duplo esquerdo dash"
	return "WASD mover | Espaco dash | Mouse mirar/atirar"
