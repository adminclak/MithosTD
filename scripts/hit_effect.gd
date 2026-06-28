class_name HitEffect
extends Node2D

## Efeito visual efêmero (faísca de flecha, explosão de bola de fogo, brilho de
## conjuração). Desenha um anel que cresce e some, e se autodestrói. Puro código.

var _t: float = 0.0
var _dur: float = 0.30
var _max_r: float = 20.0
var _col: Color = Color(1.0, 0.6, 0.2)
var _filled: bool = false
var _sparks: int = 0


func setup(max_r: float, col: Color, filled: bool = false, dur: float = 0.30, sparks: int = 0) -> void:
	_max_r = max_r
	_col = col
	_filled = filled
	_dur = dur
	_sparks = sparks
	z_index = 50


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= _dur:
		queue_free()


func _draw() -> void:
	var k: float = clampf(_t / _dur, 0.0, 1.0)
	var r: float = lerp(3.0, _max_r, k)
	var a: float = 1.0 - k
	if _filled:
		# Miolo quente da explosão.
		draw_circle(Vector2.ZERO, r * 0.7, Color(1.0, 0.95, 0.6, a * 0.6))
		draw_circle(Vector2.ZERO, r, Color(_col.r, _col.g, _col.b, a * 0.45))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(_col.r, _col.g, _col.b, a), 2.5)
	# Estilhaços radiais (faísca).
	for i in _sparks:
		var ang: float = TAU * float(i) / float(max(1, _sparks))
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(dir * (r * 0.6), dir * r, Color(_col.r, _col.g, _col.b, a), 1.5)
