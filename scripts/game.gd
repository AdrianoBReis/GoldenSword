extends Node3D

@onready var hud_label: Label = $HUD/Info
@onready var player: CharacterBody3D = $Player
@onready var spawner: Node3D = $Spawner

var score := 0
var time_left := 90.0
var game_over := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawner.connect("coin_collected", _on_coin_collected)
	spawner.connect("target_hit", _on_target_hit)
	_update_hud("Colete cubos azuis e acerte alvos vermelhos!")

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("fire"):
			get_tree().reload_current_scene()
		return

	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		game_over = true
		_update_hud("Fim de jogo! Pontos: %d | Clique para reiniciar" % score)
	else:
		_update_hud("Tempo: %02d  Pontos: %d\nWASD mover | Espaço pular | Mouse mirar" % [int(time_left), score])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_coin_collected() -> void:
	score += 10

func _on_target_hit() -> void:
	score += 25

func _update_hud(text_value: String) -> void:
	hud_label.text = text_value
