class_name BlessingsScreen
extends CanvasLayer

## Bênçãos do Olimpo: melhorias PERMANENTES da conta compradas com Essência (a
## moeda que antes não tinha uso). Mesmo padrão visual de Heróis/Loja/Missões.
## Cada linha mostra a bênção, o efeito acumulado, o nível (pips) e o custo da
## próxima melhoria. Persiste o progresso e emite closed para voltar ao Hub.

signal closed

var _content: VBoxContainer
var _ess_lbl: Label


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.04, 0.03, 0.30)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	add_child(_label("BENCAOS DO OLIMPO", Vector2(96, 72), 30, Color(1.0, 0.9, 0.6), true))
	_ess_lbl = _label("", Vector2(900, 82), 20, Color(0.6, 0.95, 0.7))
	add_child(_ess_lbl)

	var panel := PanelContainer.new()
	panel.position = Vector2(92, 124)
	panel.custom_minimum_size = Vector2(1106, 512)
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
	_content.add_theme_constant_override("separation", 10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	var back := Button.new()
	back.position = Vector2(92, 644)
	back.custom_minimum_size = Vector2(180, 44)
	back.text = "Voltar"
	back.pressed.connect(func(): closed.emit())
	add_child(back)

	add_child(UiTheme.ornate_frame())
	_rebuild()


func _rebuild() -> void:
	_ess_lbl.text = "Essencia: %d" % Progression.meta_essence
	for c in _content.get_children():
		c.queue_free()
	var intro := _label("Melhorias PERMANENTES, valem em todas as partidas.", Vector2.ZERO, 15, Color(0.78, 0.74, 0.64))
	_content.add_child(intro)
	for b in Blessings.all():
		_content.add_child(_blessing_row(b))


func _blessing_row(b: Dictionary) -> PanelContainer:
	var id: String = b["id"]
	var lv: int = Progression.blessing_level(id)
	var maxed: bool = lv >= Blessings.MAX_LEVEL

	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_box())
	var m := MarginContainer.new()
	for s in ["left", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 10)
	m.add_theme_constant_override("margin_right", 26)
	row.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	m.add_child(hb)

	# Nome + efeito + pips (coluna que expande).
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	hb.add_child(col)
	var nm := Label.new()
	nm.text = b["name"]
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", b["color"])
	col.add_child(nm)
	var eff := Label.new()
	eff.text = ("Agora: " + Blessings.effect_text(b, lv)) if lv > 0 else "Efeito por nivel: " + Blessings.effect_text(b, 1)
	eff.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82))
	eff.add_theme_font_size_override("font_size", 15)
	col.add_child(eff)
	var pips := Label.new()
	pips.text = "Nivel  " + _pips(lv)
	pips.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
	pips.add_theme_font_size_override("font_size", 14)
	col.add_child(pips)

	# Custo + botão (lado direito).
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(200, 48)
	if maxed:
		buy.text = "MAXIMO"
		buy.disabled = true
	else:
		var c: int = Progression.blessing_cost(id)
		buy.text = "Melhorar\n%d essencia" % c
		buy.disabled = not Progression.can_buy_blessing(id)
		buy.pressed.connect(_on_buy.bind(id))
	var wrap := CenterContainer.new()
	wrap.add_child(buy)
	hb.add_child(wrap)
	return row


func _pips(lv: int) -> String:
	var s := ""
	for i in Blessings.MAX_LEVEL:
		s += "●" if i < lv else "○"
	return "%s  (%d/%d)" % [s, lv, Blessings.MAX_LEVEL]


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


func _on_buy(id: String) -> void:
	Progression.buy_blessing(id)
	Progression.save_game()
	_rebuild()
