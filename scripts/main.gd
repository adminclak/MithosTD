extends Node2D
## App / gerenciador de telas (Camada 4).
## Fluxo: Hub (esquadrão + fases) -> GameScreen (partida) -> ResultScreen
## (XP/desbloqueio) -> Hub. A persistência fica no autoload Progression.

var _current: Node = null
var _no_save: bool = false ## simulação fresca: não grava o save real do jogador


func _ready() -> void:
	# Tema visual global (fonte de jogo + molduras Kenney) em todas as telas.
	UiTheme.apply(get_window())
	# Atalho de smoke test: "-- --auto-stage" inicia a fase 1 direto com os
	# personagens iniciais, exercitando o fluxo Partida -> Resultado sem input.
	var args := OS.get_cmdline_user_args()
	# Teste: zera o progresso (heróis, moedas, fases) para experimentar a campanha
	# do começo. Uso: Godot --path . -- --reset-save
	if args.has("--reset-save"):
		Progression.reset()
		Progression.ensure_starting_team()
		Progression.save_game()
		print("Progresso resetado (--reset-save).")
	if args.has("--shot"):
		_shot_mode(args)
		return
	if args.has("--auto-stage"):
		var idx := 1
		for a in args:
			if a.is_valid_int():
				idx = clampi(int(a), 1, StageList.count())
		# Esquadrao de demo variado (bloqueio + AoE + dano + suporte).
		var squad := ["hercules", "ares", "artemis", "zeus", "atena", "medusa"]
		var ult := "zeus"
		# --fresh-sim: simula um JOGADOR NOVO (starters nivel 1, sem bencaos) só EM
		# MEMORIA, sem gravar — para medir a dificuldade base sem o save leveldo.
		if args.has("--fresh-sim"):
			Progression.reset()
			Progression.ensure_starting_team()
			squad = Roster.STARTERS.duplicate()
			ult = squad[0]
			_no_save = true
			print("Simulacao FRESCA (starters nv1, sem gravar).")
		_on_start_stage(StageList.get_stage(idx), squad, ult, true)
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


## Modo de captura: abre uma tela, espera renderizar e salva um PNG, depois sai.
## Uso: Godot --path . -- --shot <title|worldmap|heroes|collection|gacha|quests>
func _shot_mode(args: Array) -> void:
	var which := "title"
	for a in args:
		if a in ["title", "worldmap", "heroes", "collection", "gacha", "quests", "game", "blessings", "picker", "build"]:
			which = a
	match which:
		"worldmap": _show_worldmap()
		"picker":
			_show_worldmap()
			await get_tree().process_frame
			(_current as WorldMapScreen)._on_node(StageList.get_stage(1))
		"build":
			# Abre o menu de um slot vazio na fase 1 p/ ver a lista de heróis.
			_on_start_stage(StageList.get_stage(1), \
				["hercules", "ares", "artemis", "atena", "apolo", "medusa", "hermes"], "ares", false)
			for _i in 5:
				await get_tree().process_frame
			var g := _current as GameScreen
			if g != null and g._build_manager != null and not g._build_manager.slots.is_empty():
				g._build_manager._open_build(0)
		"heroes": _show_heroes()
		"collection": _show_collection()
		"gacha": _show_gacha()
		"quests": _show_quests()
		"blessings": _show_blessings()
		"game":
			var gidx := 1
			for a in args:
				if a.is_valid_int():
					gidx = clampi(int(a), 1, StageList.count())
			_on_start_stage(StageList.get_stage(gidx), \
				["hercules", "ares", "artemis", "atena", "apolo", "medusa", "hermes"], "ares", true)
		_: _show_title()
	var waits := 150 if which == "game" else 30
	for i in waits:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("c:/projetos/jogoTD/_shot_%s.png" % which)
	get_tree().quit()


func _show_title() -> void:
	var t := TitleScreen.new()
	t.play_pressed.connect(_show_worldmap)
	t.heroes_pressed.connect(_show_heroes)
	t.shop_pressed.connect(_show_collection)
	t.quests_pressed.connect(_show_quests)
	t.gacha_pressed.connect(_show_gacha)
	t.blessings_pressed.connect(_show_blessings)
	_switch_to(t)


func _show_blessings() -> void:
	var screen := BlessingsScreen.new()
	screen.closed.connect(_show_title)
	_switch_to(screen)


func _show_worldmap() -> void:
	var w := WorldMapScreen.new()
	w.stage_chosen.connect(_start_stage_from_map)
	w.back.connect(_show_title)
	_switch_to(w)


func _show_heroes() -> void:
	var h := HeroesScreen.new()
	h.closed.connect(_show_title)
	_switch_to(h)


func _start_stage_from_map(stage: StageData, diff: int = 0) -> void:
	_on_start_stage(stage, Progression.current_squad(), Progression.current_ult(), false, diff)


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


func _on_start_stage(stage: StageData, squad_ids: Array, ult_id: String = "", auto: bool = false, diff: int = 0) -> void:
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

	# Bênção Fúria de Ares (+dano permanente): cobre torres-herói e o campeão (que
	# usam estes dados); as torres genéricas recebem o mesmo no BuildManager.
	var dmg_mult := Progression.bless_damage_mult()
	if dmg_mult != 1.0:
		for d in squad_datas:
			d.damage = int(round(d.damage * dmg_mult))
			d.melee_damage = int(round(d.melee_damage * dmg_mult))

	var game := GameScreen.new()
	game.setup(stage, squad_datas, ult_id, diff)
	game.auto_start = auto
	game.finished.connect(_on_game_finished.bind(stage, squad_ids, diff))
	_switch_to(game)


func _on_game_finished(victory: bool, stars: int, stage: StageData, squad_ids: Array, diff: int = 0) -> void:
	print("Fim da fase %d [%s] - vitoria: %s (%d estrelas)" % [stage.index, Difficulty.name_of(diff), victory, stars])
	if victory:
		Progression.record_win()
	var reward_mult := Difficulty.reward_mult(diff)
	var base_xp: int = stage.xp_reward if victory else int(round(stage.xp_reward * 0.3))
	var xp: int = int(round(base_xp * reward_mult))
	var summary := Progression.grant_squad_xp(squad_ids, xp)
	var rewards := Progression.grant_rewards(stage.index, victory, diff)
	var newly: Array = []
	var star_info := {}
	var diff_unlocked := false
	if victory:
		newly = Progression.mark_stage_cleared(stage.index)
		star_info = Progression.record_stars(stage.index, stars)
		diff_unlocked = Progression.record_stage_diff(stage.index, diff)
		# Bônus de Essência por NOVAS estrelas (incentivo a refazer melhor).
		var gained: int = star_info.get("gained", 0)
		if gained > 0:
			rewards["essence"] = int(rewards.get("essence", 0)) + gained * 3
			Progression.add_essence(gained * 3)
	if not _no_save:
		Progression.save_game()

	var result := ResultScreen.new()
	result.setup(victory, xp, summary, newly, rewards, stars, star_info)
	result.set_difficulty(diff, diff_unlocked and diff + 1 < Difficulty.count())
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
