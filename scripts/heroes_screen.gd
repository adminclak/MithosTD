class_name HeroesScreen
extends CanvasLayer

## Tela de Heróis: 3 ABAS de equipe (Equipe 1/2/3), grade de retratos e ficha do
## herói (arte, atributos, elemento, habilidade, Poder Supremo, 8 slots). Clicar no
## herói = inspecionar; botão da ficha entra/sai da equipe; no rodapé, a equipe
## atual com um clique para remover. Mostra as sinergias ativas. Tudo salvo.

signal closed

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]

var _sel_id: String = ""
var _filter: String = "Todas"
var _root: Control


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg()) ## fundo de madeira (estilo Kingdom Rush)
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.22)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	if _sel_id == "":
		var sq := Progression.current_squad()
		var unlocked := Progression.unlocked_ids()
		_sel_id = sq[0] if not sq.is_empty() else (unlocked[0] if not unlocked.is_empty() else "")
	_rebuild()


func _team() -> int:
	return Progression.active_team


func _rebuild() -> void:
	for c in _root.get_children():
		c.queue_free()
	_root.add_child(_label("HEROIS", Vector2(24, 16), 30, Color(1.0, 0.86, 0.42)))
	_root.add_child(_label("Ouro %d   Ambrosia %d" % [Progression.meta_gold, Progression.ambrosia],
		Vector2(230, 26), 18, Color(1, 0.9, 0.5)))

	# Abas de equipe (1/2/3).
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(24, 54)
	tabs.add_theme_constant_override("separation", 8)
	_root.add_child(tabs)
	for i in 3:
		var tb := Button.new()
		tb.custom_minimum_size = Vector2(150, 36)
		var n: int = Progression.teams[i].size()
		tb.text = "Equipe %d (%d)" % [i + 1, n]
		if i == _team():
			tb.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
		tb.pressed.connect(func(idx = i): Progression.set_active_team(idx); _rebuild())
		tabs.add_child(tb)

	# Filtro de mitologia — só aparece se houver mais de uma mitologia liberada.
	var present := {}
	for id in Progression.unlocked_ids():
		var c := Roster.by_id(id)
		if c != null:
			present[c.mythology] = true
	if present.size() > 1:
		var fbar := HBoxContainer.new()
		fbar.position = Vector2(24, 96)
		fbar.add_theme_constant_override("separation", 4)
		_root.add_child(fbar)
		for myth in (["Todas"] + present.keys()):
			var fb := Button.new()
			fb.custom_minimum_size = Vector2(88, 24)
			fb.text = myth
			fb.add_theme_font_size_override("font_size", 13)
			fb.pressed.connect(func(m = myth): _filter = m; _rebuild())
			fbar.add_child(fb)

	_build_grid()
	if _sel_id != "":
		_build_detail()
	_build_footer()


func _build_grid() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 130)
	scroll.custom_minimum_size = Vector2(560, 458)
	scroll.size = Vector2(560, 458)
	_root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	var team: Array = Progression.teams[_team()]
	for id in Progression.unlocked_ids():
		var ch := Roster.by_id(id)
		if ch == null:
			continue
		if _filter != "Todas" and ch.mythology != _filter:
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 104)
		b.button_pressed = (id == _sel_id)
		var tex := Art.hero(id)
		if tex != null:
			b.icon = tex
			b.expand_icon = true
		b.text = "" if tex != null else ch.display_name
		var el := Elements.of_character(id)
		b.tooltip_text = "%s\n%s  [%s]%s" % [ch.display_name, CLASS_NAMES[ch.tower_class],
			Elements.name_of(el), ("  • NA EQUIPE" if team.has(id) else "")]
		if team.has(id):
			b.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		b.pressed.connect(func(i = id): _sel_id = i; _rebuild())
		grid.add_child(b)


func _build_detail() -> void:
	var ch := Roster.by_id(_sel_id)
	if ch == null:
		return
	var panel := PanelContainer.new()
	panel.position = Vector2(604, 130)
	panel.custom_minimum_size = Vector2(648, 458)
	panel.size = Vector2(648, 458)
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	v.add_child(top)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(170, 170)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var htex := Art.hero(_sel_id)
	if htex != null:
		art.texture = htex
	top.add_child(art)
	var info := VBoxContainer.new()
	top.add_child(info)
	var lvl := Progression.level_of(_sel_id)
	var el := Elements.of_character(_sel_id)
	info.add_child(_label(ch.display_name, Vector2.ZERO, 24, Color(1, 0.9, 0.5)))
	info.add_child(_label("%s  -  %s  -  Nv %d" % [ch.mythology, CLASS_NAMES[ch.tower_class], lvl], Vector2.ZERO, 15, Color.WHITE))
	info.add_child(_label("Elemento: %s" % Elements.name_of(el), Vector2.ZERO, 16, Elements.color_of(el)))
	var a: AttributeSet = ch.attributes_at(lvl)
	info.add_child(_label("FOR %d  AGI %d  VIT %d" % [a.strength, a.agility, a.vitality], Vector2.ZERO, 15, Color(0.85, 0.9, 1)))
	info.add_child(_label("INT %d  DES %d  SOR %d" % [a.intelligence, a.dexterity, a.luck], Vector2.ZERO, 15, Color(0.85, 0.9, 1)))
	if ch.ability != null:
		info.add_child(_label("Habilidade: " + ch.ability.display_name, Vector2.ZERO, 14, Color(0.7, 0.9, 1)))
	var ult := Ultimates.for_character(_sel_id)
	info.add_child(_label("Poder Supremo: " + ult.display_name, Vector2.ZERO, 14, ult.color))

	v.add_child(_label("Equipamento", Vector2.ZERO, 16, Color(1, 0.86, 0.42)))
	var slots := GridContainer.new()
	slots.columns = 4
	slots.add_theme_constant_override("h_separation", 6)
	slots.add_theme_constant_override("v_separation", 6)
	v.add_child(slots)
	for s in range(EquipmentData.SLOT_NAMES.size()):
		slots.add_child(_slot_button(s))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	v.add_child(actions)
	var team: Array = Progression.teams[_team()]
	var in_team := team.has(_sel_id)
	var sq := Button.new()
	sq.custom_minimum_size = Vector2(270, 42)
	if in_team:
		sq.text = "Remover da Equipe %d" % (_team() + 1)
	elif team.size() >= Progression.SQUAD_MAX:
		sq.text = "Equipe cheia (%d)" % Progression.SQUAD_MAX
		sq.disabled = true
	else:
		sq.text = "Adicionar a Equipe %d" % (_team() + 1)
	sq.pressed.connect(func(): Progression.toggle_in_team(_team(), _sel_id); _rebuild())
	actions.add_child(sq)
	var ub := Button.new()
	ub.custom_minimum_size = Vector2(280, 42)
	var is_ult: bool = Progression.team_ults[_team()] == _sel_id
	ub.text = "Poder Supremo: ATIVO" if is_ult else "Usar este Poder Supremo"
	ub.disabled = is_ult or not in_team
	ub.pressed.connect(func(): Progression.set_team_ult(_team(), _sel_id); _rebuild())
	actions.add_child(ub)

	# Campeão (1 por partida): o herói que anda no mapa.
	var cb := Button.new()
	cb.custom_minimum_size = Vector2(560, 40)
	var is_champ: bool = Progression.current_champion() == _sel_id
	cb.text = "♛ CAMPEAO (anda no mapa)" if is_champ else "Definir como Campeao"
	cb.disabled = is_champ or not in_team
	cb.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	cb.pressed.connect(func(): Progression.set_team_champion(_team(), _sel_id); _rebuild())
	v.add_child(cb)


func _slot_button(slot: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 28)
	var cur: String = Progression.equipped_ids(_sel_id).get(str(slot), "")
	var item := EquipmentList.by_id(cur) if cur != "" else null
	b.text = "%s: %s" % [EquipmentData.slot_name(slot), (item.display_name if item != null else "-")]
	b.add_theme_font_size_override("font_size", 12)
	if item != null:
		b.add_theme_color_override("font_color", EquipmentData.rarity_color(item.rarity))
		var tex := Art.item(item.icon_id())
		if tex != null:
			b.icon = tex
			b.expand_icon = true
	b.pressed.connect(_cycle_slot.bind(slot))
	return b


func _build_footer() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.45)
	bar.position = Vector2(0, 596)
	bar.size = Vector2(1280, 124)
	_root.add_child(bar)

	var team: Array = Progression.teams[_team()]
	_root.add_child(_label("EQUIPE %d (clique no card para remover):" % (_team() + 1),
		Vector2(24, 604), 16, Color(1, 0.9, 0.5)))
	var hb := HBoxContainer.new()
	hb.position = Vector2(24, 628)
	hb.add_theme_constant_override("separation", 6)
	_root.add_child(hb)
	for id in team:
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 64)
		var tex := Art.hero(id)
		if tex != null:
			b.icon = tex
			b.expand_icon = true
		var ch := Roster.by_id(id)
		b.tooltip_text = "Remover %s" % (ch.display_name if ch != null else id)
		b.pressed.connect(func(i = id): Progression.toggle_in_team(_team(), i); _rebuild())
		hb.add_child(b)
	for i in range(team.size(), Progression.SQUAD_MAX):
		var empty := _label("[ vazio ]", Vector2.ZERO, 14, Color(0.5, 0.5, 0.55))
		empty.custom_minimum_size = Vector2(64, 64)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(empty)

	# Sinergias ativas da equipe.
	var syn := Synergy.active(team)
	var syn_names: Array = []
	for s in syn:
		syn_names.append(s["name"])
	var syn_text := "Sinergias: " + (", ".join(syn_names) if not syn_names.is_empty() else "nenhuma (combine mitologia/classe/elemento)")
	_root.add_child(_label(syn_text, Vector2(560, 604), 14, Color(0.6, 1.0, 0.7)))

	var back := Button.new()
	back.position = Vector2(1110, 632)
	back.custom_minimum_size = Vector2(150, 48)
	back.text = "Voltar"
	back.pressed.connect(func(): closed.emit())
	_root.add_child(back)


func _cycle_slot(slot: int) -> void:
	var cur: String = Progression.equipped_ids(_sel_id).get(str(slot), "")
	var options: Array = [""]
	for id in Progression.inventory:
		var item := EquipmentList.by_id(id)
		if item != null and item.slot == slot and (Progression.is_item_available(id) or id == cur):
			options.append(id)
	var idx: int = options.find(cur)
	var nxt: String = options[(idx + 1) % options.size()]
	if nxt == "":
		Progression.unequip(_sel_id, slot)
	else:
		Progression.equip(_sel_id, slot, nxt)
	Progression.save_game()
	_rebuild()


func _label(text: String, pos: Vector2, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	# Contorno escuro = legível tanto na madeira quanto no pergaminho.
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	return l
