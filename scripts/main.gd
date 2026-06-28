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

	# Camada 2: uma torre de cada classe nos slots, pra ver o combate completo.
	var slots := level.get_tower_slots()
	var waypoints := level.get_waypoints()
	var loadout := [
		TowerData.archer(),  # slot 0
		TowerData.mage(),    # slot 1
		TowerData.warrior(), # slot 2 (perto do caminho — invoca bloqueadores)
		TowerData.priest(),  # slot 3 (buffa o Arqueiro vizinho + lentidão/cura)
		TowerData.archer(),  # slot 4
	]
	for i in slots.size():
		var tower := Tower.new()
		tower.setup(loadout[i % loadout.size()])
		tower.waypoints = waypoints
		tower.position = slots[i]
		add_child(tower)

	# Ondas de inimigos
	var wave_manager := WaveManager.new()
	wave_manager.waypoints = level.get_waypoints()
	wave_manager.enemies_root = enemies_root
	add_child(wave_manager)
	wave_manager.start_waves()

	GameState.game_over.connect(_on_game_over)

func _on_game_over(victory: bool) -> void:
	print("FIM DE JOGO — vitoria: ", victory)
