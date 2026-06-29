class_name RadialMenu
extends CanvasLayer

## Menu radial (estilo Kingdom Rush): abre ao redor de um ponto com N opções em
## botões dispostos em círculo. Usado para construir (4 torres) e para gerir
## (melhorar/vender). Clique fora fecha. Emite chosen(index).

signal chosen(index: int)
signal closed

var _panel: Control
var _open: bool = false


func _ready() -> void:
	layer = 9
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	_panel.gui_input.connect(_on_bg_input)
	visible = false


## options = [{ "text": String, "color": Color(opcional), "enabled": bool(opcional) }]
func open_menu(center: Vector2, options: Array) -> void:
	for c in _panel.get_children():
		c.queue_free()
	var n: int = options.size()
	for i in n:
		var ang := -PI / 2.0 + TAU * float(i) / float(n)
		var off := Vector2(cos(ang), sin(ang)) * (84.0 if n > 2 else 70.0)
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 56)
		b.size = Vector2(104, 56)
		b.position = (center + off) - Vector2(52, 28)
		b.add_theme_font_size_override("font_size", 15)
		b.text = options[i].get("text", "?")
		b.disabled = not options[i].get("enabled", true)
		if options[i].has("color"):
			b.add_theme_color_override("font_color", options[i]["color"])
		b.pressed.connect(_choose.bind(i))
		_panel.add_child(b)
	visible = true
	_open = true


func close() -> void:
	visible = false
	_open = false


func is_open() -> bool:
	return _open


func _choose(i: int) -> void:
	close()
	chosen.emit(i)


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
		closed.emit()
