class_name TitleScreen
extends CanvasLayer

## Tela inicial premium (estilo Kingdom Rush): splash do Olimpo, dois heróis guardando
## o menu, logo no banner ornamentado e botões em ouro/madeira com brilho. Emite um
## sinal por destino.

signal play_pressed
signal heroes_pressed
signal shop_pressed
signal quests_pressed
signal gacha_pressed
signal blessings_pressed

var _t: float = 0.0
var _glow: Panel = null   ## brilho pulsante atrás do botão JOGAR


func _ready() -> void:
	layer = 5
	# Fundo ilustrado (Olimpo) + véu com gradiente p/ os botões destacarem embaixo.
	var bg_tex := Art.map("menu_bg")
	if bg_tex != null:
		var tr := TextureRect.new()
		tr.texture = bg_tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(tr)
	else:
		var cr := ColorRect.new()
		cr.color = Color(0.08, 0.09, 0.13)
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(cr)
	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.04, 0.05, 0.09, 0.32)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	# Vinheta inferior (escurece a base p/ legibilidade dos botões/recursos).
	var vine := TextureRect.new()
	vine.set_anchors_preset(Control.PRESET_FULL_RECT)
	vine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vine.texture = _vgrad()
	vine.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(vine)

	# Heróis guardando o menu (arte premium nos cantos inferiores).
	_add_guardian("hercules", Vector2(96, 250), false)
	_add_guardian("zeus", Vector2(902, 250), true)

	# Banner ornamentado + emblema + logo.
	var banner_tex := Art.ui("ui_banner")
	if banner_tex != null:
		var bn := TextureRect.new()
		bn.texture = banner_tex
		bn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		bn.position = Vector2(340, 24)
		bn.size = Vector2(600, 210)
		bn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bn)
	var emblem_tex := Art.ui("ui_emblem")
	if emblem_tex != null:
		var em := TextureRect.new()
		em.texture = emblem_tex
		em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		em.position = Vector2(584, 2)
		em.size = Vector2(112, 112)
		em.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(em)

	var logo := Label.new()
	logo.position = Vector2(340, 90)
	logo.size = Vector2(600, 96)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo.text = "MITHOS TD"
	var tf := UiTheme.fancy_font()
	if tf != null:
		logo.add_theme_font_override("font", tf)
	logo.add_theme_font_size_override("font_size", 52)
	logo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	logo.add_theme_color_override("font_outline_color", Color(0.3, 0.14, 0.02))
	logo.add_theme_constant_override("outline_size", 7)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	logo.add_theme_constant_override("shadow_offset_y", 3)
	add_child(logo)

	var sub := _label("Mitologias em guerra", Vector2(0, 244), 1280, 20, Color(0.98, 0.92, 0.7), true)
	add_child(sub)

	# Brilho pulsante atrás do JOGAR.
	_glow = Panel.new()
	_glow.position = Vector2(470, 296)
	_glow.size = Vector2(340, 72)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(1.0, 0.85, 0.4, 0.0)
	gsb.set_corner_radius_all(18)
	gsb.shadow_color = Color(1.0, 0.82, 0.32, 0.55)
	gsb.shadow_size = 26
	_glow.add_theme_stylebox_override("panel", gsb)
	add_child(_glow)

	# Coluna de botões (centralizada).
	var col := VBoxContainer.new()
	col.position = Vector2(490, 300)
	col.custom_minimum_size = Vector2(300, 0)
	col.add_theme_constant_override("separation", 13)
	add_child(col)
	col.add_child(_btn("JOGAR", func(): play_pressed.emit(), true, 32, 300))
	col.add_child(_btn("HEROIS", func(): heroes_pressed.emit(), false, 24, 300))
	col.add_child(_btn("LOJA", func(): shop_pressed.emit(), false, 24, 300))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	row.add_child(_btn("MISSOES", func(): quests_pressed.emit(), false, 20, 144))
	row.add_child(_btn("ALTAR", func(): gacha_pressed.emit(), false, 20, 144))
	col.add_child(_btn("BENCAOS DO OLIMPO", func(): blessings_pressed.emit(), false, 20, 300))

	# Faixa de recursos no rodapé (placa de pergaminho).
	_add_resource_bar()
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _glow != null:
		var sb := _glow.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			var p: float = 0.5 + 0.5 * sin(_t * 2.4)
			sb.shadow_size = 18.0 + 16.0 * p
			sb.shadow_color = Color(1.0, 0.82, 0.32, 0.35 + 0.35 * p)


# --- Helpers ---
## Herói grande "guardando" o menu (arte premium, leve escurecido p/ não competir).
func _add_guardian(hero_id: String, pos: Vector2, flip: bool) -> void:
	var tex := Art.hero(hero_id)
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.position = pos
	tr.size = Vector2(282, 470)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = Color(0.92, 0.92, 0.96, 0.96)
	if flip:
		tr.flip_h = true
	add_child(tr)


## Botão em ouro (primário) ou madeira escura (secundário), com hover/pressed.
func _btn(text: String, cb: Callable, primary: bool, font_size: int, width: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(width, 60 if primary else 52)
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	var mk := func(top: Color, bot: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bot.lerp(top, 0.5)
		s.set_corner_radius_all(11)
		s.set_border_width_all(3)
		s.border_color = border
		s.set_content_margin_all(8)
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 6
		return s
	if primary:
		b.add_theme_stylebox_override("normal", mk.call(Color(0.97, 0.80, 0.34), Color(0.76, 0.54, 0.16), Color(1.0, 0.93, 0.62)))
		b.add_theme_stylebox_override("hover", mk.call(Color(1.0, 0.88, 0.46), Color(0.84, 0.62, 0.22), Color(1.0, 0.97, 0.74)))
		b.add_theme_stylebox_override("pressed", mk.call(Color(0.80, 0.62, 0.22), Color(0.6, 0.43, 0.13), Color(0.95, 0.86, 0.52)))
		b.add_theme_color_override("font_color", Color(0.22, 0.12, 0.02))
		b.add_theme_color_override("font_hover_color", Color(0.18, 0.10, 0.01))
		b.add_theme_color_override("font_pressed_color", Color(0.30, 0.20, 0.06))
	else:
		b.add_theme_stylebox_override("normal", mk.call(Color(0.30, 0.22, 0.14), Color(0.18, 0.13, 0.09), Color(0.92, 0.74, 0.36)))
		b.add_theme_stylebox_override("hover", mk.call(Color(0.40, 0.30, 0.18), Color(0.26, 0.19, 0.12), Color(1.0, 0.86, 0.46)))
		b.add_theme_stylebox_override("pressed", mk.call(Color(0.22, 0.16, 0.10), Color(0.14, 0.10, 0.07), Color(0.85, 0.68, 0.34)))
		b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.82))
		b.add_theme_color_override("font_pressed_color", Color(0.9, 0.82, 0.62))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02, 0.9))
	b.add_theme_constant_override("outline_size", 3)
	b.pressed.connect(cb)
	return b


func _add_resource_bar() -> void:
	var bar := Panel.new()
	bar.position = Vector2(290, 658)
	bar.size = Vector2(700, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.06, 0.86)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.66, 0.30)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 6
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	var res := _label("Ouro %d     Ambrosia %d     Estrelas %d/%d     Herois %d/%d" % [
		Progression.meta_gold, Progression.ambrosia, Progression.total_stars(),
		Progression.max_total_stars(), Progression.unlocked_ids().size(), Roster.count()],
		Vector2(290, 668), 700, 20, Color(1.0, 0.9, 0.5))
	add_child(res)


func _label(text: String, pos: Vector2, width: int, fsize: int, col: Color, fancy: bool = false) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(width, fsize + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 0.92))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fancy:
		var ff := UiTheme.fancy_font()
		if ff != null:
			l.add_theme_font_override("font", ff)
	return l


## Gradiente vertical transparente->escuro (vinheta inferior), gerado por código.
func _vgrad() -> ImageTexture:
	var img := Image.create(1, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var a: float = clampf((float(y) / 64.0 - 0.4) / 0.6, 0.0, 1.0) * 0.55
		img.set_pixel(0, y, Color(0.03, 0.03, 0.06, a))
	return ImageTexture.create_from_image(img)
