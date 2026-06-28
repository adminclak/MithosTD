extends Node2D
## Cena principal — Camada 1.
## Monta o nível, posiciona torres de teste nos slots, cria a HUD e inicia as ondas.

const START_HP := 20
const START_GOLD := 150

func _ready() -> void:
	GameState.reset_run(START_HP, START_GOLD)

	# Nível: caminho, base e slots de torre
	var level := Level.new()
	add_child(level)

	# HUD (CanvasLayer, fica sempre por cima)
	var hud := Hud.new()
	add_child(hud)

	# Container para os inimigos vivos
	var enemies_root := Node2D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)

	# Camada 3: o jogador invoca/upa/vende torres clicando nos slots (gastando ouro).
	var build_manager := BuildManager.new()
	build_manager.setup(level.get_tower_slots(), level.get_waypoints())
	add_child(build_manager)

	# Ondas de inimigos
	var wave_manager := WaveManager.new()
	wave_manager.waypoints = level.get_waypoints()
	wave_manager.enemies_root = enemies_root
	add_child(wave_manager)
	wave_manager.start_waves()

	GameState.game_over.connect(_on_game_over)

func _on_game_over(victory: bool) -> void:
	print("FIM DE JOGO — vitoria: ", victory)
