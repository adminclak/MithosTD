class_name Level
extends Node2D

## Mapa da fase: fundo, rota (caminho) e a base. Sem slots fixos — o
## posicionamento de torres é livre (com zonas), tratado pelo BuildManager.

const WAYPOINTS: Array = [
	Vector2(-40, 160),
	Vector2(360, 160),
	Vector2(360, 420),
	Vector2(760, 420),
	Vector2(760, 180),
	Vector2(1040, 180),
	Vector2(1040, 560),
	Vector2(1240, 560),
]

const GRASS := Color(0.15, 0.21, 0.16)
const PATH_BORDER := Color(0.42, 0.35, 0.24)
const PATH_FILL := Color(0.82, 0.73, 0.55)


func _ready() -> void:
	# Caminho desenhado em duas camadas (borda + miolo) para um visual mais limpo.
	var border := _path_line(54, PATH_BORDER)
	add_child(border)
	var fill := _path_line(40, PATH_FILL)
	add_child(fill)
	queue_redraw()


func _path_line(w: float, col: Color) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array(WAYPOINTS)
	l.width = w
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	return l


func get_waypoints() -> Array:
	return WAYPOINTS.duplicate()


func _draw() -> void:
	# Fundo (grama). Desenhado pelo Level; o caminho (filhos Line2D) vem por cima.
	draw_rect(Rect2(0, 0, 1280, 720), GRASS)

	# Entrada dos inimigos.
	var start: Vector2 = WAYPOINTS[0]
	draw_circle(start + Vector2(20, 0), 9.0, Color(0.7, 0.3, 0.3))

	# Base (chegada) — a defender.
	var base_pos: Vector2 = WAYPOINTS[-1]
	draw_circle(base_pos, 27.0, Color(0.12, 0.45, 0.22))
	draw_circle(base_pos, 21.0, Color(0.2, 0.7, 0.32))
	draw_circle(base_pos, 9.0, Color(1, 1, 1))
