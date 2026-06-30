class_name MatchHud
extends CanvasLayer

## Controles da partida (estilo Kingdom Rush): cluster compacto no topo (Lançar
## Onda + Pause + velocidade + Abandonar) e dois PODERES circulares pequenos nos
## cantos inferiores (Reforços à esquerda, Poder Supremo à direita), acima da
## barra de heróis. process_mode ALWAYS p/ responder mesmo em pausa.

signal advance_pressed
signal pause_pressed
signal speed_pressed
signal abandon_pressed
signal ult_pressed
signal power2_pressed

var _phase_label: Label
var _advance_btn: Button
var _pause_btn: Button
var _speed_btn: Button
var _ult: PowerButton
var _power2: PowerButton


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Cluster de controle no topo (centro), compacto e temático.
	var bar := HBoxContainer.new()
	bar.position = Vector2(338, 12)
	bar.add_theme_constant_override("separation", 7)
	add_child(bar)

	_advance_btn = _btn("Lancar Onda", 150, true)
	_advance_btn.pressed.connect(func(): advance_pressed.emit())
	bar.add_child(_advance_btn)

	_pause_btn = _btn("II", 46, false)
	_pause_btn.add_theme_font_size_override("font_size", 18)
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	bar.add_child(_pause_btn)

	_speed_btn = _btn("x1", 54, false)
	_speed_btn.pressed.connect(func(): speed_pressed.emit())
	bar.add_child(_speed_btn)

	# Abandonar: discreto, canto superior direito.
	var abandon := _btn("Sair", 78, false)
	abandon.position = Vector2(1192, 12)
	abandon.add_theme_color_override("font_color", Color(1.0, 0.6, 0.55))
	abandon.pressed.connect(func(): abandon_pressed.emit())
	add_child(abandon)

	_phase_label = Label.new()
	_phase_label.position = Vector2(340, 56)
	_phase_label.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	_phase_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_phase_label.add_theme_constant_override("shadow_offset_x", 1)
	_phase_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_phase_label)

	# Reforços (canto inferior ESQUERDO) — circular, acima da barra de heróis.
	_power2 = PowerButton.new()
	_power2.position = Vector2(20, 520)
	_power2.setup("R", Color(0.45, 0.9, 0.55), "Reforcos")
	_power2.pressed.connect(func(): power2_pressed.emit())
	add_child(_power2)

	# Poder Supremo (canto inferior DIREITO) — começa escondido (só se houver ult).
	_ult = PowerButton.new()
	_ult.position = Vector2(1174, 520)
	_ult.setup("★", Color(1, 0.85, 0.3), "Supremo")
	_ult.visible = false
	_ult.pressed.connect(func(): ult_pressed.emit())
	add_child(_ult)


## Botão temático (madeira/ouro) — primary = destaque dourado (ação principal).
func _btn(text: String, w: int, primary: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(w, 40)
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.30, 0.22, 0.10, 0.96) if primary else Color(0.15, 0.14, 0.13, 0.92)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(1.0, 0.82, 0.35) if primary else Color(0.55, 0.48, 0.34)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	var hv := sb.duplicate()
	hv.bg_color = Color(0.40, 0.30, 0.14, 0.98) if primary else Color(0.22, 0.20, 0.18, 0.95)
	var dis := sb.duplicate()
	dis.bg_color = Color(0.12, 0.12, 0.12, 0.7)
	dis.border_color = Color(0.35, 0.32, 0.28)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6) if primary else Color(0.92, 0.9, 0.85))
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.62))
	return b


func set_phase(text: String) -> void:
	_phase_label.text = text


func set_advance_enabled(on: bool) -> void:
	_advance_btn.disabled = not on


func set_paused(p: bool) -> void:
	_pause_btn.text = "▶" if p else "II"


func set_fast(fast: bool) -> void:
	_speed_btn.text = "x2" if fast else "x1"


func set_ult(name: String, color: Color) -> void:
	_ult.visible = true
	_ult.setup("★", color, "Supremo")


func set_ult_charge(frac: float) -> void:
	if _ult != null:
		_ult.set_charge(frac)


func set_power2_charge(frac: float) -> void:
	if _power2 != null:
		_power2.set_charge(frac)
