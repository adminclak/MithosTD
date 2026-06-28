class_name GameScreen
extends Node2D

## Uma partida (uma fase). Monta nível, HUD, BuildManager (esquadrão) e ondas.
## Fase de PREPARAÇÃO: o jogador posiciona torres e só então clica "Lancar Onda".
## Botões: lançar onda, pause, velocidade (x1/x2) e abandonar.
## Emite finished(victory) quando a partida acaba.

signal finished(victory: bool)

const START_HP := 20
const START_GOLD := 180

var auto_start: bool = false ## smoke test: começa as ondas sozinho

var _stage: StageData
var _squad: Array = []
var _wave_manager: WaveManager
var _match_hud: MatchHud
var _fast: bool = false
var _ended: bool = false


func setup(stage: StageData, squad_datas: Array) -> void:
	_stage = stage
	_squad = squad_datas


func _ready() -> void:
	GameState.reset_run(START_HP, START_GOLD)

	var level := Level.new()
	add_child(level)

	var enemies_root := Node2D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)

	var build_manager := BuildManager.new()
	build_manager.setup(level.get_waypoints(), _squad)
	add_child(build_manager)

	var hud := Hud.new()
	add_child(hud)

	var ability_bar := AbilityBar.new()
	add_child(ability_bar)

	_match_hud = MatchHud.new()
	add_child(_match_hud)
	_match_hud.advance_pressed.connect(_on_advance)
	_match_hud.pause_pressed.connect(_on_pause)
	_match_hud.speed_pressed.connect(_on_speed)
	_match_hud.abandon_pressed.connect(_on_abandon)
	_match_hud.set_phase("Preparacao — posicione suas torres e clique Lancar Onda")

	_wave_manager = WaveManager.new()
	_wave_manager.waypoints = level.get_waypoints()
	_wave_manager.enemies_root = enemies_root
	_wave_manager.total_waves = _stage.waves
	_wave_manager.stage_index = _stage.index
	_wave_manager.enemy_hp_mult = _stage.enemy_hp_mult
	_wave_manager.enemy_count_mult = _stage.enemy_count_mult
	_wave_manager.phase_changed.connect(_on_phase_changed)
	add_child(_wave_manager)

	GameState.game_over.connect(_on_game_over)

	if auto_start:
		_wave_manager.player_advance()


func _on_advance() -> void:
	if _wave_manager.can_advance():
		_wave_manager.player_advance()


func _on_phase_changed(text: String) -> void:
	_match_hud.set_phase(text)
	_match_hud.set_advance_enabled(_wave_manager.can_advance())


func _on_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	_match_hud.set_paused(p)


func _on_speed() -> void:
	_fast = not _fast
	Engine.time_scale = 2.0 if _fast else 1.0
	_match_hud.set_fast(_fast)


func _on_abandon() -> void:
	if _ended:
		return
	_ended = true
	_restore_run_state()
	finished.emit(false)


func _on_game_over(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	_restore_run_state()
	await get_tree().create_timer(1.2).timeout
	finished.emit(victory)


func _restore_run_state() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
