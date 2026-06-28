class_name GameScreen
extends Node2D

## Uma partida (uma fase). Monta nível, HUD, BuildManager (esquadrão) e ondas.
## Fase de PREPARAÇÃO: o jogador posiciona torres e só então clica "Lancar Onda".
## Botões: lançar onda, pause, velocidade (x1/x2) e abandonar.
## Emite finished(victory) quando a partida acaba.

signal finished(victory: bool)

const START_HP := 20
const START_GOLD := 220
const PREP_TIME := 10.0 ## segundos de preparação antes da 1ª onda
const ULT_CHARGE_TIME := 28.0 ## segundos de onda para encher o Poder Supremo

var auto_start: bool = false ## smoke test: começa as ondas sozinho
var _prep_timer: float = PREP_TIME

var _stage: StageData
var _squad: Array = []
var _wave_manager: WaveManager
var _build_manager: BuildManager
var _match_hud: MatchHud
var _fast: bool = false
var _ended: bool = false

# Poder Supremo escolhido para a partida (1 por partida) e sua carga (0..1).
var _ult: UltimateData = null
var _ult_charge: float = 1.0 ## começa carregado para a 1ª investida


func setup(stage: StageData, squad_datas: Array, ult_char_id: String = "") -> void:
	_stage = stage
	_squad = squad_datas
	var cid := ult_char_id
	if cid == "" and not squad_datas.is_empty():
		cid = squad_datas[0].char_id
	if cid != "":
		_ult = Ultimates.for_character(cid)


func _ready() -> void:
	GameState.reset_run(START_HP, START_GOLD)

	var level := Level.new()
	if _stage != null:
		level.theme = _stage.theme
	add_child(level)

	var enemies_root := Node2D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)

	_build_manager = BuildManager.new()
	_build_manager.setup(level.get_waypoints(), _squad)
	add_child(_build_manager)

	# Barra de heróis no rodapé -> clique entra no modo de colocação (fantasma).
	var squad_bar := SquadBar.new()
	squad_bar.setup(_build_manager)
	squad_bar.char_selected.connect(_build_manager.start_placing)
	add_child(squad_bar)

	var hud := Hud.new()
	add_child(hud)

	var ability_bar := AbilityBar.new()
	add_child(ability_bar)

	_match_hud = MatchHud.new()
	add_child(_match_hud)
	_match_hud.advance_pressed.connect(_on_advance)
	_match_hud.pause_pressed.connect(_on_pause)
	_match_hud.speed_pressed.connect(_on_speed)
	_match_hud.abandon_pressed.connect(_confirm_abandon)
	_match_hud.ult_pressed.connect(_on_ult)
	_match_hud.set_phase("Preparacao: %ds — posicione e clique Lancar Onda" % int(PREP_TIME))
	if _ult != null:
		_match_hud.set_ult(_ult.display_name, _ult.color)

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
		_auto_place_demo()
		_wave_manager.player_advance()


## Demo automática (smoke / auto-stage): posiciona o esquadrão sozinho, em zonas
## válidas, para exercitar o combate e o desenho das torres sem input.
func _auto_place_demo() -> void:
	GameState.add_gold(1500) # ouro extra apenas para a demo
	var ranged := [Vector2(200, 280), Vector2(560, 300), Vector2(900, 280), Vector2(1130, 300)]
	var melee := [Vector2(360, 290), Vector2(760, 300), Vector2(1040, 360)]
	var ri := 0
	var mi := 0
	for data in _squad:
		var pos: Vector2
		if data.tower_class == TowerData.TowerClass.WARRIOR:
			pos = melee[mi % melee.size()]
			mi += 1
		else:
			pos = ranged[ri % ranged.size()]
			ri += 1
		_build_manager.try_place(pos, data)


func _process(delta: float) -> void:
	# Contagem regressiva da preparação (só antes da 1ª onda).
	if _wave_manager != null and _wave_manager.is_in_prep() and not _ended:
		_prep_timer -= delta
		if _prep_timer <= 0.0:
			_wave_manager.player_advance()
		else:
			_match_hud.set_phase("Preparacao: %ds — posicione e clique Lancar Onda" % ceil(_prep_timer))

	# Carga do Poder Supremo (enche durante as ondas).
	if _ult != null and not _ended and _wave_manager != null and not _wave_manager.is_in_prep():
		if _ult_charge < 1.0:
			_ult_charge = min(1.0, _ult_charge + delta / ULT_CHARGE_TIME)
		_match_hud.set_ult_charge(_ult_charge)
		# Smoke/demo: dispara sozinho quando carregado (exercita a animação).
		if auto_start and _ult_charge >= 1.0:
			_on_ult()


func _on_ult() -> void:
	if _ult == null or _ult_charge < 1.0 or _ended:
		return
	_ult_charge = 0.0
	_match_hud.set_ult_charge(0.0)
	var fx := UltimateEffect.new()
	add_child(fx)
	fx.play(_ult)


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


func _confirm_abandon() -> void:
	if _ended:
		return
	get_tree().paused = true
	var dlg := ConfirmationDialog.new()
	dlg.title = "Abandonar"
	dlg.dialog_text = "Abandonar a partida? Voce perde o progresso desta fase."
	dlg.ok_button_text = "Abandonar"
	dlg.cancel_button_text = "Continuar jogando"
	dlg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dlg)
	dlg.confirmed.connect(func():
		get_tree().paused = false
		_do_abandon())
	dlg.canceled.connect(func():
		get_tree().paused = false
		dlg.queue_free())
	dlg.popup_centered()


func _do_abandon() -> void:
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
