class_name UltAimer
extends Control

## Sobreposição de mira do Poder Supremo. Quando ativa, escurece a tela, desenha
## uma retícula no cursor e captura o clique via _input (esquerdo = lançar no
## ponto; direito/ESC = cancelar). Emite aimed(pos) com a posição escolhida.

signal aimed(pos: Vector2)
signal canceled

var color: Color = Color(1, 0.85, 0.3)
var _active: bool = false


func _ready() -> void:
	# Cobre a tela toda (FULL_RECT dimensiona sozinho) e bloqueia cliques abaixo.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(false)


func start(c: Color) -> void:
	color = c
	_active = true
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_active = false
	visible = false
	set_process(false)


func _process(_delta: float) -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			aimed.emit(get_global_mouse_position())
			stop()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			canceled.emit()
			stop()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		canceled.emit()
		stop()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.30))
	var m := get_global_mouse_position()
	draw_arc(m, 66.0, 0.0, TAU, 40, color, 3.0)
	draw_arc(m, 34.0, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.7), 2.0)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var d := Vector2(cos(a), sin(a))
		draw_line(m + d * 18.0, m + d * 32.0, color, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(24, 40),
		"PODER SUPREMO: clique onde lancar  (botao direito / ESC = cancelar)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
