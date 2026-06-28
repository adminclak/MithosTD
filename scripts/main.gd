extends Node2D
## App / gerenciador de telas (Camada 4).
## Fluxo: Hub (esquadrão + fases) -> GameScreen (partida) -> ResultScreen
## (XP/desbloqueio) -> Hub. A persistência fica no autoload Progression.

var _current: Node = null


func _ready() -> void:
	# Atalho de smoke test: "-- --auto-stage" inicia a fase 1 direto com os
	# personagens iniciais, exercitando o fluxo Partida -> Resultado sem input.
	if OS.get_cmdline_user_args().has("--auto-stage"):
		var squad := Progression.unlocked_ids()
		_on_start_stage(StageList.get_stage(1), squad.slice(0, Progression.SQUAD_MAX))
	else:
		_show_hub()


func _show_hub() -> void:
	var hub := HubScreen.new()
	hub.start_stage.connect(_on_start_stage)
	_switch_to(hub)


func _on_start_stage(stage: StageData, squad_ids: Array) -> void:
	var squad_datas: Array = []
	for id in squad_ids:
		var ch := GreekRoster.by_id(id)
		if ch != null:
			squad_datas.append(ch.tower_data_for_level(Progression.level_of(id)))

	var game := GameScreen.new()
	game.setup(stage, squad_datas)
	game.finished.connect(_on_game_finished.bind(stage, squad_ids))
	_switch_to(game)


func _on_game_finished(victory: bool, stage: StageData, squad_ids: Array) -> void:
	print("Fim da fase %d - vitoria: %s (XP +%d)" % [stage.index, victory, \
		stage.xp_reward if victory else int(round(stage.xp_reward * 0.3))])
	var xp: int = stage.xp_reward if victory else int(round(stage.xp_reward * 0.3))
	var summary := Progression.grant_squad_xp(squad_ids, xp)
	var newly: Array = []
	if victory:
		newly = Progression.mark_stage_cleared(stage.index)
	Progression.save_game()

	var result := ResultScreen.new()
	result.setup(victory, xp, summary, newly)
	result.continue_pressed.connect(_show_hub)
	_switch_to(result)


func _switch_to(screen: Node) -> void:
	if _current != null and is_instance_valid(_current):
		_current.queue_free()
	_current = screen
	add_child(screen)
