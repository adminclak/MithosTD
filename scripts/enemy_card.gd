class_name EnemyCard
extends CanvasLayer

## Card "NOVO INIMIGO!" (estilo Kingdom Rush): quando um tipo de inimigo aparece
## pela 1ª vez na partida, um cartão desliza da direita com a arte, o nome, as
## características (elemento/traços) e os stats. Segura alguns segundos e recolhe.
## Vários novos tipos na mesma onda entram numa fila e aparecem em sequência.

const W := 330.0
const H := 138.0
const MARGIN := 22.0
const Y := 150.0
const SLIDE := 0.45
const HOLD := 3.2

var _panel: PanelContainer
var _art: TextureRect
var _art_fallback: ColorRect
var _name_lbl: Label
var _desc_lbl: Label
var _stats_lbl: Label
var _t: float = 0.0
var _active: bool = false
var _queue: Array = []
var _x_off: float
var _x_on: float


func _ready() -> void:
	layer = 9
	_x_off = 1280.0 + 10.0
	_x_on = 1280.0 - W - MARGIN

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(W, H)
	_panel.size = Vector2(W, H)
	_panel.position = Vector2(_x_off, Y)
	_panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.95))
	_panel.visible = false
	add_child(_panel)

	var margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 12)
	_panel.add_child(margin)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	margin.add_child(hb)

	# Arte do inimigo (com um quadro escuro de fundo).
	var art_box := PanelContainer.new()
	art_box.custom_minimum_size = Vector2(92, 92)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.05, 0.6)
	sb.set_corner_radius_all(6)
	art_box.add_theme_stylebox_override("panel", sb)
	hb.add_child(art_box)
	_art_fallback = ColorRect.new()
	_art_fallback.custom_minimum_size = Vector2(92, 92)
	art_box.add_child(_art_fallback)
	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(92, 92)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_box.add_child(_art)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)

	var new_lbl := Label.new()
	new_lbl.text = "NOVO INIMIGO!"
	new_lbl.add_theme_font_size_override("font_size", 13)
	new_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	vb.add_child(new_lbl)

	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 24)
	_name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.85))
	var ff := UiTheme.fancy_font()
	if ff != null:
		_name_lbl.add_theme_font_override("font", ff)
	vb.add_child(_name_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.add_theme_font_size_override("font_size", 14)
	_desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_desc_lbl)

	_stats_lbl = Label.new()
	_stats_lbl.add_theme_font_size_override("font_size", 13)
	_stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
	vb.add_child(_stats_lbl)

	set_process(false)


## Enfileira um inimigo para apresentação (mostra agora se estiver livre).
func show_enemy(d: EnemyData) -> void:
	if d == null:
		return
	_queue.append(d)
	if not _active:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_active = false
		_panel.visible = false
		set_process(false)
		return
	var d: EnemyData = _queue.pop_front()
	_fill(d)
	_t = 0.0
	_active = true
	_panel.visible = true
	_panel.position = Vector2(_x_off, Y)
	set_process(true)


func _fill(d: EnemyData) -> void:
	_name_lbl.text = d.display_name
	var tex: Texture2D = Art.enemy(d.id)
	if tex != null:
		_art.texture = tex
		_art_fallback.visible = false
	else:
		_art.texture = null
		_art_fallback.color = d.color
		_art_fallback.visible = true
	_desc_lbl.text = _describe(d)
	_stats_lbl.text = "Vida %d   Vel %d   Def %d" % [d.max_hp, int(round(d.speed)), d.defense]


## Traços legíveis a partir dos stats (sem precisar de texto escrito à mão).
func _describe(d: EnemyData) -> String:
	var tags: Array = []
	if d.element >= 0 and d.element < Elements.NAMES.size():
		tags.append(Elements.NAMES[d.element])
	if d.special == EnemyData.Special.SPLIT:
		tags.append("Se divide")
	if d.defense >= 5:
		tags.append("Blindado")
	if d.speed >= 200.0:
		tags.append("Veloz")
	elif d.speed <= 90.0:
		tags.append("Lento")
	if d.max_hp >= 120:
		tags.append("Resistente")
	return "  •  ".join(tags)


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	var total := SLIDE + HOLD + SLIDE
	var x := _x_on
	if _t < SLIDE:
		x = lerp(_x_off, _x_on, ease(_t / SLIDE, 0.4)) # entrada com desaceleração
	elif _t > SLIDE + HOLD:
		x = lerp(_x_on, _x_off, ease((_t - SLIDE - HOLD) / SLIDE, 2.2))
	_panel.position.x = x
	if _t >= total:
		_next()
