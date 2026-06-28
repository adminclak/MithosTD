class_name MatchHud
extends CanvasLayer

## Botões de controle da partida: lançar onda (também usado na preparação para
## iniciar), pausar, mudar velocidade e abandonar. process_mode ALWAYS para os
## botões continuarem respondendo enquanto o jogo está pausado.

signal advance_pressed
signal pause_pressed
signal speed_pressed
signal abandon_pressed

var _phase_label: Label
var _advance_btn: Button
var _pause_btn: Button
var _speed_btn: Button


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
	add_child(_phase_label)


func _mk(text: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(124, 34)
	b.text = text
	return b


func set_phase(text: String) -> void:
	_phase_label.text = text


func set_advance_enabled(on: bool) -> void:
	_advance_btn.disabled = not on


func set_paused(p: bool) -> void:
	_pause_btn.text = "Continuar" if p else "Pause"


func set_fast(fast: bool) -> void:
	_speed_btn.text = "x2" if fast else "x1"
