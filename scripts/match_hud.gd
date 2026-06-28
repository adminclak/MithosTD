class_name MatchHud
extends CanvasLayer

## Botões de controle da partida: lançar onda (também usado na preparação para
## iniciar), pausar, mudar velocidade e abandonar. process_mode ALWAYS para os
## botões continuarem respondendo enquanto o jogo está pausado.

signal advance_pressed
signal pause_pressed
signal speed_pressed
signal abandon_pressed
signal ult_pressed

var _phase_label: Label
var _advance_btn: Button
var _pause_btn: Button
var _speed_btn: Button
var _ult_btn: Button
var _ult_name: String = ""
var _ult_color: Color = Color(1, 0.85, 0.3)
var _ult_charge: float = 0.0


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bar := HBoxContainer.new()
	bar.position = Vector2(340, 12)
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)

	_advance_btn = _mk("Lancar Onda")
	_advance_btn.pressed.connect(func(): advance_pressed.emit())
	bar.add_child(_advance_btn)

	_pause_btn = _mk("Pause")
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	bar.add_child(_pause_btn)

	_speed_btn = _mk("x1")
	_speed_btn.custom_minimum_size = Vector2(60, 34)
	_speed_btn.pressed.connect(func(): speed_pressed.emit())
	bar.add_child(_speed_btn)

	var abandon := _mk("Abandonar")
	abandon.pressed.connect(func(): abandon_pressed.emit())
	bar.add_child(abandon)

	_phase_label = Label.new()
	_phase_label.position = Vector2(340, 52)
	_phase_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_phase_label.add_theme_constant_override("shadow_offset_x", 1)
	_phase_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_phase_label)

	# Botão grande do Poder Supremo (canto superior direito).
	_ult_btn = Button.new()
	_ult_btn.position = Vector2(1024, 10)
	_ult_btn.size = Vector2(244, 54)
	_ult_btn.custom_minimum_size = Vector2(244, 54)
	_ult_btn.add_theme_font_size_override("font_size", 15)
	_ult_btn.pressed.connect(func(): ult_pressed.emit())
	_ult_btn.visible = false
	add_child(_ult_btn)
	_refresh_ult()


func _mk(text: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(124, 34)
	b.text = text
	UiTheme.style_button(b)
	return b


func set_phase(text: String) -> void:
	_phase_label.text = text


func set_advance_enabled(on: bool) -> void:
	_advance_btn.disabled = not on


func set_paused(p: bool) -> void:
	_pause_btn.text = "Continuar" if p else "Pause"


func set_fast(fast: bool) -> void:
	_speed_btn.text = "x2" if fast else "x1"


func set_ult(name: String, color: Color) -> void:
	_ult_name = name
	_ult_color = color
	_ult_btn.visible = true
	_refresh_ult()


func set_ult_charge(frac: float) -> void:
	_ult_charge = clampf(frac, 0.0, 1.0)
	_refresh_ult()


func _refresh_ult() -> void:
	if _ult_btn == null or _ult_name == "":
		return
	var ready := _ult_charge >= 1.0
	_ult_btn.disabled = not ready
	if ready:
		_ult_btn.text = "★ %s ★\nPODER SUPREMO PRONTO" % _ult_name
	else:
		_ult_btn.text = "%s\nCarregando %d%%" % [_ult_name, int(_ult_charge * 100.0)]
	# Moldura dourada acende quando pronto.
	var border := _ult_color if ready else Color(0.45, 0.4, 0.3)
	var bg := Color(0.20, 0.16, 0.10, 0.95) if ready else Color(0.12, 0.12, 0.14, 0.85)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3)
	sb.border_color = border
	if ready:
		sb.shadow_color = Color(_ult_color.r, _ult_color.g, _ult_color.b, 0.6)
		sb.shadow_size = 8
	_ult_btn.add_theme_stylebox_override("normal", sb)
	_ult_btn.add_theme_stylebox_override("hover", sb)
	_ult_btn.add_theme_stylebox_override("disabled", sb)
	_ult_btn.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	_ult_btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.72))
