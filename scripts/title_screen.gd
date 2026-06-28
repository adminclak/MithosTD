class_name TitleScreen
extends CanvasLayer

## Tela inicial limpa (estilo Tangy/Kingdom Rush): arte HD de fundo, logo grande e
## poucos botões que abrem telas dedicadas. Emite um sinal por destino.

signal play_pressed
signal heroes_pressed
signal shop_pressed
signal quests_pressed
signal gacha_pressed


func _ready() -> void:
	layer = 5
	# Fundo ilustrado (HD) + véu para contraste.
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
	scrim.color = Color(0.05, 0.06, 0.10, 0.35)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)

	# Logo.
	var logo := Label.new()
	logo.position = Vector2(0, 70)
	logo.size = Vector2(1280, 120)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.text = "MITHOS TD"
	var tf := UiTheme.title_font()
	if tf != null:
		logo.add_theme_font_override("font", tf)
	logo.add_theme_font_size_override("font_size", 64)
	logo.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	logo.add_theme_constant_override("shadow_offset_x", 3)
	logo.add_theme_constant_override("shadow_offset_y", 5)
	add_child(logo)

	var sub := Label.new()
	sub.position = Vector2(0, 188)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "Mitologias em guerra"
	sub.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	add_child(sub)

	# Botões centrais (verticais).
	var col := VBoxContainer.new()
	col.position = Vector2(490, 300)
	col.custom_minimum_size = Vector2(300, 0)
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(_big_btn("JOGAR", func(): play_pressed.emit(), 30))
	col.add_child(_big_btn("HEROIS", func(): heroes_pressed.emit()))
	col.add_child(_big_btn("LOJA", func(): shop_pressed.emit()))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	row.add_child(_big_btn("MISSOES", func(): quests_pressed.emit(), 20, 144))
	row.add_child(_big_btn("ALTAR", func(): gacha_pressed.emit(), 20, 144))

	# Faixa de recursos no rodapé.
	var res := Label.new()
	res.position = Vector2(0, 672)
	res.size = Vector2(1280, 30)
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	res.text = "Ouro %d     Ambrosia %d     Fase liberada %d/%d     Herois %d/%d" % [
		Progression.meta_gold, Progression.ambrosia, Progression.highest_stage_unlocked,
		StageList.count(), Progression.unlocked_ids().size(), Roster.count()]
	add_child(res)


func _big_btn(text: String, cb: Callable, font_size: int = 24, width: int = 300) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(width, 56)
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(cb)
	return b
