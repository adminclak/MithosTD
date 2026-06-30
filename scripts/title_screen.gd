class_name TitleScreen
extends CanvasLayer

## Menu principal (estilo Kingdom Rush / mobile): fundo cartoon do Olimpo, logo
## dedicado, dois heróis guardando, botão JOGAR em destaque e a NavBar padrão embaixo
## (Heróis, Equipar, Bestiário, Loja, Missões, Altar, Bênçãos). Emite play_pressed e
## section_selected(id) — o main roteia a seção.

signal play_pressed
signal section_selected(id: String)

var _t: float = 0.0
var _glow: Panel = null


func _ready() -> void:
	layer = 5
	# Fundo cartoon (combina com personagens) + véu + vinheta inferior.
	var bg_tex := Art.map("menu_bg")
	if bg_tex != null:
		var tr := TextureRect.new()
		tr.texture = bg_tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
	else:
		var cr := ColorRect.new()
		cr.color = Color(0.08, 0.09, 0.13)
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(cr)
	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.04, 0.05, 0.09, 0.22)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	# Heróis guardando as laterais (mesmo estilo cartoon do fundo agora).
	_add_guardian("hercules", Vector2(70, 232), false)
	_add_guardian("zeus", Vector2(926, 232), true)

	# Logo dedicado (arte única "MITHOS TD"), centralizado no topo.
	var logo_tex := Art.ui("logo_mithos")
	if logo_tex != null:
		var lg := TextureRect.new()
		lg.texture = logo_tex
		lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lg.position = Vector2(390, 2)
		lg.size = Vector2(500, 270)
		lg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lg)
	else:
		add_child(_label("MITHOS TD", Vector2(0, 60), 1280, 52, Color(1.0, 0.9, 0.4), true))
	add_child(_label("Mitologias em guerra", Vector2(0, 256), 1280, 20, Color(0.98, 0.92, 0.7), true))

	# Brilho pulsante atrás do JOGAR.
	_glow = Panel.new()
	_glow.position = Vector2(450, 330)
	_glow.size = Vector2(380, 78)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(1.0, 0.85, 0.4, 0.0)
	gsb.set_corner_radius_all(18)
	gsb.shadow_color = Color(1.0, 0.82, 0.32, 0.5)
	gsb.shadow_size = 24
	_glow.add_theme_stylebox_override("panel", gsb)
	add_child(_glow)

	# JOGAR (grande, dourado).
	var play := _gold_btn("JOGAR", 36)
	play.position = Vector2(460, 336)
	play.custom_minimum_size = Vector2(360, 70)
	play.size = Vector2(360, 70)
	play.pressed.connect(func(): play_pressed.emit())
	add_child(play)

	# Recursos (placa compacta no topo-direita).
	_add_resource_chip()

	# Barra de navegação padrão (seções) embaixo.
	var nav := NavBar.new()
	nav.setup(NavBar.MAIN_TABS, "")
	add_child(nav)
	nav.selected.connect(func(id): section_selected.emit(id))
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _glow != null:
		var sb := _glow.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			var p: float = 0.5 + 0.5 * sin(_t * 2.4)
			sb.shadow_size = 16.0 + 16.0 * p
			sb.shadow_color = Color(1.0, 0.82, 0.32, 0.32 + 0.34 * p)


func _add_guardian(hero_id: String, pos: Vector2, flip: bool) -> void:
	var tex := Art.hero(hero_id)
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.position = pos
	tr.size = Vector2(284, 396)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if flip:
		tr.flip_h = true
	add_child(tr)


func _gold_btn(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	var mk := func(top: Color, bot: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bot.lerp(top, 0.5)
		s.set_corner_radius_all(12)
		s.set_border_width_all(3)
		s.border_color = border
		s.set_content_margin_all(8)
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 6
		return s
	b.add_theme_stylebox_override("normal", mk.call(Color(0.97, 0.80, 0.34), Color(0.76, 0.54, 0.16), Color(1.0, 0.93, 0.62)))
	b.add_theme_stylebox_override("hover", mk.call(Color(1.0, 0.88, 0.46), Color(0.84, 0.62, 0.22), Color(1.0, 0.97, 0.74)))
	b.add_theme_stylebox_override("pressed", mk.call(Color(0.80, 0.62, 0.22), Color(0.6, 0.43, 0.13), Color(0.95, 0.86, 0.52)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(0.22, 0.12, 0.02))
	b.add_theme_color_override("font_hover_color", Color(0.18, 0.10, 0.01))
	b.add_theme_color_override("font_outline_color", Color(1.0, 0.95, 0.7, 0.5))
	b.add_theme_constant_override("outline_size", 2)
	return b


func _add_resource_chip() -> void:
	var chip := Panel.new()
	chip.position = Vector2(946, 12)
	chip.size = Vector2(322, 40)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.06, 0.88)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.66, 0.30)
	chip.add_theme_stylebox_override("panel", sb)
	add_child(chip)
	add_child(_label("Ouro %d   Ambrosia %d   %d/%d ★" % [
		Progression.meta_gold, Progression.ambrosia,
		Progression.total_stars(), Progression.max_total_stars()],
		Vector2(946, 20), 322, 18, Color(1.0, 0.9, 0.5)))


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
