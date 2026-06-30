class_name PowerButton
extends Control

## Botão de poder circular (estilo Kingdom Rush): disco com ícone, anel de carga
## que enche 0→1 e brilho pulsante quando pronto. Compacto, fica nos cantos
## inferiores. Emite pressed só quando carregado.

signal pressed

const SIZE := 86.0

var icon_glyph: String = "★"
var ring_color: Color = Color(1.0, 0.85, 0.3)
var title: String = "Poder"
var _charge: float = 1.0
var _charged: bool = true
var _t: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE + 16)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func setup(glyph: String, color: Color, name_text: String) -> void:
	icon_glyph = glyph
	ring_color = color
	title = name_text
	queue_redraw()


func set_charge(frac: float) -> void:
	_charge = clampf(frac, 0.0, 1.0)
	_charged = _charge >= 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if _charged:
		_t += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _charged:
			pressed.emit()
		accept_event()


func _draw() -> void:
	var c := Vector2(SIZE * 0.5, SIZE * 0.5)
	var r := SIZE * 0.5 - 4.0
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)

	# Sombra + disco de fundo.
	draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.35))
	var bg := Color(0.16, 0.13, 0.09, 0.96) if _charged else Color(0.11, 0.11, 0.13, 0.9)
	draw_circle(c, r, bg)

	# Trilho do anel + anel de carga (enche no sentido horário a partir do topo).
	draw_arc(c, r - 2.0, 0.0, TAU, 40, Color(0, 0, 0, 0.4), 4.0)
	var start := -PI / 2.0
	var col := ring_color if _charged else Color(0.55, 0.5, 0.4)
	if _charged:
		col = Color(ring_color.r, ring_color.g, ring_color.b, 0.7 + 0.3 * pulse)
	draw_arc(c, r - 2.0, start, start + TAU * _charge, 48, col, 4.0)

	# Brilho externo quando pronto.
	if _charged:
		draw_arc(c, r + 1.0, 0.0, TAU, 40, Color(ring_color.r, ring_color.g, ring_color.b, 0.25 + 0.25 * pulse), 6.0)

	# Ícone central.
	var f := ThemeDB.fallback_font
	var icol := Color(1, 0.96, 0.85) if _charged else Color(0.6, 0.6, 0.64)
	var isz := 34
	var iw := f.get_string_size(icon_glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, isz).x
	draw_string(f, c + Vector2(-iw * 0.5, 12), icon_glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, isz, icol)

	# Rótulo curto embaixo (nome ou %).
	var label := title if _charged else ("%d%%" % int(_charge * 100.0))
	var lcol := Color(1, 0.92, 0.7) if _charged else Color(0.7, 0.7, 0.72)
	var lw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
	draw_string(f, Vector2(SIZE * 0.5 - lw * 0.5, SIZE + 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, lcol)
