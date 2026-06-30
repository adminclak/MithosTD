class_name CollectionScreen
extends CanvasLayer

## Bazar do Mercador (Loja + Coleção): um atendente grego atrás de um balcão
## apresenta as mercadorias em três prateleiras (abas): Relíquias & Armas,
## Recrutar Heróis e Equipar & Evoluir. Toda a lógica é a mesma de antes
## (Progression), só ganhou um rosto e tema. Emite closed para voltar ao Hub.

signal closed
signal section_selected(id: String)

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]
const STAR := "*"
const MERCHANT_NAME := "Filemon, o Mercador"

# Falas do atendente por aba (dão vida ao balcão).
const GREETINGS := [
	"Reliquias e armas dignas dos deuses, heroi! Escolha bem.",
	"Procurando companheiros de batalha? Tenho otimos recrutas.",
	"Traga seus herois — eu cuido do equipamento e da evolucao.",
]
const TAB_NAMES := ["Reliquias & Armas", "Recrutar Herois", "Equipar & Evoluir"]

var _tab: int = 0
var _content: VBoxContainer
var _bubble_lbl: Label
var _res_lbl: Label
var _tab_btns: Array = []

# Filtros da aba "Relíquias & Armas": slot (-1 = todas) e raridade (-1 = todas).
var _filter_slot: int = -1
var _filter_rarity: int = -1
var _filter_box: VBoxContainer
var _cat_btns: Array = []
var _rar_btns: Array = []


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.03, 0.02, 0.28)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_build_left()
	_build_right()
	_select_tab(0)
	NavBar.add_to(self, "loja", func(id): section_selected.emit(id), func(): closed.emit())


# ---------------------------------------------------------------------------
# BALCÃO + ATENDENTE (coluna esquerda)
# ---------------------------------------------------------------------------
func _build_left() -> void:
	# Balão de fala do mercador (acima da cabeça).
	var bubble := PanelContainer.new()
	bubble.position = Vector2(86, 74)
	bubble.custom_minimum_size = Vector2(290, 0)
	bubble.add_theme_stylebox_override("panel", _bubble_box())
	add_child(bubble)
	var bmar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		bmar.add_theme_constant_override("margin_" + s, 12)
	bubble.add_child(bmar)
	_bubble_lbl = Label.new()
	_bubble_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_lbl.custom_minimum_size = Vector2(266, 0)
	_bubble_lbl.add_theme_color_override("font_color", Color(0.20, 0.13, 0.06))
	_bubble_lbl.add_theme_font_size_override("font_size", 18)
	bmar.add_child(_bubble_lbl)
	# Rabicho do balão apontando para o mercador.
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(196, 156), Vector2(232, 156), Vector2(210, 186)])
	tail.color = Color(0.97, 0.93, 0.82)
	add_child(tail)

	# Sprite do atendente, em pé atrás do balcão.
	var merch := TextureRect.new()
	var mtex := Art.hero("merchant")
	merch.position = Vector2(90, 186)
	merch.custom_minimum_size = Vector2(300, 330)
	merch.size = Vector2(300, 330)
	merch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	merch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	merch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mtex != null:
		merch.texture = mtex
	add_child(merch)

	# Balcão de madeira (à frente do mercador, escondendo as pernas).
	var counter := Panel.new()
	counter.position = Vector2(82, 452)
	counter.size = Vector2(326, 200)
	counter.add_theme_stylebox_override("panel", _counter_box())
	add_child(counter)
	# Tampo claro do balcão (faixa de destaque no topo).
	var top := ColorRect.new()
	top.position = Vector2(82, 452)
	top.size = Vector2(326, 14)
	top.color = Color(0.66, 0.48, 0.28)
	add_child(top)

	# Placa do nome do mercador, no balcão.
	var name_lbl := Label.new()
	name_lbl.position = Vector2(90, 474)
	name_lbl.size = Vector2(310, 30)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	name_lbl.add_theme_font_size_override("font_size", 22)
	var ff := UiTheme.fancy_font()
	if ff != null:
		name_lbl.add_theme_font_override("font", ff)
	name_lbl.text = MERCHANT_NAME
	add_child(name_lbl)

	# Recursos (moedas) sobre o balcão.
	_res_lbl = Label.new()
	_res_lbl.position = Vector2(98, 512)
	_res_lbl.size = Vector2(300, 80)
	_res_lbl.add_theme_font_size_override("font_size", 19)
	add_child(_res_lbl)
	_refresh_resources()


func _refresh_resources() -> void:
	_res_lbl.text = "Ouro meta:  %d\nEssencia:  %d\nAmbrosia:  %d" % \
		[Progression.meta_gold, Progression.meta_essence, Progression.ambrosia]


# ---------------------------------------------------------------------------
# PRATELEIRAS / MERCADORIAS (coluna direita, com abas)
# ---------------------------------------------------------------------------
func _build_right() -> void:
	# Barra de abas (prateleiras do bazar).
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(430, 74)
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	for i in TAB_NAMES.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(242, 40)
		b.text = TAB_NAMES[i]
		b.pressed.connect(_select_tab.bind(i))
		tabs.add_child(b)
		_tab_btns.append(b)

	# Painel das mercadorias (pergaminho) + scroll.
	var panel := PanelContainer.new()
	panel.position = Vector2(430, 122)
	panel.custom_minimum_size = Vector2(768, 514)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.96))
	add_child(panel)
	var pmar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pmar.add_theme_constant_override("margin_" + s, 16)
	panel.add_child(pmar)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	pmar.add_child(outer)
	# Barra de filtros (categoria por ícone + raridade) — só visível na aba de itens.
	_filter_box = _build_filter_bar()
	outer.add_child(_filter_box)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)


func _select_tab(i: int) -> void:
	_tab = i
	_bubble_lbl.text = GREETINGS[i]
	for k in _tab_btns.size():
		(_tab_btns[k] as Button).disabled = (k == i) ## aba ativa fica "afundada"
	_filter_box.visible = (i == 0) ## filtros só fazem sentido na loja de itens
	_rebuild_content()


# --- Barra de filtros (categoria + raridade) ---
func _build_filter_bar() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	# Linha 1: categorias (slots) com ícones.
	var cat := HBoxContainer.new()
	cat.add_theme_constant_override("separation", 4)
	box.add_child(cat)
	_cat_btns = []
	cat.add_child(_cat_button("Todas", -1, null))
	for s in range(EquipmentData.SLOT_NAMES.size()):
		var icon: Texture2D = Art.item("slot_" + EquipmentData.SLOT_KEYS[s])
		cat.add_child(_cat_button(EquipmentData.SLOT_NAMES[s], s, icon))

	# Linha 2: raridades (coloridas).
	var rar := HBoxContainer.new()
	rar.add_theme_constant_override("separation", 4)
	box.add_child(rar)
	_rar_btns = []
	rar.add_child(_rar_button("Todas", -1))
	for r in EquipmentData.rarity_order():
		rar.add_child(_rar_button(EquipmentData.rarity_name(r), r))
	return box


func _cat_button(label: String, slot: int, icon: Texture2D) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.tooltip_text = label
	if icon != null:
		b.icon = icon
		b.expand_icon = true
		b.custom_minimum_size = Vector2(44, 40)
	else:
		b.text = label
		b.custom_minimum_size = Vector2(64, 40)
	b.button_pressed = (slot == _filter_slot)
	b.pressed.connect(func(): _filter_slot = slot; _sync_filter_buttons(); _rebuild_content())
	_cat_btns.append({"btn": b, "slot": slot})
	return b


func _rar_button(label: String, r: int) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.text = label
	b.custom_minimum_size = Vector2(88, 34)
	b.add_theme_font_size_override("font_size", 13)
	if r >= 0:
		b.add_theme_color_override("font_color", EquipmentData.rarity_color(r))
	b.button_pressed = (r == _filter_rarity)
	b.pressed.connect(func(): _filter_rarity = r; _sync_filter_buttons(); _rebuild_content())
	_rar_btns.append({"btn": b, "rar": r})
	return b


## Mantém só um botão "pressionado" por linha (comportamento de rádio).
func _sync_filter_buttons() -> void:
	for e in _cat_btns:
		(e["btn"] as Button).button_pressed = (int(e["slot"]) == _filter_slot)
	for e in _rar_btns:
		(e["btn"] as Button).button_pressed = (int(e["rar"]) == _filter_rarity)


func _rebuild_content() -> void:
	for c in _content.get_children():
		c.queue_free()
	match _tab:
		0: _fill_items()
		1: _fill_recruit()
		2: _fill_characters()


# --- Aba 0: Relíquias & Armas (loja de itens) ---
func _fill_items() -> void:
	var shown: Array = []
	for item in EquipmentList.all():
		if _filter_slot >= 0 and item.slot != _filter_slot:
			continue
		if _filter_rarity >= 0 and item.rarity != _filter_rarity:
			continue
		shown.append(item)

	var head := Label.new()
	head.text = "%d itens à venda (pagos em Ouro meta)" % shown.size()
	head.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	_content.add_child(head)
	if shown.is_empty():
		var none := Label.new()
		none.text = "Nada nesta categoria/raridade."
		none.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
		_content.add_child(none)
		return
	for item in shown:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _row_box())
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var m := MarginContainer.new()
		for s in ["left", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + s, 6)
		m.add_theme_constant_override("margin_right", 26) ## espaço p/ a barra de rolagem
		m.add_child(hb)
		row.add_child(m)

		var tex := Art.item(item.icon_id())
		if tex != null:
			var ic := TextureRect.new()
			ic.texture = tex
			ic.custom_minimum_size = Vector2(34, 34)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb.add_child(ic)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(360, 0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.clip_text = true
		lbl.text = "[%s] %s — %s" % [EquipmentData.slot_name(item.slot), item.display_name, item.effects_text()]
		lbl.add_theme_color_override("font_color", EquipmentData.rarity_color(item.rarity))
		hb.add_child(lbl)
		var buy := Button.new()
		buy.custom_minimum_size = Vector2(150, 34)
		if Progression.owns_item(item.id):
			buy.text = "Possui"
			buy.disabled = true
		else:
			var price := EquipmentList.price(item.rarity)
			buy.text = "Comprar %d" % price
			buy.disabled = Progression.meta_gold < price
			buy.pressed.connect(_on_buy.bind(item.id))
		hb.add_child(buy)
		_content.add_child(row)


# --- Aba 1: Recrutar Heróis ---
func _fill_recruit() -> void:
	var head := Label.new()
	head.text = "Recrutas disponíveis (pagos em Ambrosia: %d)" % Progression.ambrosia
	head.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	_content.add_child(head)
	var any := false
	for d in Roster.defs():
		var id: String = d[0]
		if Progression.is_unlocked(id):
			continue
		any = true
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _row_box())
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var m := MarginContainer.new()
		for s in ["left", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + s, 6)
		m.add_theme_constant_override("margin_right", 26) ## espaço p/ a barra de rolagem
		m.add_child(hb)
		row.add_child(m)

		var tex := Art.hero(id)
		if tex != null:
			var ic := TextureRect.new()
			ic.texture = tex
			ic.custom_minimum_size = Vector2(40, 40)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb.add_child(ic)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(340, 0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = "%s  (%s)" % [d[1], Roster.rarity_name(Roster.rarity_of(id))]
		hb.add_child(lbl)
		var buy := Button.new()
		buy.custom_minimum_size = Vector2(170, 34)
		var price := Progression.character_price(id)
		buy.text = "Recrutar %d" % price
		buy.disabled = Progression.ambrosia < price
		buy.pressed.connect(_on_buy_char.bind(id))
		hb.add_child(buy)
		_content.add_child(row)
	if not any:
		var done := Label.new()
		done.text = "Todos os herois ja foram recrutados, heroi!"
		done.add_theme_color_override("font_color", Color(0.7, 0.85, 0.6))
		_content.add_child(done)


# --- Aba 2: Equipar & Evoluir ---
func _fill_characters() -> void:
	for id in Progression.unlocked_ids():
		var ch := Roster.by_id(id)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _row_box())
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		var m := MarginContainer.new()
		for s in ["left", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + s, 8)
		m.add_theme_constant_override("margin_right", 26) ## espaço p/ a barra de rolagem
		m.add_child(v)
		panel.add_child(m)

		var name_lbl := Label.new()
		name_lbl.text = "%s  (%s)  Nv %d  %s  | Frag: %d" % [ch.display_name, \
			CLASS_NAMES[ch.tower_class], Progression.level_of(id), \
			STAR.repeat(Progression.stars_of(id)), Progression.fragments_of(id)]
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
		v.add_child(name_lbl)

		var slots := GridContainer.new()
		slots.columns = 4
		slots.add_theme_constant_override("h_separation", 6)
		slots.add_theme_constant_override("v_separation", 4)
		for s in range(EquipmentData.SLOT_NAMES.size()):
			slots.add_child(_slot_button(id, s, EquipmentData.slot_name(s)))
		v.add_child(slots)

		var evo := Button.new()
		evo.custom_minimum_size = Vector2(300, 32)
		var cost := Progression.evolve_cost(id)
		if cost.is_empty():
			evo.text = "Evolucao maxima"
			evo.disabled = true
		else:
			evo.text = "Evoluir (%d frag + %d ouro)" % [cost["frag"], cost["gold"]]
			evo.disabled = not Progression.can_evolve(id)
			evo.pressed.connect(_on_evolve.bind(id))
		v.add_child(evo)
		_content.add_child(panel)


func _slot_button(char_id: String, slot: int, slot_label: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(166, 30)
	var cur: String = Progression.equipped_ids(char_id).get(str(slot), "")
	var item := EquipmentList.by_id(cur) if cur != "" else null
	b.text = "%s: %s" % [slot_label, (item.display_name if item != null else "-")]
	if item != null:
		b.add_theme_color_override("font_color", EquipmentData.rarity_color(item.rarity))
		var tex := Art.item(item.icon_id())
		if tex != null:
			b.icon = tex
			b.expand_icon = true
	b.pressed.connect(_on_cycle_slot.bind(char_id, slot))
	return b


# ---------------------------------------------------------------------------
# Estilos (pergaminho / madeira / balão)
# ---------------------------------------------------------------------------
func _bubble_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.93, 0.82)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.45, 0.32, 0.18)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	return sb


func _counter_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.36, 0.24, 0.14)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.22, 0.14, 0.08)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	return sb


func _row_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.12, 0.09, 0.55)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.5, 0.4, 0.26, 0.6)
	return sb


# ---------------------------------------------------------------------------
# Ações (mesma lógica de Progression de antes)
# ---------------------------------------------------------------------------
func _on_buy_char(char_id: String) -> void:
	Progression.buy_character(char_id)
	Progression.save_game()
	_refresh_resources()
	_rebuild_content()


func _on_cycle_slot(char_id: String, slot: int) -> void:
	var cur: String = Progression.equipped_ids(char_id).get(str(slot), "")
	var options: Array = [""]
	for id in Progression.inventory:
		var item := EquipmentList.by_id(id)
		if item != null and item.slot == slot and (Progression.is_item_available(id) or id == cur):
			options.append(id)
	var idx: int = options.find(cur)
	var nxt: String = options[(idx + 1) % options.size()]
	if nxt == "":
		Progression.unequip(char_id, slot)
	else:
		Progression.equip(char_id, slot, nxt)
	Progression.save_game()
	_rebuild_content()


func _on_buy(item_id: String) -> void:
	Progression.buy_item(item_id)
	Progression.save_game()
	_refresh_resources()
	_rebuild_content()


func _on_evolve(char_id: String) -> void:
	Progression.evolve(char_id)
	Progression.save_game()
	_refresh_resources()
	_rebuild_content()
