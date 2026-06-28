class_name GameScreen
extends Node2D

## Uma partida (uma fase). Monta o nível, a HUD, o BuildManager (com o esquadrão
## levado) e as ondas conforme a dificuldade da fase. Emite `finished(victory)`
## quando a partida acaba. O cálculo de XP/desbloqueio fica no App (main.gd).

signal finished(victory: bool)

const START_HP := 20
const START_GOLD := 150

var _stage: StageData
var _squad: Array = []   ## TowerData (com char_id)


func setup(stage: StageData, squad_datas: Array) -> void:
	_stage = stage
	_squad = squad_datas


func _ready() -> void:
	GameState.reset_run(START_HP, START_GOLD)

	var level := Level.new()
	add_child(level)

	var hud := Hud.new()
	add_child(hud)

	var ability_bar := AbilityBar.new()
	add_child(ability_bar)

	var enemies_root := Node2D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)

	var build_manager := BuildManager.new()
	build_manager.setup(level.get_tower_slots_for(_stage.slots), level.get_waypoints(), _squad)
	add_child(build_manager)

	var wave_manager := WaveManager.new()
	wave_manager.waypoints = level.get_waypoints()
	wave_manager.enemies_root = enemies_root
	wave_manager.total_waves = _stage.waves
	wave_manager.enemy_hp_mult = _stage.enemy_hp_mult
	wave_manager.enemy_count_mult = _stage.enemy_count_mult
	add_child(wave_manager)
	wave_manager.start_waves()

	GameState.game_over.connect(_on_game_over)


func _on_game_over(victory: bool) -> void:
	# Pequena pausa pra ler o "VITORIA/DERROTA" antes de ir ao resultado.
	await get_tree().create_timer(1.5).timeout
	finished.emit(victory)
