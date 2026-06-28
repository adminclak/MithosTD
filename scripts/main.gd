extends Node2D
## App / gerenciador de telas (Camada 4).
## Fluxo: Hub (esquadrão + fases) -> GameScreen (partida) -> ResultScreen
## (XP/desbloqueio) -> Hub. A persistência fica no autoload Progression.

var _current: Node = null


func _ready() -> void:
	# Tema visual global (fonte de jogo + molduras Kenney) em todas as telas.
	UiTheme.apply(get_window())
	# Atalho de smoke test: "-- --auto-stage" inicia a fase 1 direto com os
	# personagens iniciais, exercitando o fluxo Partida -> Resultado sem input.
	var args := OS.get_cmdline_user_args()
	if args.has("--auto-stage"):
		var idx := 1
		for a in args:
			if a.is_valid_int():
				idx = clampi(int(a), 1, StageList.count())
		# Esquadrao de demo variado (bloqueio + AoE + dano + suporte).
		var squad := ["hercules", "ares", "artemis", "zeus", "atena", "medusa"]
		_on_start_stage(StageList.get_stage(idx), squad, "zeus", true)
	elif args.has("--heroes"):
		_show_heroes()
	elif args.has("--worldmap"):
		_show_worldmap()
	elif args.has("--collection"):
		_show_collection()
	elif args.has("--gacha"):
		_show_gacha()
	elif args.has("--quests"):
		_show_quests()
	else:
		_show_title()


func _show_title() -> void:
	var t := TitleScreen.new()
	t.play_pressed.connect(_show_worldmap)
	t.heroes_pressed.connect(_show_heroes)
	t.shop_pressed.connect(_show_collection)
	t.quests_pressed.connect(_show_quests)
	t.gacha_pressed.connect(_show_gacha)
	_switch_to(t)


func _show_worldmap() -> void:
	var w := WorldMapScreen.new()
	w.stage_chosen.connect(_start_stage_from_map)
	w.back.connect(_show_title)
	_switch_to(w)


func _show_heroes() -> void:
	var h := HeroesScreen.new()
	h.closed.connect(_show_title)
	_switch_to(h)


func _start_stage_from_map(stage: StageData) -> void:
	_on_start_stage(stage, Progression.current_squad(), Progression.current_ult(), false)


func _show_collection() -> void:
	var screen := CollectionScreen.new()
	screen.closed.connect(_show_title)
	_switch_to(screen)


func _show_gacha() -> void:
	var screen := GachaScreen.new()
	screen.closed.connect(_show_title)
	_switch_to(screen)


func _show_quests() -> void:
	var screen := QuestsScreen.new()
	screen.closed.connect(_show_title)
	_switch_to(screen)


func _on_start_stage(stage: StageData, squad_ids: Array, ult_id: String = "", auto: bool = false) -> void:
	var squad_datas: Array = []
	for id in squad_ids:
		var ch := Roster.by_id(id)
		if ch != null:
			var data := ch.tower_data_for_level(Progression.level_of(id), Progression.stars_of(id))
			var worn: Array = Progression.equipped_data(id)
			for item in worn:
				item.apply_to(data)
				data.equip_icons[item.slot] = item.icon_id() ## p/ mostrar vestido no boneco
			EquipSets.apply(data, worn) ## bônus de conjunto (2/4 peças)
			squad_datas.append(data)

	# Sinergias de equipe (mitologia / duplas / classe / elemento) aplicadas a todos.
	Synergy.apply(squad_ids, squad_datas)

	var game := GameScreen.new()
	game.setup(stage, squad_datas, ult_id)
	game.auto_start = auto
	game.finished.connect(_on_game_finished.bind(stage, squad_ids))
	_switch_to(game)


func _on_game_finished(victory: bool, stage: StageData, squad_ids: Array) -> void:
	print("Fim da fase %d - vitoria: %s" % [stage.index, victory])
	if victory:
		Progression.record_win()
	var xp: int = stage.xp_reward if victory else int(round(stage.xp_reward * 0.3))
	var summary := Progression.grant_squad_xp(squad_ids, xp)
	var rewards := Progression.grant_rewards(stage.index, victory)
	var newly: Array = []
	if victory:
		newly = Progression.mark_stage_cleared(stage.index)
	Progression.save_game()

	var result := ResultScreen.new()
	result.setup(victory, xp, summary, newly, rewards)
	result.continue_pressed.connect(_show_title)
	_switch_to(result)


func _switch_to(screen: Node) -> void:
	# Seguranca: nenhuma tela deve herdar pause/velocidade de uma partida.
	get_tree().paused = false
	Engine.time_scale = 1.0
	if _current != null and is_instance_valid(_current):
		_current.queue_free()
	_current = screen
	add_child(screen)
