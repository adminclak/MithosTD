class_name TeamSelectScreen
extends CanvasLayer

## Seleção de equipe ANTES da batalha (pedido do usuário): depois de escolher a
## dificuldade, o jogador monta os 6 heróis que vão entrar na fase e escolhe o
## Poder Supremo. Mesmo padrão visual das outras telas. Emite started(squad, ult).

signal started(squad_ids: Array, ult_id: String, diff: int)
signal back

const MAX := 6

var _stage: StageData
var _diff: int = 0
var _lineup: Array = []   ## ids escolhidos (ordem)
var _ult: String = ""     ## id do Poder Supremo (um dos escolhidos)

var _grid: GridContainer
var _ult_lbl: Label
var _count_lbl: Label
var _start_btn: Button


func setup(stage: StageData, diff: int) -> void:
	_stage = stage
	_diff = diff


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.04, 0.03, 0.30)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	# Pré-preenche com a equipe ativa salva (jogador só confirma se gostar).
	for id in Progression.current_squad():
		if Progression.is_unlocked(id) and _lineup.size() < MAX:
			_lineup.append(id)
	_ult = Progression.current_ult()
	if not _lineup.has(_ult):
		_ult = _lineup[0] if not _lineup.is_empty() else ""

	add_child(_label("MONTAR EQUIPE", Vector2(96, 70), 30, Color(1.0, 0.9, 0.6), true))
	var diff_name := Difficulty.name_of(_diff)
	var sub := _label("%s  —  %s     ·     toque num heroi para adicionar/remover" %
		[_stage.display_name if _stage != null else "", diff_name],
		Vector2(98, 112), 18, Difficulty.color_of(_diff))
	add_child(sub)

	var panel := PanelContainer.new()
	panel.position = Vector2(92, 146)
	panel.custom_minimum_size = Vector2(1096, 410)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.96))
	add_child(panel)
	var pmar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pmar.add_theme_constant_override("margin_" + s, 16)
	panel.add_child(pmar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pmar.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	_count_lbl = _label("", Vector2(96, 566), 18, Color(0.95, 0.92, 0.82))
	add_child(_count_lbl)
	_ult_lbl = _label("", Vector2(300, 566), 18, Color(0.7, 0.95, 1.0))
	add_child(_ult_lbl)
	var ult_btn := Button.new()
	ult_btn.position = Vector2(820, 560)
	ult_btn.custom_minimum_size = Vector2(220, 40)
	ult_btn.text = "Trocar Poder Supremo"
	ult_btn.pressed.connect(_cycle_ult)
	add_child(ult_btn)

	var back_btn := Button.new()
	back_btn.position = Vector2(96, 648)
	back_btn.custom_minimum_size = Vector2(170, 46)
	back_btn.text = "Voltar"
	back_btn.pressed.connect(func(): back.emit())
	add_child(back_btn)

	_start_btn = Button.new()
	_start_btn.position = Vector2(1000, 648)
	_start_btn.custom_minimum_size = Vector2(190, 46)
	_start_btn.text = "INICIAR"
	_start_btn.add_theme_font_size_override("font_size", 22)
	_start_btn.pressed.connect(_on_start)
	add_child(_start_btn)

	add_child(UiTheme.ornate_frame())
	_rebuild()


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for id in Progression.unlocked_ids():
		_grid.add_child(_hero_card(id))
	var n := _lineup.size()
	_count_lbl.text = "Equipe: %d/%d" % [n, MAX]
	var uch := Roster.by_id(_ult)
	_ult_lbl.text = "Poder Supremo: %s" % (uch.display_name if uch != null else "—")
	_start_btn.disabled = _lineup.is_empty()


const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]


func _hero_card(id: String) -> Control:
	var ch := Roster.by_id(id)
	var idx: int = _lineup.find(id)
	var chosen := idx >= 0

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(166, 168)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.12, 0.09, 0.6)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(3 if chosen else 1)
	sb.border_color = Color(1.0, 0.85, 0.35) if chosen else Color(0.5, 0.4, 0.26, 0.7)
	card.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(0, 96)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex := Art.hero(id)
	if tex != null:
		art.texture = tex
	v.add_child(art)

	var nm := Label.new()
	nm.text = (("%d. " % (idx + 1)) if chosen else "") + (ch.display_name if ch != null else id)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 14)
	nm.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6) if chosen else Color(0.9, 0.88, 0.82))
	v.add_child(nm)

	if ch != null:
		var el := Elements.of_character(id)
		var info := Label.new()
		info.text = "%s · %s" % [CLASS_NAMES[ch.tower_class], Elements.name_of(el)]
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 11)
		info.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
		v.add_child(info)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(_toggle.bind(id))
	card.add_child(btn)
	return card


func _toggle(id: String) -> void:
	if _lineup.has(id):
		_lineup.erase(id)
		if _ult == id:
			_ult = _lineup[0] if not _lineup.is_empty() else ""
	elif _lineup.size() < MAX:
		_lineup.append(id)
		if _ult == "":
			_ult = id
	_rebuild()


func _cycle_ult() -> void:
	if _lineup.is_empty():
		return
	var i: int = _lineup.find(_ult)
	_ult = _lineup[(i + 1) % _lineup.size()]
	_rebuild()


func _on_start() -> void:
	if _lineup.is_empty():
		return
	# Persiste a escolha na equipe ativa (lembra na próxima vez) e inicia.
	Progression.set_squad(_lineup, _ult)
	started.emit(_lineup.duplicate(), _ult, _diff)


func _label(text: String, pos: Vector2, fsize: int, col: Color, fancy: bool = false) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	if fancy:
		var ff := UiTheme.fancy_font()
		if ff != null:
			l.add_theme_font_override("font", ff)
	return l
