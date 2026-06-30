class_name QuestsScreen
extends CanvasLayer

## Tela de Missões (mesmo padrão visual de Heróis/Loja): fundo de madeira, moldura
## ornamentada, título dourado e abas (Campanha / Diárias) num painel de pergaminho.
## Cada missão é uma linha com descrição, barra de progresso, recompensa e o botão
## de coletar. Persiste o progresso e emite closed para voltar ao Hub.

signal closed
signal section_selected(id: String)

const TAB_NAMES := ["Campanha", "Diarias"]

var _tab: int = 0
var _content: VBoxContainer
var _amb_lbl: Label
var _tab_btns: Array = []


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.04, 0.03, 0.30)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	add_child(_label("MISSOES", Vector2(96, 72), 30, Color(1.0, 0.9, 0.6), true))
	_amb_lbl = _label("", Vector2(1006, 82), 20, Color(1.0, 0.82, 0.4))
	add_child(_amb_lbl)

	# Abas (Campanha / Diárias).
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(430, 74)
	tabs.add_theme_constant_override("separation", 10)
	add_child(tabs)
	for i in TAB_NAMES.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(280, 42)
		b.text = TAB_NAMES[i]
		b.pressed.connect(_select_tab.bind(i))
		tabs.add_child(b)
		_tab_btns.append(b)

	# Painel de pergaminho com a lista de missões.
	var panel := PanelContainer.new()
	panel.position = Vector2(92, 130)
	panel.custom_minimum_size = Vector2(1106, 506)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.96))
	add_child(panel)
	var pmar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pmar.add_theme_constant_override("margin_" + s, 18)
	panel.add_child(pmar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pmar.add_child(scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	NavBar.add_to(self, "missoes", func(id): section_selected.emit(id), func(): closed.emit())
	_refresh_amb()
	_select_tab(0)


func _refresh_amb() -> void:
	_amb_lbl.text = "Ambrosia: %d" % Progression.ambrosia


func _select_tab(i: int) -> void:
	_tab = i
	for k in _tab_btns.size():
		(_tab_btns[k] as Button).disabled = (k == i)
	_rebuild_content()


func _rebuild_content() -> void:
	for c in _content.get_children():
		c.queue_free()
	var daily := _tab == 1
	var any := false
	for q in Quests.all():
		if q.get("daily", false) != daily:
			continue
		any = true
		_content.add_child(_quest_row(q))
	if not any:
		_content.add_child(_label("Nenhuma missao por aqui.", Vector2.ZERO, 18, Color(0.7, 0.7, 0.72)))


func _quest_row(q: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_box())
	var m := MarginContainer.new()
	for s in ["left", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 8)
	m.add_theme_constant_override("margin_right", 26) ## espaço p/ a barra de rolagem
	row.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	m.add_child(hb)

	var prog: int = Progression.quest_progress(q)
	var target: int = q["target"]

	# Descrição + barra de progresso.
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	hb.add_child(col)
	var desc := Label.new()
	desc.text = q["desc"]
	desc.add_theme_color_override("font_color", Color(1.0, 0.94, 0.8))
	desc.add_theme_font_size_override("font_size", 18)
	col.add_child(desc)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = max(1, target)
	bar.value = min(prog, target)
	bar.show_percentage = false
	col.add_child(bar)
	var pl := Label.new()
	pl.text = "%d / %d" % [min(prog, target), target]
	pl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.62))
	pl.add_theme_font_size_override("font_size", 13)
	col.add_child(pl)

	# Recompensa.
	var rew := Label.new()
	rew.custom_minimum_size = Vector2(150, 0)
	rew.text = "+%d Ambrosia" % q["ambrosia"]
	rew.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	rew.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(rew)

	# Botão de coletar.
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 40)
	if Progression.quest_claimed(q):
		btn.text = "Coletado"
		btn.disabled = true
	elif Progression.quest_claimable(q):
		btn.text = "Coletar"
		btn.pressed.connect(_on_claim.bind(q["id"]))
	else:
		btn.text = "Em progresso"
		btn.disabled = true
	var bwrap := CenterContainer.new()
	bwrap.add_child(btn)
	hb.add_child(bwrap)
	return row


func _row_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.12, 0.09, 0.55)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.5, 0.4, 0.26, 0.6)
	return sb


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


func _on_claim(qid: String) -> void:
	Progression.claim_quest(qid)
	Progression.save_game()
	_refresh_amb()
	_rebuild_content()
