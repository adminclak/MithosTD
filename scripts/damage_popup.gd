class_name DamagePopup
extends Node2D

## Número de dano flutuante (estilo Kingdom Rush/ape-td): aparece no inimigo, dá um
## "pop" (sobe encolhendo) e some. Cor mais quente/maior quando é crítico.

var _text: String = ""
var _color: Color = Color(1.0, 0.95, 0.6)
var _life: float = 0.0
var _ttl: float = 0.6
var _vy: float = -52.0
var _base_size: float = 16.0

@onready var _font: Font = ThemeDB.fallback_font


func setup(amount: int, color: Color = Color(1.0, 0.95, 0.6), crit: bool = false) -> void:
	_text = str(amount)
	_color = color
	z_index = 60
	if crit:
		_base_size = 24.0
		_ttl = 0.75
		_vy = -64.0
	# leve dispersão horizontal p/ não empilhar números idênticos
	position += Vector2(randf_range(-6.0, 6.0), 0.0)


func _process(delta: float) -> void:
	_life += delta
	position.y += _vy * delta
	_vy = move_toward(_vy, 0.0, 70.0 * delta) # desacelera a subida
	queue_redraw()
	if _life >= _ttl:
		queue_free()


func _draw() -> void:
	if _font == null:
		return
	var t: float = clampf(_life / _ttl, 0.0, 1.0)
	var alpha: float = 1.0 - t * t          # some mais no fim
	var scale_pop: float = 1.0 + 0.35 * (1.0 - clampf(_life / 0.12, 0.0, 1.0)) # estala ao nascer
	var fsize: int = int(round(_base_size * scale_pop))
	var size: Vector2 = _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pos: Vector2 = Vector2(-size.x * 0.5, size.y * 0.3)
	# Contorno escuro (legibilidade sobre qualquer fundo) + número colorido.
	var outline := Color(0, 0, 0, alpha * 0.9)
	for o in [Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(0, -1.5), Vector2(0, 1.5)]:
		_font.draw_string(get_canvas_item(), pos + o, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, outline)
	_font.draw_string(get_canvas_item(), pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize,
			Color(_color.r, _color.g, _color.b, alpha))
