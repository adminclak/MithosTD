class_name WaveManager
extends Node

## Gera as ondas de uma fase usando a composição do WaveComposer e o bestiário.
## A dificuldade (hp/contagem) vem da StageData via GameScreen.

@export var total_waves: int = 5
@export var stage_index: int = 1
@export var spawn_interval: float = 0.6
@export var wave_pause: float = 3.0
@export var wave_bonus: int = 20 ## ouro ganho ao concluir cada onda
@export var enemy_hp_mult: float = 1.0
@export var enemy_count_mult: float = 1.0

var waypoints: Array = []
var enemies_root: Node2D


func start_waves() -> void:
	_run_waves()


func _run_waves() -> void:
	for w in range(1, total_waves + 1):
		if GameState.is_over():
			return
		GameState.set_wave(w, total_waves)
		for group in WaveComposer.compose(stage_index, w, total_waves):
			var count: int = max(1, int(round(group["count"] * enemy_count_mult)))
			for i in count:
				if GameState.is_over():
					return
				_spawn(group["id"])
				await get_tree().create_timer(spawn_interval).timeout
		# Bônus por concluir a onda.
		GameState.add_gold(wave_bonus)
		if w < total_waves:
			await get_tree().create_timer(wave_pause).timeout

	# Espera a tela limpar dos inimigos restantes.
	while get_tree().get_nodes_in_group("enemies").size() > 0:
		if GameState.is_over():
			return
		await get_tree().create_timer(0.5).timeout
	if not GameState.is_over():
		GameState.win()


func _spawn(enemy_id: String) -> void:
	var d := GreekBestiary.by_id(enemy_id)
	if d == null:
		return
	var e := Enemy.new()
	e.apply_data(d, enemy_hp_mult)
	e.setup(waypoints)
	if enemies_root != null:
		enemies_root.add_child(e)
	else:
		add_child(e)
