class_name BestiaryScreen
extends CanvasLayer

## Bestiário: grade de inimigos. Os DESCOBERTOS (Progression.discovered_enemies)
## mostram arte + stats; os não vistos ficam como silhueta "???". Usa a NavBar padrão.

signal back_pressed
signal section_selected(id: String)


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.04, 0.03, 0.30)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	add_child(_title("BESTIARIO", Vector2(96, 30), 34))
	var enemies := GreekBestiary.all()
	var known := 0
	for e in enemies:
		if _seen(e.id):
			known += 1
	add_child(_title("%d / %d descobertos" % [known, enemies.size()], Vector2(98, 78), 18, Color(0.85, 0.82, 0.7)))

	var panel := PanelContainer.new()
	panel.position = Vector2(60, 116)
	panel.custom_minimum_size = Vector2(1160, 480)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.96))
	add_child(panel)
	var mar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		mar.add_theme_constant_override("margin_" + s, 16)
	panel.add_child(mar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mar.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for e in enemies:
		grid.add_child(_card(e))

	# Voltar ao menu (topo-direita) + barra de navegação padrão embaixo.
	var back := Button.new()
	back.position = Vector2(1084, 30)
	back.custom_minimum_size = Vector2(150, 44)
	back.text = "Menu"
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)

	var nav := NavBar.new()
	nav.setup(NavBar.MAIN_TABS, "bestiario")
	add_child(nav)
	nav.selected.connect(func(id): section_selected.emit(id))


func _seen(enemy_id: String) -> bool:
	return Progression.is_enemy_discovered(enemy_id)


func _card(e: EnemyData) -> PanelContainer:
	var seen := _seen(e.id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(272, 132)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.07, 0.95) if seen else Color(0.09, 0.08, 0.07, 0.9)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.66, 0.30) if seen else Color(0.35, 0.32, 0.28)
	card.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 8)
	card.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	m.add_child(hb)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(96, 96)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex := Art.enemy(e.id)
	if tex != null:
		art.texture = tex
		art.modulate = Color.WHITE if seen else Color(0, 0, 0, 0.85) # silhueta
	hb.add_child(art)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(v)
	var nm := Label.new()
	nm.text = e.display_name if seen else "???"
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7) if seen else Color(0.6, 0.58, 0.52))
	var ff := UiTheme.fancy_font()
	if ff != null:
		nm.add_theme_font_override("font", ff)
	v.add_child(nm)
	if seen:
		var el := Label.new()
		el.text = Elements.name_of(e.element) if e.element >= 0 else "Neutro"
		el.add_theme_font_size_override("font_size", 14)
		el.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		v.add_child(el)
		var st := Label.new()
		st.text = "Vida %d   Vel %d   Def %d" % [e.max_hp, int(e.speed), e.defense]
		st.add_theme_font_size_override("font_size", 13)
		st.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
		v.add_child(st)
	else:
		var hint := Label.new()
		hint.text = "Ainda nao descoberto"
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.52))
		v.add_child(hint)
	return card


func _title(text: String, pos: Vector2, fsize: int, col: Color = Color(1.0, 0.9, 0.6)) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	var ff := UiTheme.fancy_font()
	if ff != null:
		l.add_theme_font_override("font", ff)
	return l
