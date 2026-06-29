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
	_test_combat_polish()
	_test_blocking()
	_test_priest_aura()
	_test_economy()
	_test_build_menu_ui()
	_test_progression()
	_test_gacha()
	_test_quests()
	_test_squad_uniqueness()
	_test_abilities()
	_test_equipment()
	_test_shop_evolution()
	_test_bestiary()
	_test_wave_composition()
	_test_balance()
	_test_attributes()
	_test_combat_stats()
	_test_ability_families()
	_test_elements()
	_test_sets_synergy()
	_test_all_characters_act()
	print("\n=== RESULTADO: %d passou, %d falhou ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


## Garante que TODOS os personagens do roster AGEM em campo: ranged dispara um
## projétil; melee trava/fere um inimigo no raio. Pega "personagens parados".
func _test_all_characters_act() -> void:
	print("\nTodos os personagens agem em campo:")
	var gs = root.get_node_or_null(^"/root/GameState")
	if gs != null:
		gs.reset_run(20, 0)
	var dead: Array = []
	for d in Roster.defs():
		var id: String = d[0]
		var ch = Roster.by_id(id)
		var data = ch.tower_data_for_level(1, 1)
		var t = Tower.new()
		t.setup(data)
		root.add_child(t)
		t.global_position = Vector2(500, 400)
		var e = Enemy.new()
		e.max_hp = 1000
		e.hp = 1000
		root.add_child(e)
		e.global_position = Vector2(515, 400)
		var acted := false
		if data.is_melee:
			t._process_melee(0.5)
			acted = e.hp < 1000 or e.is_blocked()
		else:
			var before := _count_projectiles()
			t._process(0.6)
			acted = _count_projectiles() > before
		if not acted:
			dead.append(id)
		t.free()
		e.free()
		_clear_projectiles()
	var ok := dead.is_empty()
	_check(ok, "todos os personagens agem em campo" + ("" if ok else " — PARADOS: %s" % str(dead)))


func _test_elements() -> void:
	print("\nElementos (ciclo + luz/trevas):")
	var E = Elements.E
	_check(is_equal_approx(Elements.mult(E.AGUA, E.FOGO), 1.5), "Agua forte vs Fogo (+50%)")
	_check(is_equal_approx(Elements.mult(E.FOGO, E.AGUA), 0.75), "Fogo fraco vs Agua (-25%)")
	_check(is_equal_approx(Elements.mult(E.FOGO, E.TERRA), 1.5), "Fogo forte vs Terra")
	_check(is_equal_approx(Elements.mult(E.LUZ, E.TREVAS), 1.5), "Luz forte vs Trevas")
	_check(is_equal_approx(Elements.mult(E.TREVAS, E.LUZ), 1.5), "Trevas forte vs Luz")
	_check(is_equal_approx(Elements.mult(E.FOGO, E.FOGO), 1.0), "mesmo elemento = neutro")
	_check(Elements.of_character("zeus") == E.AR, "Zeus = Ar")
	_check(Elements.of_character("hades") == E.TREVAS, "Hades = Trevas")
	# Aplicacao no inimigo (lacaio = Terra).
	var e = Enemy.new()
	e.apply_data(GreekBestiary.by_id("lacaio"))
	root.add_child(e)
	e.hp = 100
	e.take_damage(20, 0, E.FOGO) # fogo forte vs terra: 20 -> 30
	_check(e.hp == 70, "Fogo (forte) +50% no inimigo Terra (20->30)")
	e.hp = 100
	e.take_damage(20, 0, E.AR) # ar fraco vs terra: 20 -> 15
	_check(e.hp == 85, "Ar (fraco) -25% no inimigo Terra (20->15)")
	e.free()


func _test_sets_synergy() -> void:
	print("\nSets de equipamento + sinergia de equipe:")
	# Set Olimpo: 2 pecas dao +12% dano.
	var d = TowerData.mage() # dano 6
	var items2 = [EquipmentList.by_id("raio_zeus"), EquipmentList.by_id("egide_atena")]
	EquipSets.apply(d, items2)
	_check(d.damage == 7, "Set Olimpo 2pc: +12% dano (6->7)")
	# 4 pecas: aplica 2pc + 4pc (dano e critico).
	var d2 = TowerData.mage()
	var items4 = [EquipmentList.by_id("raio_zeus"), EquipmentList.by_id("egide_atena"),
		EquipmentList.by_id("sandalias_hermes"), EquipmentList.by_id("coroa_louros")]
	EquipSets.apply(d2, items4)
	_check(d2.damage == 9 and d2.crit_chance > 0.09, "Set Olimpo 4pc: dano e critico maiores")
	# Sinergia: trio iconico.
	var syn = Synergy.active(["zeus", "poseidon", "hades"])
	var names: Array = []
	for s in syn:
		names.append(s["name"])
	_check(names.has("Os Tres Tronos"), "combo 'Os Tres Tronos' ativo")
	var datas = [TowerData.mage()]
	var before = datas[0].damage
	Synergy.apply(["zeus", "poseidon", "hades"], datas)
	_check(datas[0].damage > before, "sinergia aumenta o dano de todos")


func _count_projectiles() -> int:
	var n := 0
	for c in root.get_children():
		if c is Projectile:
			n += 1
	return n


func _clear_projectiles() -> void:
	for c in root.get_children():
		if c is Projectile:
			c.free()

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
	_check(w.is_melee == true, "Guerreiro e melee (tanka na rota)")
	_check(w.max_hp > 0, "melee tem vida")
	_check(w.block_capacity >= 1, "melee segura ao menos 1 inimigo")

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

## As 3 "joias" trazidas dos TDs de referência: slow-on-hit (torre de gelo/água),
## projétil em arco (artilharia) e feedback de impacto (número de dano flutuante).
func _test_combat_polish() -> void:
	print("\nPolimento de combate (slow / arco / numero de dano):")

	# 1) Slow-on-hit: projétil de água atrasa o inimigo atingido.
	var e = Enemy.new(); e.max_hp = 100
	root.add_child(e)
	e.global_position = Vector2(100, 100)
	var pj = Projectile.new()
	root.add_child(pj)
	pj.global_position = Vector2(100, 100)
	pj.setup(e, 10, 0.0, Color.WHITE, 0, -1, 0.55, 1.3) # slow_mult 0.55, dur 1.3
	pj._impact()
	_check(e.is_slowed(), "projetil de gelo aplica lentidao no acerto")
	_check(e.hp == 90, "projetil de gelo tambem causa dano")
	e.free()

	# 2) Projétil em arco (lob) chega ao destino e causa dano em área.
	var a1 = Enemy.new(); a1.max_hp = 100
	root.add_child(a1)
	a1.global_position = Vector2(300, 300)
	var lob = Projectile.new()
	root.add_child(lob)
	lob.global_position = Vector2(120, 300)
	lob.speed = 400.0
	lob.setup(a1, 15, 72.0, Color.WHITE)
	lob.set_arc(48.0, a1)
	_check(lob._arc, "set_arc liga o modo balistico")
	for _i in 240: # avança o voo até o impacto (queue_free no fim)
		if not is_instance_valid(lob):
			break
		lob._process(0.016)
	_check(a1.hp < 100, "projetil em arco causa dano ao cair no alvo")
	a1.free()

	# 3) Feedback: take_damage cria um número de dano flutuante no pai.
	var before := _count_popups()
	var e2 = Enemy.new(); e2.max_hp = 100
	root.add_child(e2)
	e2.global_position = Vector2(500, 500)
	e2.take_damage(7)
	_check(_count_popups() == before + 1, "take_damage cria 1 numero de dano flutuante")
	_check(e2.hp == 93, "take_damage aplica o dano (-7)")
	# DoT não deve encher de números (popup=false por tick).
	var mid := _count_popups()
	e2.take_damage(3, 999, -1, false)
	_check(_count_popups() == mid, "dano por tick (DoT) nao cria numero flutuante")
	e2.free()

	# 4) Data-driven: Mago arremessa em arco; personagem de água tem slow.
	_check(TowerData.mage().proj_arc == true, "Mago (area) usa projetil em arco")
	var water_ok := true
	var water_found := false
	for d in Roster.defs():
		var id: String = d[0]
		if Elements.of_character(id) == Elements.E.AGUA:
			var td = Roster.by_id(id).tower_data_for_level(1, 1)
			if not td.is_melee and td.damage > 0:
				water_found = true
				if not (td.slow_duration > 0.0 and td.slow_mult < 1.0):
					water_ok = false
	_check(not water_found or water_ok, "personagens de agua (ranged) atrasam no acerto")

	_clear_popups()


func _count_popups() -> int:
	var n := 0
	for c in root.get_children():
		if c is DamagePopup:
			n += 1
	return n


func _clear_popups() -> void:
	for c in root.get_children():
		if c is DamagePopup:
			c.free()


func _test_blocking() -> void:
	print("\nCombate melee (personagem tanka na rota):")
	var gs = root.get_node_or_null(^"/root/GameState")
	gs.reset_run(20, 0)

	var t = Tower.new()
	t.setup(TowerData.warrior()) # is_melee, max_hp 120, defense 6, melee_damage 8, cap 3
	root.add_child(t)
	t.global_position = Vector2(500, 420)
	_check(t.data.is_melee == true, "Guerreiro entra como melee")
	_check(t.max_hp() > 0, "melee tem vida")

	var enemy = Enemy.new()
	enemy.max_hp = 100
	enemy.attack_damage = 16
	root.add_child(enemy)
	enemy.global_position = Vector2(520, 420) # dentro do engage_radius

	# Um frame de combate melee: trava e ataca o inimigo.
	t._process_melee(0.2)
	_check(enemy.is_blocked() == true, "melee trava o inimigo no raio")
	_check(enemy.hp < 100, "melee causa dano ao inimigo travado")

	# Inimigo travado bate no melee (dano reduzido pela defesa: 16-6=10).
	var hp_before = t._hp
	enemy._attack_cd = 0.0
	enemy._blocked_by = t
	enemy._fight(0.1)
	_check(t._hp == hp_before - 10, "inimigo causa dano no melee menos a defesa (16-6)")

	# Cair libera os inimigos travados.
	t._go_down()
	_check(t.is_down() == true, "melee cai ao ser derrotado")
	_check(enemy.is_blocked() == false, "ao cair, o melee solta os inimigos")

	t.free()
	enemy.free()

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
	bm.setup([Vector2(0, 300), Vector2(600, 300)]) # rota horizontal; sem squad
	root.add_child(bm)
	var ranged_pos := Vector2(200, 440) # lateral (longe da rota)

	# Invocar Arqueiro (100) em qualquer ponto livre: desconta ouro.
	var archer = TowerData.archer()
	_check(bm.can_place(archer.tower_class, ranged_pos) == true, "pode posicionar em ponto livre")
	_check(bm.try_place(ranged_pos, archer) == true, "try_place com saldo retorna true")
	_check(gs.gold == 200, "invocar Arqueiro desconta 100 (300 -> 200)")
	_check(bm._towers.size() == 1, "torre fica posicionada")

	# Espacamento: nao pode colocar em cima de outra.
	_check(bm.can_place(archer.tower_class, ranged_pos + Vector2(8, 0)) == false, "perto demais e bloqueado")

	# Upgrade.
	var t = bm._tower_at(ranged_pos)
	_check(t != null, "_tower_at encontra a torre clicada")
	_check(t.upgrade_cost() == 60, "custo do 1o upgrade do Arqueiro = 60")
	_check(bm.try_upgrade(t) == true, "try_upgrade com saldo retorna true")
	_check(t.level == 2, "torre sobe para o nivel 2")
	_check(gs.gold == 140, "upgrade desconta 60 (200 -> 140)")

	# Vender devolve 60% do investido (100 + 60 = 160 -> 96).
	_check(t.sell_value() == 96, "venda devolve 60% do investido (160 -> 96)")
	var before = gs.gold
	_check(bm.sell(t) == true, "sell retorna true")
	_check(gs.gold == before + 96, "vender credita o valor de venda")
	_check(bm._towers.size() == 0, "torre removida apos vender")

	# Posicionamento livre: qualquer classe pode em qualquer ponto valido.
	var ponto := Vector2(300, 200)
	_check(bm.can_place(TowerData.warrior().tower_class, ponto) == true, "Guerreiro pode em qualquer ponto livre")
	_check(bm.can_place(TowerData.archer().tower_class, ponto) == true, "Arqueiro pode em qualquer ponto livre")
	_check(bm.can_place(TowerData.archer().tower_class, Vector2(-50, 200)) == false, "fora do mapa e bloqueado")

	# Sem ouro suficiente: nao invoca e nao gasta.
	gs.reset_run(20, 50)
	var bm2 = BuildManager.new()
	bm2.setup([Vector2(0, 300), Vector2(600, 300)])
	root.add_child(bm2)
	_check(bm2.try_place(Vector2(200, 440), TowerData.archer()) == false, "sem ouro nao invoca Arqueiro (100)")
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

	# Foco grego: 8 personagens; comeca com os iniciais.
	_check(Roster.count() == 8, "roster grego tem 8 personagens")
	_check(pr.unlocked_ids().size() == Roster.STARTERS.size(), "comeca com os iniciais")
	_check(pr.is_unlocked("artemis") == true, "Artemis (inicial) desbloqueada")
	_check(pr.is_unlocked("zeus") == false, "Zeus comeca bloqueado")
	_check(pr.highest_stage_unlocked == 1, "comeca com a fase 1 liberada")

	# XP sobe de nivel: xp_to_next(1) = 40, entao 100 sobe ao menos 1 nivel.
	var s = pr.grant_squad_xp(["artemis"], 100)
	_check(pr.level_of("artemis") >= 2, "100 de XP sobe Artemis de nivel")
	_check(s["artemis"]["new_level"] == pr.level_of("artemis"), "resumo bate com o nivel novo")

	# Concluir a fase 1 libera a fase 2; concluir a 5 desbloqueia Zeus (campanha).
	pr.mark_stage_cleared(1)
	_check(pr.highest_stage_unlocked == 2, "fase 2 liberada apos concluir a 1")
	var newly = pr.mark_stage_cleared(5)
	_check(newly.has("zeus"), "fase 5 (Olimpo) desbloqueia Zeus")

	# Save/load roundtrip num arquivo temporario (nao toca o save real).
	var tmp = "user://test_save_%d.json" % Time.get_ticks_usec()
	var lvl = pr.level_of("artemis")
	pr.save_to(tmp)
	pr.reset()
	_check(pr.level_of("artemis") == 1, "reset volta o nivel para 1")
	pr.load_from(tmp)
	_check(pr.level_of("artemis") == lvl, "load restaura o nivel da Artemis")
	_check(pr.highest_stage_unlocked == 2, "load restaura a fase liberada")
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	# Nivel escala os stats (via atributos).
	var ch = Roster.by_id("artemis")
	var d10 = ch.tower_data_for_level(10)
	_check(d10.char_id == "artemis", "tower_data_for_level marca o char_id")
	_check(d10.damage > ch.tower_data_for_level(1).damage, "nivel aumenta o dano (atributos)")
	pr.reset()

func _test_squad_uniqueness() -> void:
	print("\nEsquadrao de personagens unicos (BuildManager):")
	var gs = root.get_node_or_null(^"/root/GameState")
	gs.reset_run(20, 1000)
	var data = Roster.by_id("artemis").tower_data_for_level(1)
	var bm = BuildManager.new()
	bm.setup([Vector2(0, 300), Vector2(600, 300)], [data])
	root.add_child(bm)
	var pos := Vector2(200, 440) # lateral (Artemis e arqueira)
	_check(bm._available_squad().size() == 1, "esquadrao com 1 personagem: 1 disponivel")
	bm.try_place(pos, data)
	_check(bm._available_squad().size() == 0, "apos invocar, 0 disponiveis (personagem unico)")
	bm.sell(bm._tower_at(pos))
	_check(bm._available_squad().size() == 1, "apos vender, o personagem volta a ficar disponivel")
	bm.free()

func _test_abilities() -> void:
	print("\nHabilidades ativas:")
	# DAMAGE_AOE (Flecha Perfurante da Artemis): power 30, raio 230.
	var t = Tower.new()
	t.setup(Roster.by_id("artemis").tower_data_for_level(1))
	root.add_child(t)
	t.global_position = Vector2(0, 0)
	var e1 = Enemy.new(); e1.max_hp = 100
	var e2 = Enemy.new(); e2.max_hp = 100
	root.add_child(e1); root.add_child(e2)
	e1.global_position = Vector2(60, 0)  # dentro do raio
	e2.global_position = Vector2(500, 0) # fora do raio
	_check(t.has_ability(), "Artemis tem habilidade")
	_check(t.ability_cooldown_left() == 0.0, "habilidade comeca pronta")
	_check(t.use_ability() == true, "use_ability dispara")
	_check(e1.hp == 66, "Chuva de Flechas (LINE) fere inimigo no raio (-34)")
	_check(e2.hp == 100, "habilidade nao fere inimigo fora do raio")
	_check(t.ability_cooldown_left() > 0.0, "entra em cooldown apos o uso")
	_check(t.use_ability() == false, "nao dispara enquanto em cooldown")

	# STUN_AOE (Olhar Petrificante da Medusa): atordoa e fere leve.
	var tm = Tower.new()
	tm.setup(Roster.by_id("medusa").tower_data_for_level(1))
	root.add_child(tm)
	tm.global_position = Vector2(0, 0)
	var e3 = Enemy.new(); e3.max_hp = 100
	root.add_child(e3)
	e3.global_position = Vector2(40, 0)
	tm.use_ability()
	_check(e3.is_stunned() == true, "STUN_AOE atordoa o inimigo")

	# BUFF_TOWER (Velocidade Divina do Hermes): buff temporario na propria torre.
	var th = Tower.new()
	th.setup(Roster.by_id("hermes").tower_data_for_level(1))
	root.add_child(th)
	th.global_position = Vector2(0, 0)
	th.use_ability()
	_check(th._temp_mult() == 1.6, "BUFF_TOWER aplica buff temporario (x1.6)")

	# Escudo e cura em personagem melee (habilidades de suporte).
	var mt = Tower.new(); mt.setup(TowerData.warrior()); root.add_child(mt); mt.global_position = Vector2(0, 200)
	mt.apply_shield(5.0)
	mt.take_damage(50)
	_check(mt._hp == mt.max_hp(), "melee com escudo ignora o dano")
	var mt2 = Tower.new(); mt2.setup(TowerData.warrior()); root.add_child(mt2); mt2.global_position = Vector2(0, 260)
	mt2.take_damage(40) # 40 - defesa 6 = 34
	mt2.heal(20)
	_check(mt2._hp == mt2.max_hp() - 14, "heal recupera o melee (dano 34, cura 20 = -14)")

	t.free(); tm.free(); th.free(); e1.free(); e2.free(); e3.free(); mt.free(); mt2.free()

func _test_equipment() -> void:
	print("\nEquipamentos (bonus nos stats):")
	var d = TowerData.archer() # alcance 200
	EquipmentList.by_id("amuleto_vista").apply_to(d) # RANGE +12%
	_check(abs(d.attack_range - 224.0) < 0.01, "Amuleto da Vista: +12% no alcance (200 -> 224)")

	var d2 = TowerData.mage() # dano 6
	EquipmentList.by_id("espada_longa").apply_to(d2) # DAMAGE +20%
	_check(d2.damage == 7, "Espada Longa: +20% no dano (6 -> 7)")

	var d3 = TowerData.mage()
	EquipmentList.by_id("mjolnir").apply_to(d3) # lendario: +45% dano, +14% crit
	_check(d3.damage == 9 and d3.crit_chance > 0.13, "Mjolnir (lendario) some dano e critico")

	var pr = root.get_node_or_null(^"/root/Progression")
	pr.reset()
	pr.meta_gold = 1000
	_check(pr.buy_item("espada_curta") == true, "compra item com ouro meta")
	_check(pr.owns_item("espada_curta") == true, "passa a possuir o item")
	_check(pr.meta_gold == 880, "compra desconta o preco (120)")
	_check(pr.buy_item("espada_curta") == false, "nao compra item ja possuido")

	_check(pr.equip("artemis", EquipmentData.Slot.WEAPON, "espada_curta") == true, "equipa arma compativel")
	_check(pr.is_item_available("espada_curta") == false, "item equipado fica indisponivel")
	_check(pr.equip("hermes", EquipmentData.Slot.WEAPON, "espada_curta") == false, "nao equipa item ja em outro personagem")
	_check(pr.equip("artemis", EquipmentData.Slot.HELMET, "espada_curta") == false, "nao equipa arma no slot de elmo")
	pr.unequip("artemis", EquipmentData.Slot.WEAPON)
	_check(pr.is_item_available("espada_curta") == true, "desequipar devolve a disponibilidade")

	# 8 slots ocupaveis ao mesmo tempo (um item por slot).
	pr.reset()
	for iid in ["kabuto_oni", "oyoroi", "megingjord", "botas_vidar", "mjolnir", "egide_atena", "olho_odin", "anel_ouro"]:
		pr.add_item(iid)
		var it = EquipmentList.by_id(iid)
		pr.equip("zeus", it.slot, iid)
	_check(pr.equipped_data("zeus").size() == 8, "personagem pode usar os 8 slots ao mesmo tempo")
	_check(EquipmentList.count() >= 200, "catalogo com centenas de itens (%d)" % EquipmentList.count())

func _test_shop_evolution() -> void:
	print("\nLoja / evolucao de estrela:")
	var pr = root.get_node_or_null(^"/root/Progression")
	pr.reset()
	pr.add_fragments("artemis", 50)
	pr.meta_gold = 2000
	_check(pr.stars_of("artemis") == 1, "comeca com 1 estrela")
	_check(pr.level_cap("artemis") == 10, "teto de nivel 10 na estrela 1")
	_check(pr.can_evolve("artemis") == true, "pode evoluir com fragmentos + ouro")
	_check(pr.evolve("artemis") == true, "evolui")
	_check(pr.stars_of("artemis") == 2, "sobe para 2 estrelas")
	_check(pr.level_cap("artemis") == 20, "teto de nivel sobe para 20")
	_check(pr.fragments_of("artemis") == 40 and pr.meta_gold == 1700, "evolucao gasta 10 fragmentos + 300 ouro")
	pr.fragments["artemis"] = 0
	_check(pr.can_evolve("artemis") == false, "sem fragmentos nao evolui")

	# Recompensas de fim de fase.
	pr.reset()
	var r = pr.grant_rewards(1, true)
	_check(r["gold"] == 45, "vitoria na fase 1 da 45 de ouro meta")
	_check(r["essence"] == 3, "vitoria na fase 1 da 3 de essencia")
	var r2 = pr.grant_rewards(1, false)
	_check(r2["gold"] == 10, "derrota da 10 de ouro meta")
	_check(r2["ambrosia"] > 0, "fase concede Ambrosia (gacha)")
	pr.reset()

func _test_gacha() -> void:
	print("\nGacha / loja de personagens / fragmentos:")
	var pr = root.get_node_or_null(^"/root/Progression")
	pr.reset()

	# Sem Ambrosia, gacha nao roda.
	_check(pr.gacha_roll().get("ok", false) == false, "gacha sem Ambrosia nao roda")
	pr.add_ambrosia(1000)
	var r = pr.gacha_roll()
	_check(r["ok"] == true, "gacha roda com Ambrosia")
	_check(pr.ambrosia == 900, "gacha gasta 100 de Ambrosia")

	# Repetido vira fragmentos: com todos desbloqueados, todo giro da fragmentos.
	pr.reset()
	for c in Roster.all():
		pr.unlock_character(c.id)
	pr.add_ambrosia(500)
	var r2 = pr.gacha_roll()
	_check(r2["is_new"] == false and r2["fragments"] > 0, "gacha repetido vira fragmentos")

	# Comprar personagem na loja com Ambrosia.
	pr.reset()
	pr.add_ambrosia(5000)
	_check(pr.is_unlocked("zeus") == false, "Zeus comeca bloqueado")
	_check(pr.buy_character("zeus") == true, "compra Zeus com Ambrosia")
	_check(pr.is_unlocked("zeus") == true, "Zeus desbloqueado apos a compra")
	_check(pr.buy_character("zeus") == false, "nao compra Zeus de novo")
	pr.reset()

func _test_quests() -> void:
	print("\nQuests (campanha / diarias / claim):")
	var pr = root.get_node_or_null(^"/root/Progression")
	pr.reset()
	var q := Quests.by_id("q_wins5") # vencer 5 partidas
	_check(pr.quest_complete(q) == false, "quest de 5 vitorias comeca incompleta")
	for i in 5:
		pr.record_win()
	_check(pr.metric_value("wins") == 5, "record_win conta as vitorias")
	_check(pr.quest_complete(q) == true, "quest completa apos 5 vitorias")
	_check(pr.quest_claimable(q) == true, "quest completa e coletavel")
	var amb_before = pr.ambrosia
	_check(pr.claim_quest("q_wins5") == true, "claim da a recompensa")
	_check(pr.ambrosia == amb_before + q["ambrosia"], "claim credita a Ambrosia")
	_check(pr.quest_claimable(q) == false, "quest ja coletada nao e coletavel de novo")
	pr.reset()

func _test_bestiary() -> void:
	print("\nBestiario grego (7 inimigos + divisao da Hidra):")
	var lacaio = GreekBestiary.by_id("lacaio")
	_check(lacaio != null and lacaio.max_hp == 12, "Lacaio tem 12 de vida")
	var talos = GreekBestiary.by_id("talos")
	_check(talos != null and talos.max_hp >= 450, "Talos (boss) tem muita vida")
	var hidra = GreekBestiary.by_id("hidra")
	_check(hidra.special == EnemyData.Special.SPLIT, "Hidra tem comportamento de divisao")

	# apply_data aplica os stats e o multiplicador de vida da fase.
	var e = Enemy.new()
	e.apply_data(GreekBestiary.by_id("esqueleto"), 2.0)
	root.add_child(e)
	_check(e.max_hp == 88, "apply_data aplica hp_mult (44 * 2 = 88)")
	_check(e.hp == 88, "_ready inicia hp = max_hp")
	e.free()

	# Matar uma Hidra gera 2 filhotes que entram no jogo.
	var gs = root.get_node_or_null(^"/root/GameState")
	gs.reset_run(20, 0)
	var hidra_e = Enemy.new()
	hidra_e.apply_data(GreekBestiary.by_id("hidra"))
	hidra_e.setup([Vector2(0, 0), Vector2(200, 0)])
	root.add_child(hidra_e)
	hidra_e.global_position = Vector2(50, 0)
	hidra_e.take_damage(999)
	var filhotes := 0
	for en in get_nodes_in_group("enemies"):
		if is_instance_valid(en) and en.data != null and en.data.id == "hidra_filhote":
			filhotes += 1
	_check(filhotes == 2, "Hidra ao morrer gera 2 filhotes")
	for en in get_nodes_in_group("enemies"):
		if is_instance_valid(en):
			en.free()

	# Todos os tipos do bestiario instanciam sem erro (cobre o boss Talos).
	var ok_all := true
	for ed in GreekBestiary.all():
		var en = Enemy.new()
		en.apply_data(ed)
		en.setup([Vector2(0, 0), Vector2(100, 0)])
		root.add_child(en)
		if not en.is_in_group("enemies") or en.max_hp != ed.max_hp:
			ok_all = false
		en.free()
	_check(ok_all, "todos os 8 tipos do bestiario instanciam corretamente")

func _test_wave_composition() -> void:
	print("\nComposicao de ondas por fase:")
	var g1 = WaveComposer.compose(1, 1, 5)
	_check(g1.size() == 1 and g1[0]["id"] == "lacaio", "fase 1 (tutorial) spawna so lacaios")

	var g3 = WaveComposer.compose(3, 4, 7)
	var has_hidra := false
	for g in g3:
		if g["id"] == "hidra":
			has_hidra = true
	_check(has_hidra, "fase 3 inclui Hidras (premia AoE)")

	var gboss = WaveComposer.compose(5, 5, 5)
	var has_talos := false
	for g in gboss:
		if g["id"] == "talos":
			has_talos = true
	_check(has_talos, "onda final da fase 5 inclui o boss Talos")

## Invariantes de BALANCEAMENTO (modelo da seção de economia/combate). Documentam
## e protegem os "pesos": economia inicial, ritmo de morte, ouro≈esforço, curva de
## inimigos suave (sem picos absurdos) e escala de fase limitada.
func _test_balance() -> void:
	print("\nBalanceamento (economia + curva de inimigos):")

	# Custo da torre mais barata e ouro inicial.
	var cheapest := 1 << 30
	for t in TowerData.all_classes():
		cheapest = min(cheapest, t.cost)
	var start_gold: int = Balance.START_GOLD
	_check(start_gold >= 3 * cheapest,
		"ouro inicial (%d) compra >=3 torres baratas (%d cada)" % [start_gold, cheapest])

	# Uma torre inicial (Arqueiro nv1) derruba um inimigo básico em ~2s.
	var sniper := AttributeStats.build(TowerData.TowerClass.ARCHER,
		Archetypes.base_attr(Archetypes.Kind.ARCHER_SNIPER))
	var dps: float = sniper.damage * sniper.fire_rate
	var lacaio := GreekBestiary.by_id("lacaio")
	_check(dps >= lacaio.max_hp / 2.0,
		"arqueiro inicial mata o básico em ~2s (DPS %.0f vs %d vida)" % [dps, lacaio.max_hp])

	# Ouro ~ esforço: cada inimigo paga numa faixa justa de vida/ouro (sem inimigo
	# que vale ouro de menos nem 'caixa eletrônico').
	var fair := true
	var worst := ""
	for ed in GreekBestiary.all():
		if ed.gold_reward <= 0:
			continue
		var ratio: float = float(ed.max_hp) / float(ed.gold_reward)
		if ratio < 1.2 or ratio > 6.5:
			fair = false
			worst = "%s (%.1f hp/ouro)" % [ed.id, ratio]
	_check(fair, "ouro proporcional ao esforço em todos os inimigos" + ("" if fair else " — fora: " + worst))

	# Recompensa básica não é mesquinha (financia expansão como nos refs).
	_check(lacaio.gold_reward >= cheapest / 25.0,
		"kill básico (%d) financia torres (custo %d)" % [lacaio.gold_reward, cheapest])

	# Curva de inimigos suave: cada degrau <= ~4x o anterior (sem salto 50x).
	var esq := GreekBestiary.by_id("esqueleto")
	var cen := GreekBestiary.by_id("centauro")
	var cic := GreekBestiary.by_id("ciclope")
	var tal := GreekBestiary.by_id("talos")
	var smooth := cen.max_hp <= 3 * esq.max_hp and cic.max_hp <= 3 * cen.max_hp and tal.max_hp <= 4 * cic.max_hp
	_check(smooth, "curva de vida suave (esq->cen->cic->boss sem pico absurdo)")

	# Escala de fase: hp_mult crescente e o boss efetivo na fase 5 é batível (<=1000).
	var prev := 0.0
	var rising := true
	var capped := true
	for s in StageList.all():
		if s.enemy_hp_mult <= prev:
			rising = false
		prev = s.enemy_hp_mult
		if s.enemy_hp_mult > 2.0:
			capped = false
	var boss_eff: float = tal.max_hp * StageList.get_stage(5).enemy_hp_mult
	_check(rising and capped, "hp_mult das fases é crescente e <=2.0")
	_check(boss_eff <= 1000.0, "boss efetivo na fase 5 (%.0f) é batível (<=1000)" % boss_eff)

func _test_attributes() -> void:
	print("\nAtributos (Ragnarok-like) + critico:")
	var base = AttributeSet.make(10, 10, 10, 10, 10, 10)
	var growth = AttributeSet.make(2, 0, 0, 0, 0, 0)
	var at5 = base.plus_scaled(growth, 4) # nivel 5 = base + growth * 4
	_check(at5.strength == 18, "plus_scaled: STR 10 + 2*4 = 18")
	_check(at5.agility == 10, "plus_scaled nao mexe nos outros atributos")

	# STR aumenta o dano do Arqueiro.
	var weak = AttributeStats.build(TowerData.TowerClass.ARCHER, AttributeSet.make(10, 10, 10, 10, 20, 10))
	var strong = AttributeStats.build(TowerData.TowerClass.ARCHER, AttributeSet.make(40, 10, 10, 10, 20, 10))
	_check(strong.damage > weak.damage, "mais STR = mais dano no Arqueiro")

	# INT manda no Mago; VIT na vida do Guerreiro melee.
	var mage = AttributeStats.build(TowerData.TowerClass.MAGE, AttributeSet.make(10, 10, 10, 50, 20, 10))
	_check(mage.damage > weak.damage, "Mago com INT alta tem dano alto")
	var war = AttributeStats.build(TowerData.TowerClass.WARRIOR, AttributeSet.make(10, 10, 50, 10, 10, 10), true)
	_check(war.max_hp > 50, "VIT alta da muita vida ao melee")

	# LUK alta gera chance de critico.
	var lucky = AttributeStats.build(TowerData.TowerClass.ARCHER, AttributeSet.make(10, 10, 10, 10, 10, 80))
	_check(lucky.crit_chance > 0.2, "LUK alta da chance de critico")

func _test_combat_stats() -> void:
	print("\nDefesa / penetracao / melee (builds):")
	# Defesa do inimigo reduz dano; penetracao fura. Usa um inimigo sintético com
	# defesa fixa (desacoplado do ajuste fino do bestiário).
	var armored := EnemyData.new()
	armored.defense = 5
	var e = Enemy.new()
	e.max_hp = 100
	root.add_child(e)
	e.data = armored
	e.take_damage(20, 0)
	_check(e.hp == 85, "defesa reduz o dano (20 - 5 = 15)")
	e.take_damage(20, 5)
	_check(e.hp == 65, "penetracao fura a defesa (dano cheio 20)")
	e.free()

	# Build melee: VIT da vida/defesa; STR/VIT/estrelas dao capacidade; AGI da esquiva.
	var m1 = AttributeStats.build(TowerData.TowerClass.WARRIOR, AttributeSet.make(20, 10, 40, 10, 10, 10), true, 1)
	var m3 = AttributeStats.build(TowerData.TowerClass.WARRIOR, AttributeSet.make(20, 10, 40, 10, 10, 10), true, 3)
	_check(m1.is_melee and m1.max_hp > 0, "build melee tem vida")
	_check(m1.defense > 0, "VIT da defesa ao melee")
	_check(m3.block_capacity > m1.block_capacity, "estrelas aumentam a capacidade de bloqueio")
	var agile = AttributeStats.build(TowerData.TowerClass.WARRIOR, AttributeSet.make(10, 90, 20, 10, 10, 10), true, 1)
	_check(agile.dodge > 0.1, "AGI alta da esquiva ao melee")
	var penet = AttributeStats.build(TowerData.TowerClass.ARCHER, AttributeSet.make(60, 10, 10, 10, 40, 10))
	_check(penet.penetration > 0, "STR/DEX dao penetracao")

func _test_ability_families() -> void:
	print("\nFamilias de habilidade (lentidao / DoT / empurrao / catalogo):")
	# Todos os 56 personagens tem habilidade.
	var faltando := 0
	for c in Roster.all():
		if c.ability == null:
			faltando += 1
	_check(faltando == 0, "todos os personagens tem habilidade definida")
	_check(Abilities.for_character("zeus").kind == AbilityData.Kind.CHAIN, "Zeus = raio em cadeia")
	_check(Abilities.for_character("boitata").kind == AbilityData.Kind.DOT_AOE, "Boitata = fogo (DoT)")

	# Efeitos de status no inimigo.
	var e = Enemy.new()
	e.max_hp = 100
	root.add_child(e)
	e.setup([Vector2(0, 0), Vector2(400, 0)], 1) # indo para o ponto da direita
	e.global_position = Vector2(100, 0)
	e.apply_slow(0.5, 3.0)
	_check(e.is_slowed() == true, "apply_slow deixa o inimigo lento")
	e.apply_dot(10.0, 3.0)
	_check(e.has_dot() == true, "apply_dot aplica veneno/fogo")
	var pos_before = e.global_position.x
	e.knockback(60.0)
	_check(e.global_position.x < pos_before, "knockback empurra o inimigo para tras")
	e.free()

	# CHAIN (Zeus): fere varios inimigos em cadeia.
	var tz = Tower.new(); tz.setup(Roster.by_id("zeus").tower_data_for_level(1))
	root.add_child(tz); tz.global_position = Vector2(0, 0)
	var c1 = Enemy.new(); c1.max_hp = 100; root.add_child(c1); c1.global_position = Vector2(50, 0)
	var c2 = Enemy.new(); c2.max_hp = 100; root.add_child(c2); c2.global_position = Vector2(130, 0)
	tz.use_ability()
	_check(c1.hp < 100 and c2.hp < 100, "CHAIN (Zeus) fere varios inimigos em cadeia")
	tz.free(); c1.free(); c2.free()

	# SUMMON: invoca um aliado melee temporario (habilidade montada direto).
	var dsum = TowerData.warrior()
	dsum.ability = AbilityData.make("ab_sum", "Invocar", AbilityData.Kind.SUMMON, 30.0, 180.0, 6.0, 8.0)
	var tsum = Tower.new(); tsum.setup(dsum)
	root.add_child(tsum); tsum.global_position = Vector2(0, 320)
	var before_allies = get_nodes_in_group("melee_allies").size()
	tsum.use_ability()
	_check(get_nodes_in_group("melee_allies").size() == before_allies + 1, "SUMMON invoca um aliado melee")
	tsum.free()
