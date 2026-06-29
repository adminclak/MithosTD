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
var _ult_layer: CanvasLayer = null
var _aimer: UltAimer = null
var _champion: Champion = null
var _enemies_root: Node2D = null
var _aim_mode: String = ""
var _power2_charge: float = 1.0 ## Reforços (2º poder), começa pronto
const POWER2_CHARGE_TIME := 18.0


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
	_enemies_root = enemies_root

	_build_manager = BuildManager.new()
	_build_manager.setup(level.get_waypoints(), _squad, level.get_build_slots())
	add_child(_build_manager)

	# Campeão (1 por partida): o herói escolhido anda pelo mapa (clique no chão = mover).
	if not _squad.is_empty():
		var champ_id := Progression.current_champion()
		var champ_data: TowerData = _squad[0]
		for d in _squad:
			if d.char_id == champ_id:
				champ_data = d
				break
		_champion = Champion.new()
		_champion.setup(champ_data)
		_champion.position = Vector2(620, 400)
		enemies_root.add_child(_champion)

	var hud := Hud.new()
	add_child(hud)

	# Anúncio de onda em pergaminho (estilo KR).
	var popup := ScrollPopup.new()
	add_child(popup)
	GameState.wave_changed.connect(func(cur, total):
		if cur >= 1:
			popup.announce("ONDA %d / %d" % [cur, total]))

	_match_hud = MatchHud.new()
	add_child(_match_hud)
	_match_hud.advance_pressed.connect(_on_advance)
	_match_hud.pause_pressed.connect(_on_pause)
	_match_hud.speed_pressed.connect(_on_speed)
	_match_hud.abandon_pressed.connect(_confirm_abandon)
	_match_hud.ult_pressed.connect(_on_ult)
	_match_hud.power2_pressed.connect(_on_power2)
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

	# Camada do Poder Supremo (acima de tudo) + sobreposição de mira.
	_ult_layer = CanvasLayer.new()
	_ult_layer.layer = 11
	add_child(_ult_layer)
	_aimer = UltAimer.new()
	_aimer.aimed.connect(_on_aimed)
	_ult_layer.add_child(_aimer)

	if auto_start:
		_auto_place_demo()
		_wave_manager.player_advance()


## Demo automática (smoke / auto-stage): constrói as 4 torres genéricas nos slots,
## para exercitar o combate sem input.
func _auto_place_demo() -> void:
	GameState.add_gold(1500) # ouro extra apenas para a demo
	var classes := TowerData.all_classes()
	var sl: Array = _build_manager.slots
	for i in sl.size():
		_build_manager.try_place(sl[i], classes[i % classes.size()])


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
		# Smoke/demo: dispara sozinho no centro quando carregado.
		if auto_start and _ult_charge >= 1.0:
			_aim_mode = "ult"
			_fire_ult_at(UltimateEffect.CENTER)

	# Carga dos Reforços (2º poder).
	if not _ended and _wave_manager != null and not _wave_manager.is_in_prep():
		if _power2_charge < 1.0:
			_power2_charge = min(1.0, _power2_charge + delta / POWER2_CHARGE_TIME)
		_match_hud.set_power2_charge(_power2_charge)


## Clique no chão (não consumido por slot/UI) = move o campeão até ali.
func _unhandled_input(event: InputEvent) -> void:
	if _champion == null or _ended:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_champion.move_to(get_global_mouse_position())


## Roteia o clique de mira para o poder ativo (ult ou reforços).
func _on_aimed(pos: Vector2) -> void:
	if _aim_mode == "ult":
		_fire_ult_at(pos)
	elif _aim_mode == "power2":
		_fire_power2_at(pos)
	_aim_mode = ""


func _on_ult() -> void:
	if _ult == null or _ult_charge < 1.0 or _ended:
		return
	_aim_mode = "ult"
	_aimer.start(_ult.color)


## Reforços: mira e invoca 3 soldados temporários no ponto escolhido.
func _on_power2() -> void:
	if _power2_charge < 1.0 or _ended:
		return
	_aim_mode = "power2"
	_aimer.start(Color(0.5, 0.95, 0.5))


func _fire_power2_at(pos: Vector2) -> void:
	if _power2_charge < 1.0:
		return
	_power2_charge = 0.0
	_match_hud.set_power2_charge(0.0)
	for o in [Vector2(-22, 0), Vector2(22, 0), Vector2(0, 22)]:
		var d := TowerData.new()
		d.is_melee = true
		d.max_hp = 70
		d.defense = 3
		d.melee_damage = 11
		d.melee_attack_rate = 1.1
		d.block_capacity = 1
		d.engage_radius = 74.0
		d.body_color = Color(0.55, 0.7, 0.95)
		var ally := Tower.new()
		ally.force_building = false ## reforço é um soldadinho, não prédio
		ally.setup(d)
		ally.waypoints = _wave_manager.waypoints if _wave_manager != null else []
		ally.position = pos + o
		_enemies_root.add_child(ally)
		get_tree().create_timer(12.0).timeout.connect(func(): if is_instance_valid(ally): ally.queue_free())


## Lança a ult no ponto escolhido (anima na camada de cima + aplica o efeito).
func _fire_ult_at(pos: Vector2) -> void:
	if _ult == null or _ult_charge < 1.0 or _ended:
		return
	_ult_charge = 0.0
	_match_hud.set_ult_charge(0.0)
	var fx := UltimateEffect.new()
	_ult_layer.add_child(fx)
	fx.play(_ult, pos)


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
