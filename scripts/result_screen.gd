class_name ResultScreen
extends CanvasLayer

## Tela de resultado da fase: vitória/derrota, estrelas, recompensas, XP ganho por
## personagem, níveis subidos e heróis recém-desbloqueados. Usa o tema madeira/ouro
## (UiTheme) das demais telas para ficar coeso e bonito. Emite continue_pressed.

signal continue_pressed

const PANEL_W := 720.0

var _victory: bool = false
var _xp: int = 0
var _summary: Dictionary = {}
var _newly: Array = []
var _rewards: Dictionary = {}
var _stars: int = 0
var _star_info: Dictionary = {}
var _diff: int = 0
var _unlocked_next_diff: bool = false

var _star_lbls: Array = []   ## rótulos das estrelas conquistadas (p/ pulsar)
var _t: float = 0.0


func set_difficulty(diff: int, unlocked_next: bool) -> void:
	_diff = diff
	_unlocked_next_diff = unlocked_next


func setup(victory: bool, xp: int, summary: Dictionary, newly: Array, rewards: Dictionary = {}, stars: int = 0, star_info: Dictionary = {}) -> void:
	_victory = victory
	_xp = xp
	_summary = summary
	_newly = newly
	_rewards = rewards
	_stars = stars
	_star_info = star_info


func _ready() -> void:
	layer = 6
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.04, 0.03, 0.55)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	# Coluna ancorada abaixo da moldura ornamentada (topo ~70px) para o título nunca
	# ficar escondido atrás da borda de madeira; sobra é absorvida pelo espaçador.
	var mar := MarginContainer.new()
	mar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mar.add_theme_constant_override("margin_top", 64)
	mar.add_theme_constant_override("margin_bottom", 56)
	add_child(mar)
	var center := CenterContainer.new()
	mar.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(PANEL_W, 0)
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	# --- Título (VITÓRIA / DERROTA) com fonte fancy e brilho ---
	var tcol := Color(0.55, 0.95, 0.55) if _victory else Color(0.95, 0.5, 0.5)
	var title := _clabel("VITORIA!" if _victory else "DERROTA", 60, tcol, true)
	box.add_child(title)

	# --- Selo de dificuldade ---
	box.add_child(_clabel("Dificuldade: %s" % Difficulty.name_of(_diff), 20, Difficulty.color_of(_diff)))

	# --- Estrelas (só na vitória) ---
	if _victory:
		box.add_child(_stars_row())
		if _unlocked_next_diff:
			box.add_child(_clabel("Dificuldade %s liberada nesta fase!" % Difficulty.name_of(_diff + 1),
				18, Difficulty.color_of(_diff + 1)))
		if _star_info.get("improved", false):
			box.add_child(_clabel("Novo recorde de estrelas!  (+%d essencia)" %
				(int(_star_info.get("gained", 0)) * 3), 18, Color(0.6, 0.95, 0.7)))

	# --- Painel de pergaminho com recompensas + XP + níveis ---
	box.add_child(_detail_panel())

	# --- Heróis conquistados ---
	for id in _newly:
		box.add_child(_unlock_card(id))

	# --- Botão continuar (grande, dourado) ---
	box.add_child(_spacer(8))
	var cont := Button.new()
	cont.text = "Continuar" if _victory else "Voltar ao mapa"
	cont.custom_minimum_size = Vector2(280, 56)
	cont.add_theme_font_size_override("font_size", 24)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_cta(cont)
	cont.pressed.connect(func(): continue_pressed.emit())
	box.add_child(cont)

	add_child(UiTheme.ornate_frame())
	set_process(_victory and not _star_lbls.is_empty())


## Pulso suave de brilho nas estrelas conquistadas (toque comemorativo).
func _process(delta: float) -> void:
	_t += delta
	for i in _star_lbls.size():
		var l: Label = _star_lbls[i]
		if not is_instance_valid(l):
			continue
		var puls: float = 0.78 + 0.22 * (0.5 + 0.5 * sin(_t * 3.2 - i * 0.7))
		l.modulate = Color(1, 1, 1, 1) * puls + Color(0, 0, 0, 1 - puls)


# --- Painel central (pergaminho) com os números da partida ---
func _detail_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.13, 0.10, 0.07, 0.93)
	psb.set_corner_radius_all(10)
	psb.set_border_width_all(2)
	psb.border_color = Color(0.85, 0.66, 0.30)
	psb.shadow_color = Color(0, 0, 0, 0.45)
	psb.shadow_size = 8
	panel.add_theme_stylebox_override("panel", psb)
	panel.size_flags_horizontal = Control.SIZE_FILL
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 16)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)

	if not _rewards.is_empty():
		v.add_child(_clabel("Recompensas: +%d ouro · +%d essencia" %
			[_rewards.get("gold", 0), _rewards.get("essence", 0)], 20, UiTheme.GOLD))
		var item_id: String = _rewards.get("item_id", "")
		if item_id != "":
			var item := EquipmentList.by_id(item_id)
			if item != null:
				v.add_child(_clabel("ITEM encontrado: %s (%s)!" %
					[item.display_name, EquipmentData.rarity_name(item.rarity)], 18, Color(0.6, 0.9, 1.0)))

	v.add_child(_clabel("XP ao esquadrao: +%d cada" % _xp, 18, UiTheme.TEXT))

	# Linha por herói: nível atual e (se subiu) quantos níveis ganhou.
	for id in _summary.keys():
		var ch := Roster.by_id(id)
		var info: Dictionary = _summary[id]
		var name_txt: String = ch.display_name if ch != null else id
		var lvls: int = int(info["levels_gained"])
		if lvls > 0:
			v.add_child(_clabel("%s  ->  Nv %d  (+%d)" % [name_txt, info["new_level"], lvls],
				17, Color(1.0, 0.9, 0.45)))
		else:
			v.add_child(_clabel("%s  ->  Nv %d" % [name_txt, info["new_level"]], 16, Color(0.86, 0.83, 0.74)))
	return panel


## Rótulo centralizado (preenche a largura) com contorno escuro p/ legibilidade.
func _clabel(text: String, fsize: int, col: Color, fancy: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	if fancy:
		var ff := UiTheme.fancy_font()
		if ff != null:
			l.add_theme_font_override("font", ff)
	return l


## Botão de chamada-à-ação (dourado, em relevo) coeso com o tema madeira/ouro.
func _style_cta(b: Button) -> void:
	var mk := func(top: Color, bot: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = top
		s.set_corner_radius_all(10)
		s.set_border_width_all(3)
		s.border_color = border
		s.set_content_margin_all(8)
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 6
		# leve gradiente vertical p/ dar volume (claro em cima, escuro embaixo).
		s.bg_color = bot.lerp(top, 0.5)
		return s
	var normal: StyleBoxFlat = mk.call(Color(0.95, 0.78, 0.32), Color(0.74, 0.52, 0.16), Color(1.0, 0.92, 0.6))
	var hover: StyleBoxFlat = mk.call(Color(1.0, 0.86, 0.42), Color(0.82, 0.6, 0.2), Color(1.0, 0.96, 0.72))
	var pressed: StyleBoxFlat = mk.call(Color(0.78, 0.6, 0.2), Color(0.6, 0.42, 0.12), Color(0.95, 0.85, 0.5))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(0.20, 0.12, 0.02))
	b.add_theme_color_override("font_hover_color", Color(0.16, 0.09, 0.01))
	b.add_theme_color_override("font_pressed_color", Color(0.30, 0.20, 0.06))


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Fileira de 3 estrelas (preenchidas = conquistadas; ☆ = perdidas).
func _stars_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_FILL
	for i in 3:
		var won := i < _stars
		var l := Label.new()
		l.text = "★" if won else "☆"
		l.add_theme_font_size_override("font_size", 56 if won else 48)
		l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3) if won else Color(0.45, 0.4, 0.3))
		l.add_theme_color_override("font_outline_color", Color(0.25, 0.16, 0.03))
		l.add_theme_constant_override("outline_size", 5)
		row.add_child(l)
		if won:
			_star_lbls.append(l)
	return row


## Card de destaque do herói conquistado na campanha (retrato + nome + classe).
func _unlock_card(id: String) -> PanelContainer:
	const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]
	var ch := Roster.by_id(id)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.07, 0.96)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3)
	sb.border_color = Color(1.0, 0.82, 0.35)
	sb.shadow_color = Color(1.0, 0.8, 0.3, 0.35)
	sb.shadow_size = 10
	card.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 10)
	card.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(hb)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(84, 84)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex := Art.hero(id)
	if tex != null:
		art.texture = tex
	hb.add_child(art)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	hb.add_child(v)
	var tag := Label.new()
	tag.text = "★ NOVO HERÓI CONQUISTADO!"
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	v.add_child(tag)
	var nm := Label.new()
	nm.text = ch.display_name if ch != null else id
	nm.add_theme_font_size_override("font_size", 26)
	var ff := UiTheme.fancy_font()
	if ff != null:
		nm.add_theme_font_override("font", ff)
	v.add_child(nm)
	if ch != null:
		var sub := Label.new()
		var el := Elements.of_character(id)
		sub.text = "%s · %s · %s" % [ch.mythology, CLASS_NAMES[ch.tower_class], Elements.name_of(el)]
		sub.add_theme_font_size_override("font_size", 14)
		sub.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		v.add_child(sub)
	return card
