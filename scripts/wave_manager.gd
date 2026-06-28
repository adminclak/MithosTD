class_name WaveManager
extends Node

## Gera as ondas de uma fase. Tem uma FASE DE PREPARAÇÃO: as ondas só começam
## quando o jogador manda (player_advance). Entre ondas há um intervalo que o
## jogador pode ANTECIPAR (também via player_advance), ganhando um bônus de ouro.

signal phase_changed(text: String)

@export var total_waves: int = 5
@export var stage_index: int = 1
@export var spawn_interval: float = 0.6
@export var wave_pause: float = 8.0   ## intervalo entre ondas (antecipável)
@export var wave_bonus: int = 20      ## ouro por concluir a onda
@export var early_bonus: int = 15     ## ouro extra por antecipar a próxima
@export var enemy_hp_mult: float = 1.0
@export var enemy_count_mult: float = 1.0

var waypoints: Array = []
var enemies_root: Node2D

var _begun: bool = false
var _skip: bool = false
var _in_interval: bool = false


## Chamado pelo botão do jogador: inicia a 1ª onda (sai da prep) ou antecipa a
## próxima durante o intervalo.
func player_advance() -> void:
	if not _begun:
		_begun = true
		phase_changed.emit("Onda a caminho!")
		_run_waves()
	elif _in_interval:
		_skip = true


func is_in_prep() -> bool:
	return not _begun


func can_advance() -> bool:
	return not _begun or _in_interval


func _run_waves() -> void:
	for w in range(1, total_waves + 1):
		if GameState.is_over():
			return
		GameState.set_wave(w, total_waves)
		phase_changed.emit("Onda %d/%d" % [w, total_waves])
		for group in WaveComposer.compose(stage_index, w, total_waves):
			var count: int = max(1, int(round(group["count"] * enemy_count_mult)))
			for i in count:
				if GameState.is_over():
					return
				_spawn(group["id"])
				await get_tree().create_timer(spawn_interval).timeout
		GameState.add_gold(wave_bonus)
		if w < total_waves:
			await _interval()

	# Espera limpar os inimigos restantes.
	while get_tree().get_nodes_in_group("enemies").size() > 0:
		if GameState.is_over():
			return
		await get_tree().create_timer(0.5).timeout
	if not GameState.is_over():
		GameState.win()


## Intervalo entre ondas: espera wave_pause OU a antecipação do jogador.
func _interval() -> void:
	_in_interval = true
	_skip = false
	phase_changed.emit("Prepare-se... (pode antecipar)")
	var elapsed := 0.0
	while elapsed < wave_pause and not _skip and not GameState.is_over():
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	if _skip and not GameState.is_over():
		GameState.add_gold(early_bonus) # recompensa por antecipar
	_in_interval = false


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
