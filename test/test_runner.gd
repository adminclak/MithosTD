extends SceneTree
## Test runner próprio (sem dependências externas).
## Roda com:  godot --headless --path . -s res://test/test_runner.gd
## Sai com código 0 se tudo passar, 1 se algo falhar (bom pra CI).
##
## Nota: o autoload `GameState` NÃO existe neste modo `-s`, então os testes
## evitam caminhos que tocam esse identificador (ex.: mortes que dão ouro).

var _passed := 0
var _failed := 0

func _initialize() -> void:
	# No modo -s a árvore só fica ativa a partir do 1º frame; sem isso os nós
	# adicionados ao root não ficam "inside tree" e get_tree() retorna null.
	await process_frame
	print("=== Testes Mithos TD ===")
	_test_game_state()
	_test_tower_data()
	_test_projectile_aoe()
	_test_blocking()
	_test_priest_aura()
	_test_economy()
	_test_build_menu_ui()
	_test_progression()
	_test_squad_uniqueness()
	print("\n=== RESULTADO: %d passou, %d falhou ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", msg)
	else:
		_failed += 1
		print("  [FAIL] ", msg)

func _test_game_state() -> void:
	print("\nGameState (vida / ouro / fim de jogo):")
	var GS = load("res://scripts/game_state.gd")

	# Estado inicial
	var gs = GS.new()
	gs.reset_run(20, 150)
	_check(gs.base_hp == 20, "reset_run define base_hp = 20")
	_check(gs.gold == 150, "reset_run define gold = 150")
	_check(gs.is_over() == false, "run comeca sem game over")

	# Economia
	gs.add_gold(50)
	_check(gs.gold == 200, "add_gold soma corretamente")
	_check(gs.try_spend(100) == true, "try_spend com saldo retorna true")
	_check(gs.gold == 100, "try_spend desconta o ouro")
	_check(gs.try_spend(9999) == false, "try_spend sem saldo retorna false")
	_check(gs.gold == 100, "try_spend sem saldo nao mexe no ouro")

	# Derrota ao zerar a vida
	var loss := {"called": false, "victory": null}
	gs.game_over.connect(func(v): loss["called"] = true; loss["victory"] = v)
	gs.take_base_damage(5)
	_check(gs.base_hp == 15, "take_base_damage reduz a vida")
	gs.take_base_damage(999)
	_check(gs.base_hp == 0, "vida nao fica negativa (clamp em 0)")
	_check(loss["called"] == true, "game_over emitido ao zerar a vida")
	_check(loss["victory"] == false, "derrota => victory = false")
	gs.free()

	# Vitória
	var gs2 = GS.new()
	gs2.reset_run(20, 0)
	var win := {"victory": null}
	gs2.game_over.connect(func(v): win["victory"] = v)
	gs2.win()
	_check(win["victory"] == true, "win() => game_over com victory = true")
	gs2.free()

func _test_tower_data() -> void:
	print("\nTowerData (as 4 classes):")
	var a = TowerData.archer()
	_check(a.tower_class == TowerData.TowerClass.ARCHER, "archer() tem classe ARCHER")
	_check(a.cost == 100, "Arqueiro custa 100")
	_check(a.splash_radius == 0.0, "Arqueiro e alvo unico (sem splash)")

	var m = TowerData.mage()
	_check(m.tower_class == TowerData.TowerClass.MAGE, "mage() tem classe MAGE")
	_check(m.splash_radius > 0.0, "Mago tem dano em area (splash > 0)")
	_check(m.cost == 150, "Mago custa 150")

	var w = TowerData.warrior()
	_check(w.tower_class == TowerData.TowerClass.WARRIOR, "warrior() tem classe WARRIOR")
	_check(w.blocker_count >= 1, "Guerreiro invoca >= 1 bloqueador")
	_check(w.blocker_hp > 0, "bloqueador tem vida")

	var p = TowerData.priest()
	_check(p.tower_class == TowerData.TowerClass.PRIEST, "priest() tem classe PRIEST")
	_check(p.aura_radius > 0.0, "Sacerdote tem aura")
	_check(p.aura_damage_mult > 1.0, "Sacerdote buffa dano (mult > 1)")
	_check(p.aura_slow_mult < 1.0, "Sacerdote tem lentidao (mult < 1)")

func _test_projectile_aoe() -> void:
	print("\nProjectile (dano em area do Mago):")
	var e1 = Enemy.new(); e1.max_hp = 100
	var e2 = Enemy.new(); e2.max_hp = 100
	var e3 = Enemy.new(); e3.max_hp = 100
	root.add_child(e1)
	root.add_child(e2)
	root.add_child(e3)
	e1.global_position = Vector2(100, 100)
	e2.global_position = Vector2(130, 100) # dentro do splash (72)
	e3.global_position = Vector2(400, 400) # fora do splash

	var proj = Projectile.new()
	root.add_child(proj)
	proj.global_position = Vector2(100, 100)
	proj.setup(e1, 10, 72.0, Color.WHITE)
	proj._impact()

	_check(e1.hp == 90, "AoE atinge o alvo (-10)")
	_check(e2.hp == 90, "AoE atinge inimigo proximo dentro do raio")
	_check(e3.hp == 100, "AoE nao atinge inimigo fora do raio")

	e1.free(); e2.free(); e3.free()

func _test_blocking() -> void:
	print("\nBloqueio do Guerreiro (combate corpo-a-corpo):")
	var enemy = Enemy.new()
	enemy.max_hp = 100
	enemy.attack_damage = 7
	enemy.attack_rate = 100.0
	root.add_child(enemy)
	enemy.global_position = Vector2(500, 420)

	var blocker = BlockerUnit.new()
	blocker.setup(40, 5, 100.0, 60.0, Vector2(500, 420))
	root.add_child(blocker)
	blocker.global_position = Vector2(500, 420)

	_check(enemy.is_blocked() == false, "inimigo comeca livre")

	# O bloqueador encontra e prende o inimigo no raio.
	var found = blocker._find_enemy()
	_check(found == enemy, "bloqueador encontra o inimigo no raio")
	blocker._target_enemy = found
	found.engage(blocker)
	_check(enemy.is_blocked() == true, "engage prende o inimigo")

	# Inimigo bloqueado dá dano corpo-a-corpo no bloqueador.
	enemy._attack_cd = 0.0
	enemy._fight(0.016)
	_check(blocker.hp == 33, "inimigo bloqueado causa dano no bloqueador (40-7)")

	# Outro bloqueador não pega um inimigo já bloqueado.
	var blocker2 = BlockerUnit.new()
	blocker2.setup(40, 5, 1.0, 60.0, Vector2(500, 420))
	root.add_child(blocker2)
	blocker2.global_position = Vector2(500, 420)
	_check(blocker2._find_enemy() == null, "inimigo ja bloqueado nao e pego por outro bloqueador")

	# Morte do bloqueador libera o inimigo.
	blocker.take_damage(999)
	_check(enemy.is_blocked() == false, "morte do bloqueador libera o inimigo")

	enemy.free()
	blocker2.free()

func _test_priest_aura() -> void:
	print("\nAura do Sacerdote (buff / lentidao):")
	var priest = Tower.new()
	priest.setup(TowerData.priest())
	root.add_child(priest)
	priest.global_position = Vector2(0, 0)

	var archer = Tower.new()
	archer.setup(TowerData.archer())
	root.add_child(archer)
	archer.global_position = Vector2(50, 0) # dentro da aura (170)
	archer._recompute_aura_buffs()
	_check(archer._aura_damage_mult > 1.0, "Arqueiro dentro da aura recebe buff de dano")
	_check(is_equal_approx(archer._aura_fire_rate_mult, 1.25), "buff de cadencia aplicado (1.25)")

	var far = Tower.new()
	far.setup(TowerData.archer())
	root.add_child(far)
	far.global_position = Vector2(600, 0) # fora da aura
	far._recompute_aura_buffs()
	_check(is_equal_approx(far._aura_damage_mult, 1.0), "Arqueiro fora da aura nao recebe buff")

	# Lentidão nos inimigos.
	var enemy = Enemy.new(); enemy.max_hp = 50
	root.add_child(enemy)
	enemy.global_position = Vector2(40, 0)
	_check(enemy._aura_speed_mult() < 1.0, "inimigo dentro da aura fica mais lento")

	var enemy2 = Enemy.new(); enemy2.max_hp = 50
	root.add_child(enemy2)
	enemy2.global_position = Vector2(700, 0)
	_check(is_equal_approx(enemy2._aura_speed_mult(), 1.0), "inimigo fora da aura mantem velocidade")

	priest.free(); archer.free(); far.free(); enemy.free(); enemy2.free()

func _test_economy() -> void:
	print("\nEconomia (invocar / upar / vender via BuildManager):")
	var gs = root.get_node_or_null(^"/root/GameState")
	_check(gs != null, "autoload GameState acessivel via /root no modo -s")
	if gs == null:
		return
	gs.reset_run(20, 300)

	var bm = BuildManager.new()
	bm.setup([Vector2(200, 300)], [Vector2(-40, 160), Vector2(360, 160)])
	root.add_child(bm)
	var slot = bm._slots[0]

	# Invocar Arqueiro (100): desconta ouro e ocupa o slot.
	_check(bm.try_build(slot, TowerData.archer()) == true, "try_build com saldo retorna true")
	_check(gs.gold == 200, "invocar Arqueiro desconta 100 (300 -> 200)")
	_check(slot.is_empty() == false, "slot fica ocupado apos invocar")

	# Slot ocupado nao aceita nova torre.
	_check(bm.try_build(slot, TowerData.mage()) == false, "nao invoca em slot ocupado")
	_check(gs.gold == 200, "invocacao recusada nao gasta ouro")

	# Upgrade: custo correto, sobe nivel e desconta.
	var t = slot.tower
	_check(t.level == 1, "torre comeca no nivel 1")
	_check(t.upgrade_cost() == 60, "custo do 1o upgrade do Arqueiro = 60")
	_check(bm.try_upgrade(slot) == true, "try_upgrade com saldo retorna true")
	_check(t.level == 2, "torre sobe para o nivel 2")
	_check(gs.gold == 140, "upgrade desconta 60 (200 -> 140)")

	# Vender devolve 60% do investido (100 + 60 = 160 -> 96) e libera o slot.
	_check(t.sell_value() == 96, "venda devolve 60% do investido (160 -> 96)")
	var before = gs.gold
	_check(bm.sell(slot) == true, "sell retorna true")
	_check(gs.gold == before + 96, "vender credita o valor de venda")
	_check(slot.is_empty() == true, "slot fica vazio apos vender")

	# Sem ouro suficiente: nao invoca e nao gasta.
	gs.reset_run(20, 50)
	var bm2 = BuildManager.new()
	bm2.setup([Vector2(500, 500)], [])
	root.add_child(bm2)
	_check(bm2.try_build(bm2._slots[0], TowerData.archer()) == false, "sem ouro nao invoca Arqueiro (100)")
	_check(gs.gold == 50, "tentativa sem saldo nao gasta ouro")

	bm.free()
	bm2.free()

func _test_build_menu_ui() -> void:
	print("\nUI do BuildMenu (montagem dos paineis):")
	# Painel de invocacao com ouro de sobra: 4 classes + titulo + fechar.
	var menu = BuildMenu.new()
	root.add_child(menu)
	menu.open_build(Vector2(200, 300), TowerData.all_classes(), 300)
	_check(menu._panel.visible == true, "open_build mostra o painel")
	_check(menu._box.get_child_count() == 6, "build lista 4 classes + titulo + fechar")

	# Com pouco ouro (100), so o Arqueiro (100) fica habilitado.
	var menu2 = BuildMenu.new()
	root.add_child(menu2)
	menu2.open_build(Vector2(200, 300), TowerData.all_classes(), 100)
	_check(menu2._box.get_child(1).disabled == false, "Arqueiro (100) habilitado com 100 de ouro")
	_check(menu2._box.get_child(4).disabled == true, "Mago (150) desabilitado com 100 de ouro")

	# Painel de gestao de uma torre: titulo + upar + vender + fechar.
	var menu3 = BuildMenu.new()
	root.add_child(menu3)
	var t = Tower.new()
	t.setup(TowerData.archer())
	root.add_child(t)
	menu3.open_manage(Vector2(200, 300), t, 300)
	_check(menu3._panel.visible == true, "open_manage mostra o painel")
	_check(menu3._box.get_child_count() == 4, "manage mostra titulo + upar + vender + fechar")

	menu.free(); menu2.free(); menu3.free(); t.free()

func _test_progression() -> void:
	print("\nProgressao (XP / nivel / desbloqueio / save):")
	var pr = root.get_node_or_null(^"/root/Progression")
	_check(pr != null, "autoload Progression acessivel via /root no modo -s")
	if pr == null:
		return
	pr.reset()

	# Iniciais: 4 desbloqueados (1 por classe).
	_check(pr.unlocked_ids().size() == 4, "comeca com 4 personagens desbloqueados")
	_check(pr.is_unlocked("artemis") == true, "Artemis (inicial) desbloqueada")
	_check(pr.is_unlocked("hermes") == false, "Hermes comeca bloqueado")
	_check(pr.highest_stage_unlocked == 1, "comeca com a fase 1 liberada")

	# XP sobe de nivel: xp_to_next(1) = 40, entao 100 sobe ao menos 1 nivel.
	var s = pr.grant_squad_xp(["artemis"], 100)
	_check(pr.level_of("artemis") >= 2, "100 de XP sobe Artemis de nivel")
	_check(s["artemis"]["new_level"] == pr.level_of("artemis"), "resumo bate com o nivel novo")

	# Concluir fase 1: desbloqueia Hermes e libera a fase 2.
	var newly = pr.mark_stage_cleared(1)
	_check(newly.has("hermes"), "concluir a fase 1 desbloqueia Hermes")
	_check(pr.is_unlocked("hermes") == true, "Hermes desbloqueado apos a fase 1")
	_check(pr.highest_stage_unlocked == 2, "fase 2 liberada apos concluir a 1")
	_check(pr.unlocked_ids().size() == 5, "agora 5 personagens desbloqueados")

	# Save/load roundtrip num arquivo temporario (nao toca o save real).
	var tmp = "user://test_save_%d.json" % Time.get_ticks_usec()
	pr.save_to(tmp)
	var lvl = pr.level_of("artemis")
	pr.reset()
	_check(pr.is_unlocked("hermes") == false, "reset volta ao estado inicial")
	pr.load_from(tmp)
	_check(pr.is_unlocked("hermes") == true, "load restaura o desbloqueio do Hermes")
	_check(pr.level_of("artemis") == lvl, "load restaura o nivel da Artemis")
	_check(pr.highest_stage_unlocked == 2, "load restaura a fase liberada")
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	# Nivel permanente escala os stats base.
	var ch = GreekRoster.by_id("artemis")
	var base = ch.base_data()
	var d10 = ch.tower_data_for_level(10)
	_check(d10.char_id == "artemis", "tower_data_for_level marca o char_id")
	_check(d10.damage > base.damage, "nivel permanente aumenta o dano base")

	pr.reset()

func _test_squad_uniqueness() -> void:
	print("\nEsquadrao de personagens unicos (BuildManager):")
	var gs = root.get_node_or_null(^"/root/GameState")
	gs.reset_run(20, 1000)
	var data = GreekRoster.by_id("artemis").tower_data_for_level(1)
	var bm = BuildManager.new()
	bm.setup([Vector2(200, 300), Vector2(560, 300)], [], [data])
	root.add_child(bm)
	_check(bm._available_squad().size() == 1, "esquadrao com 1 personagem: 1 disponivel")
	bm.try_build(bm._slots[0], data)
	_check(bm._available_squad().size() == 0, "apos invocar, 0 disponiveis (personagem unico)")
	bm.sell(bm._slots[0])
	_check(bm._available_squad().size() == 1, "apos vender, o personagem volta a ficar disponivel")
	bm.free()
