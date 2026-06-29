class_name TouchJoystick
extends Node2D

## Joystick virtual flutuante (mobile; também testável no PC arrastando o cursor).
## Aparece onde o dedo/cursor toca; o manípulo segue até um raio máximo e a direção
## resultante (0..1) comanda o campeão. Some ao soltar. Um toque sem arraste fica
## com direção zero — então cliques casuais não movem o herói.

const RADIUS := 72.0
const THUMB := 30.0

var active: bool = false
var _base: Vector2 = Vector2.ZERO
var _thumb: Vector2 = Vector2.ZERO


func start(at: Vector2) -> void:
	active = true
	_base = at
	_thumb = at
	visible = true
	queue_redraw()


func update(at: Vector2) -> void:
	if not active:
		return
	var off := at - _base
	_thumb = _base + off.limit_length(RADIUS)
	queue_redraw()


func stop() -> void:
	active = false
	visible = false
	queue_redraw()


## Direção normalizada por RADIUS (magnitude 0..1; 0 = parado/automático).
func direction() -> Vector2:
	if not active:
		return Vector2.ZERO
	return (_thumb - _base) / RADIUS


func _draw() -> void:
	if not active:
		return
	# Base (anel translúcido) — fica sob o polegar.
	draw_circle(_base, RADIUS, Color(0, 0, 0, 0.20))
	draw_arc(_base, RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.45), 3.0)
	# Manípulo (segue o arraste).
	draw_circle(_thumb, THUMB, Color(1, 1, 1, 0.30))
	draw_arc(_thumb, THUMB, 0.0, TAU, 28, Color(1, 1, 1, 0.75), 2.5)
