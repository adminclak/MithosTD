class_name UltAimer
extends Control

## Sobreposição de mira do Poder Supremo. Quando ativa, escurece a tela, desenha
## uma retícula no cursor e captura o clique (esquerdo = lançar no ponto; direito/
## ESC = cancelar). Emite aimed(pos) com a posição escolhida.

signal aimed(pos: Vector2)
signal canceled

var color: Color = Color(1, 0.85, 0.3)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	z_index = 50


func start(c: Color) -> void:
	color = c
	visible = true
	queue_redraw()


func stop() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			aimed.emit(get_local_mouse_position())
			stop()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			canceled.emit()
			stop()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		canceled.emit()
		stop()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	# Escurece o fundo para destacar a mira.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))
	var m := get_local_mouse_position()
	# Retícula.
	draw_arc(m, 64.0, 0.0, TAU, 40, color, 3.0)
	draw_arc(m, 34.0, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.7), 2.0)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var d := Vector2(cos(a), sin(a))
		draw_line(m + d * 18.0, m + d * 30.0, color, 2.0)
	# Dica.
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(20, 36), "PODER SUPREMO: clique onde lancar  (direito/ESC cancela)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
