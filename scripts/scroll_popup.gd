class_name ScrollPopup
extends CanvasLayer

## Anúncio em "pergaminho" (estilo Kingdom Rush): desce do topo, segura e sobe.
## Usado para "ONDA X", "Nova Onda!", etc.

var _panel: PanelContainer
var _label: Label
var _t: float = 0.0
var _dur: float = 2.2
var _active: bool = false


func _ready() -> void:
	layer = 10
	_panel = PanelContainer.new()
	_panel.position = Vector2(420, -120)
	_panel.custom_minimum_size = Vector2(440, 84)
	_panel.size = Vector2(440, 84)
	add_child(_panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", Color(0.45, 0.22, 0.08))
	var ff := UiTheme.fancy_font()
	if ff != null:
		_label.add_theme_font_override("font", ff)
	_panel.add_child(_label)
	_panel.visible = false


func announce(text: String, dur: float = 2.2) -> void:
	_label.text = text
	_dur = dur
	_t = 0.0
	_active = true
	_panel.visible = true
	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	# Desce (0..0.4s), segura, sobe (últimos 0.5s).
	var target_y := 28.0
	if _t < 0.4:
		target_y = lerp(-120.0, 28.0, _t / 0.4)
	elif _t > _dur - 0.5:
		target_y = lerp(28.0, -120.0, (_t - (_dur - 0.5)) / 0.5)
	_panel.position.y = target_y
	if _t >= _dur:
		_active = false
		_panel.visible = false
		set_process(false)
