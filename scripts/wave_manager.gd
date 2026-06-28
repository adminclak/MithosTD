class_name WaveManager
extends Node

@export var total_waves: int = 5
@export var base_count: int = 5
@export var per_wave: int = 2
@export var spawn_interval: float = 0.7
@export var wave_pause: float = 3.0
@export var wave_bonus: int = 20 ## ouro ganho ao concluir cada onda

var waypoints: Array = []
var enemies_root: Node2D


func start_waves() -> void:
	_run_waves()


func _run_waves() -> void:
	for w in range(1, total_waves + 1):
		if GameState.is_over():
			return
		GameState.set_wave(w, total_waves)
		var count: int = base_count + (w - 1) * per_wave
		for i in count:
			if GameState.is_over():
				return
			_spawn_one()
			await get_tree().create_timer(spawn_interval).timeout
		# Bônus por concluir a onda (todos os inimigos dela já foram lançados).
		GameState.add_gold(wave_bonus)
		if w < total_waves:
			await get_tree().create_timer(wave_pause).timeout
	# Espera a tela limpar de inimigos restantes.
	while get_tree().get_nodes_in_group("enemies").size() > 0:
		if GameState.is_over():
			return
		await get_tree().create_timer(0.5).timeout
	if not GameState.is_over():
		GameState.win()


func _spawn_one() -> void:
	var e := Enemy.new()
	e.setup(waypoints)
	if enemies_root != null:
		enemies_root.add_child(e)
	else:
		add_child(e)
