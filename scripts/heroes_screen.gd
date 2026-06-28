class_name HeroesScreen
extends CanvasLayer

## Tela de Heróis: grade de retratos + ficha do herói selecionado (arte grande,
## atributos, habilidade, Poder Supremo, 8 slots de equipamento) e montagem do
## esquadrão (salvo). Reconstrói a cada ação e persiste no Progression.

signal closed

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]

var _sel_id: String = ""
var _filter: String = "Todas"
var _root: Control


func _ready() -> void:
	layer = 5
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	if _sel_id == "":
		var unlocked := Progression.unlocked_ids()
		_sel_id = Progression.squad[0] if not Progression.squad.is_empty() else \
			(unlocked[0] if not unlocked.is_empty() else "")
	_rebuild()


func _rebuild() -> void:
	for c in _root.get_children():
		c.queue_free()

	var title := _label("HEROIS", Vector2(24, 18), 32, Color(1.0, 0.86, 0.42))
	_root.add_child(title)
	var res := _label("Ouro %d   Ambrosia %d   Esquadrao %d/%d" % [Progression.meta_gold,
		Progression.ambrosia, Progression.squad.size(), Progression.SQUAD_MAX],
		Vector2(250, 30), 18, Color(1, 0.9, 0.5))
	_root.add_child(res)

	# Filtro de mitologia.
	var fbar := HBoxContainer.new()
	fbar.position = Vector2(24, 62)
	fbar.add_theme_constant_override("separation", 4)
	_root.add_child(fbar)
	for myth in (["Todas"] + Roster.MYTHOLOGIES):
		var fb := Button.new()
		fb.custom_minimum_size = Vector2(92, 26)
		fb.text = myth
		fb.add_theme_font_size_override("font_size", 14)
		fb.pressed.connect(func(m = myth): _filter = m; _rebuild())
		fbar.add_child(fb)

	_build_grid()
	if _sel_id != "":
		_build_detail()
	_build_footer()


func _build_grid() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 100)
	scroll.custom_minimum_size = Vector2(560, 540)
	scroll.size = Vector2(560, 540)
	_root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	for id in Progression.unlocked_ids():
		var ch := Roster.by_id(id)
		if ch == null:
			continue
		if _filter != "Todas" and ch.mythology != _filter:
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 104)
		b.toggle_mode = true
		b.button_pressed = (id == _sel_id)
		var tex := Art.hero(id)
		if tex != null:
			b.icon = tex
			b.expand_icon = true
		b.text = "" if tex != null else ch.display_name
		var in_squad := Progression.squad.has(id)
		b.tooltip_text = ch.display_name + ("  [no esquadrao]" if in_squad else "")
		if in_squad:
			b.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		b.pressed.connect(func(i = id): _sel_id = i; _rebuild())
		grid.add_child(b)


func _build_detail() -> void:
	var ch := Roster.by_id(_sel_id)
	if ch == null:
		return
	var panel := PanelContainer.new()
	panel.position = Vector2(604, 100)
	panel.custom_minimum_size = Vector2(648, 500)
	panel.size = Vector2(648, 500)
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	v.add_child(top)
	# Arte grande.
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(180, 180)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var htex := Art.hero(_sel_id)
	if htex != null:
		art.texture = htex
	top.add_child(art)
	# Identidade + atributos.
	var info := VBoxContainer.new()
	top.add_child(info)
	var lvl := Progression.level_of(_sel_id)
	info.add_child(_label("%s" % ch.display_name, Vector2.ZERO, 26, Color(1, 0.9, 0.5)))
	info.add_child(_label("%s  -  %s  -  Nv %d  %s" % [ch.mythology, CLASS_NAMES[ch.tower_class],
		lvl, "*".repeat(Progression.stars_of(_sel_id))], Vector2.ZERO, 16, Color.WHITE))
	var a: AttributeSet = ch.attributes_at(lvl)
	info.add_child(_label("FOR %d   AGI %d   VIT %d" % [a.strength, a.agility, a.vitality], Vector2.ZERO, 16, Color(0.85, 0.9, 1)))
	info.add_child(_label("INT %d   DES %d   SOR %d" % [a.intelligence, a.dexterity, a.luck], Vector2.ZERO, 16, Color(0.85, 0.9, 1)))
	if ch.ability != null:
		info.add_child(_label("Habilidade: " + ch.ability.display_name, Vector2.ZERO, 15, Color(0.7, 0.9, 1)))
	var ult := Ultimates.for_character(_sel_id)
	info.add_child(_label("Poder Supremo: " + ult.display_name, Vector2.ZERO, 15, ult.color))

	# 8 slots de equipamento.
	v.add_child(_label("Equipamento", Vector2.ZERO, 18, Color(1, 0.86, 0.42)))
	var slots := GridContainer.new()
	slots.columns = 4
	slots.add_theme_constant_override("h_separation", 6)
	slots.add_theme_constant_override("v_separation", 6)
	v.add_child(slots)
	for s in range(EquipmentData.SLOT_NAMES.size()):
		slots.add_child(_slot_button(s))

	# Ações: esquadrão + Poder Supremo.
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	v.add_child(actions)
	var in_squad := Progression.squad.has(_sel_id)
	var sq := Button.new()
	sq.custom_minimum_size = Vector2(280, 44)
	if in_squad:
		sq.text = "Remover do esquadrao"
	elif Progression.squad.size() >= Progression.SQUAD_MAX:
		sq.text = "Esquadrao cheio (%d)" % Progression.SQUAD_MAX
		sq.disabled = true
	else:
		sq.text = "Adicionar ao esquadrao"
	sq.pressed.connect(_toggle_squad)
	actions.add_child(sq)
	var ub := Button.new()
	ub.custom_minimum_size = Vector2(300, 44)
	var is_ult := Progression.squad_ult == _sel_id
	ub.text = "Poder Supremo: ATIVO" if is_ult else "Usar este Poder Supremo"
	ub.disabled = is_ult
	ub.pressed.connect(_set_ult)
	actions.add_child(ub)


func _slot_button(slot: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 30)
	var cur: String = Progression.equipped_ids(_sel_id).get(str(slot), "")
	var item := EquipmentList.by_id(cur) if cur != "" else null
	b.text = "%s: %s" % [EquipmentData.slot_name(slot), (item.display_name if item != null else "-")]
	b.add_theme_font_size_override("font_size", 13)
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
	bar.color = Color(0, 0, 0, 0.4)
	bar.position = Vector2(0, 648)
	bar.size = Vector2(1280, 72)
	_root.add_child(bar)
	var hb := HBoxContainer.new()
	hb.position = Vector2(200, 656)
	hb.add_theme_constant_override("separation", 6)
	_root.add_child(hb)
	for id in Progression.squad:
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(56, 56)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex := Art.hero(id)
		if tex != null:
			tr.texture = tex
		hb.add_child(tr)
	_root.add_child(_label("MEU ESQUADRAO:", Vector2(24, 672), 16, Color(1, 0.9, 0.5)))
	var back := Button.new()
	back.position = Vector2(1100, 660)
	back.custom_minimum_size = Vector2(150, 48)
	back.text = "Voltar"
	back.pressed.connect(func(): closed.emit())
	_root.add_child(back)


# --- Ações ---
func _toggle_squad() -> void:
	var sq: Array = Progression.squad.duplicate()
	if sq.has(_sel_id):
		sq.erase(_sel_id)
	elif sq.size() < Progression.SQUAD_MAX:
		sq.append(_sel_id)
	Progression.set_squad(sq, Progression.squad_ult)
	_rebuild()


func _set_ult() -> void:
	var sq: Array = Progression.squad.duplicate()
	if not sq.has(_sel_id) and sq.size() < Progression.SQUAD_MAX:
		sq.append(_sel_id)
	Progression.set_squad(sq, _sel_id)
	_rebuild()


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
	return l
