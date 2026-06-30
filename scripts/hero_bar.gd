class_name HeroBar
extends CanvasLayer

## Barra inferior com os heróis do esquadrão (cards bonitos: retrato + emblema de
## classe + custo). O jogador ARRASTA um card para o mapa para posicionar o herói
## (place_at valida o ponto). Card sem ouro fica esmaecido. Some quando o herói
## entra em campo (volta se for vendido). Sem slots — posicionamento livre e válido.

const BAR_TOP := 632.0
const CARD := Vector2(96, 84)

var _bm: BuildManager
var _row: HBoxContainer
var _armed: TowerData = null ## herói selecionado na barra (aguardando clique no mapa)
var _ghost: TextureRect = null

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(bm: BuildManager) -> void:
	_bm = bm
	_bm.changed.connect(refresh)


func _ready() -> void:
	layer = 8
	var panel := Panel.new()
	panel.position = Vector2(0, BAR_TOP)
	panel.size = Vector2(1280, 720 - BAR_TOP)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.97))
	add_child(panel)
	var mar := MarginContainer.new()
	mar.position = Vector2(12, 6)
	mar.size = Vector2(1256, 720 - BAR_TOP - 12)
	panel.add_child(mar)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mar.add_child(_row)
	if _state != null and _state.has_signal("gold_changed"):
		_state.gold_changed.connect(func(_g): refresh())
	refresh()


func refresh() -> void:
	if _row == null or _bm == null:
		return
	for c in _row.get_children():
		c.queue_free()
	var list: Array = _bm.placeable()
	if list.is_empty():
		var done := Label.new()
		done.text = "Todos os herois em campo — arraste-os pelo mapa ou toque para gerir."
		done.add_theme_color_override("font_color", Color(0.85, 0.82, 0.74))
		_row.add_child(done)
		return
	for d in list:
		_row.add_child(_card(d))


func _card(d: TowerData) -> Control:
	var gold: int = _state.gold if _state != null else 0
	var afford := gold >= d.cost
	var card := Panel.new()
	card.custom_minimum_size = CARD
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var armed := _armed != null and _armed.char_id == d.char_id
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.18, 0.10, 0.95) if armed else (Color(0.16, 0.12, 0.09, 0.9) if afford else Color(0.12, 0.10, 0.10, 0.7))
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(3 if armed else 2)
	sb.border_color = Color(0.6, 0.95, 1.0) if armed else (Color(1.0, 0.82, 0.35) if afford else Color(0.4, 0.35, 0.3))
	card.add_theme_stylebox_override("panel", sb)

	# Retrato do herói (preenche o card; cinza se sem ouro).
	var art := TextureRect.new()
	art.position = Vector2(6, 2)
	art.size = Vector2(CARD.x - 12, 58)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := Art.hero(d.char_id)
	if tex != null:
		art.texture = tex
	art.modulate = Color.WHITE if afford else Color(0.45, 0.45, 0.45)
	card.add_child(art)

	# Custo embaixo.
	var cost := Label.new()
	cost.position = Vector2(0, 62)
	cost.size = Vector2(CARD.x, 18)
	cost.text = "%d" % d.cost
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost.add_theme_font_size_override("font_size", 14)
	cost.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4) if afford else Color(0.85, 0.4, 0.35))
	cost.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	cost.add_theme_constant_override("outline_size", 3)
	card.add_child(cost)

	# Emblema da classe no canto superior-esquerdo.
	var badge := ClassBadge.new(d.tower_class, 24.0)
	badge.position = Vector2(3, 3)
	badge.size = Vector2(24, 24)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(badge)

	if afford:
		card.gui_input.connect(_on_card_input.bind(d))
		card.mouse_default_cursor_shape = Control.CURSOR_DRAG
	return card


func _on_card_input(event: InputEvent, d: TowerData) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_arm(d)


## Arma um herói: ele fica SELECIONADO (card destacado) e um fantasma segue o mouse.
## Depois é só CLICAR no mapa (ou arrastar e soltar) para posicionar.
func _arm(d: TowerData) -> void:
	_armed = d
	if _ghost == null:
		_ghost = TextureRect.new()
		_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ghost.size = Vector2(54, 54)
		_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost.z_index = 50
		add_child(_ghost)
	_ghost.texture = Art.hero(d.char_id)
	_update_ghost(get_viewport().get_mouse_position())
	refresh()


func _input(event: InputEvent) -> void:
	if _armed == null:
		return
	if event is InputEventMouseMotion:
		_update_ghost((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT \
			and (event as InputEventMouseButton).pressed:
		_cancel() # botão direito cancela a seleção
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		# Clique OU soltar sobre o MAPA (acima da barra) -> posiciona.
		var p: Vector2 = (event as InputEventMouseButton).position
		if p.y < BAR_TOP:
			if _bm.place_at(p, _armed):
				_clear()
			get_viewport().set_input_as_handled()


func _update_ghost(p: Vector2) -> void:
	if _ghost == null or _armed == null:
		return
	_ghost.position = p - _ghost.size * 0.5
	var ok := p.y < BAR_TOP and _bm.can_place(p, _armed.is_melee)
	_ghost.modulate = Color(0.6, 1.0, 0.6, 0.9) if ok else Color(1.0, 0.5, 0.5, 0.8)


func _cancel() -> void:
	_clear()


func _clear() -> void:
	_armed = null
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	refresh()
