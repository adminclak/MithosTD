class_name Level
extends Node2D

## Mapa da fase: fundo de grama, rota (caminho), portal de entrada, castelo (base)
## e decorações. Usa as artes de assets/map/ quando existem; senão cai num visual
## desenhado por código.

const WAYPOINTS: Array = [
	Vector2(-40, 160),
	Vector2(360, 160),
	Vector2(360, 420),
	Vector2(760, 420),
	Vector2(760, 180),
	Vector2(1040, 180),
	Vector2(1040, 520),
	Vector2(1240, 520),
]

const GRASS := Color(0.27, 0.45, 0.22)
const PATH_BORDER := Color(0.46, 0.36, 0.24)
const PATH_FILL := Color(0.78, 0.66, 0.45)

# Decorações fixas (longe do caminho e acima da barra de heróis): id, x, y, escala
const DECOS := [
	["tree", 120, 470, 0.20], ["tree", 1170, 110, 0.20], ["tree", 700, 90, 0.17],
	["rock", 470, 250, 0.12], ["rock", 1150, 470, 0.13], ["bush", 250, 560, 0.12],
	["bush", 900, 560, 0.12], ["bush", 560, 110, 0.11],
]


func _ready() -> void:
	# Fundo de grama (sprite cobrindo a tela), ou cor sólida de fallback.
	var grass := Art.map("map_grass")
	if grass != null:
		var bg := Sprite2D.new()
		bg.texture = grass
		bg.centered = true
		bg.position = Vector2(640, 360)
		bg.z_index = -20
		bg.scale = Vector2(1280.0 / grass.get_width(), 720.0 / grass.get_height())
		add_child(bg)

	# Decorações (atrás do gameplay).
	for d in DECOS:
		_add_sprite(Art.map(d[0]), Vector2(d[1], d[2]), d[3], -10)

	# Caminho (borda + miolo).
	add_child(_path_line(54, PATH_BORDER))
	add_child(_path_line(40, PATH_FILL))

	# Portal de entrada (1º waypoint) e castelo/base (último).
	_add_sprite(Art.map("portal"), WAYPOINTS[0] + Vector2(30, 0), 0.16, -5)
	_add_sprite(Art.map("castle"), WAYPOINTS[-1], 0.18, -1)
	queue_redraw()


func _add_sprite(tex: Texture2D, pos: Vector2, scl: float, z: int) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = Vector2(scl, scl)
	s.z_index = z
	add_child(s)


func _path_line(w: float, col: Color) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array(WAYPOINTS)
	l.width = w
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.z_index = -8
	return l


func get_waypoints() -> Array:
	return WAYPOINTS.duplicate()


func _draw() -> void:
	# Fallback: se não houver sprite de grama, pinta o fundo + base/entrada simples.
	if Art.map("map_grass") == null:
		draw_rect(Rect2(0, 0, 1280, 720), GRASS)
		var base_pos: Vector2 = WAYPOINTS[-1]
		draw_circle(base_pos, 24.0, Color(0.2, 0.7, 0.32))
		draw_circle(WAYPOINTS[0] + Vector2(20, 0), 9.0, Color(0.7, 0.3, 0.3))
