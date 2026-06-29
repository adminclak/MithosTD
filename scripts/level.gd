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

# Pontos estratégicos (slots) fixos onde se constrói torre — estilo Kingdom Rush.
# Posições em áreas de grama, ao lado do caminho.
const BUILD_SLOTS := [
	Vector2(250, 250), Vector2(470, 300), Vector2(250, 510),
	Vector2(560, 330), Vector2(660, 540), Vector2(880, 300),
	Vector2(900, 110), Vector2(1140, 300), Vector2(1150, 430),
]

# Mitologia do cenário (definida pela fase). Controla chão, cor do caminho e decos.
var theme: String = "elis"

# Árvore usada na borda de floresta por cena (forma o "muro" de mata do KR).
const BORDER_BY_THEME := {"elis": "tree", "nemeia": "pine"}

# Escala consistente por tipo de decoração (objetos têm 192px).
const DECO_SCALE := {
	"tree": 0.30, "rock": 0.18, "bush": 0.21, "olive_tree": 0.30, "pine": 0.34,
	"reeds": 0.24, "lily": 0.20, "cliff_rock": 0.32, "dead_tree": 0.30,
	"column": 0.30, "statue": 0.34,
}

# Posições fixas das decorações (longe do caminho e acima da barra de heróis).
const DECO_SPOTS := [
	[120, 470, 0.20], [1170, 110, 0.20], [700, 90, 0.17], [470, 250, 0.12],
	[1150, 470, 0.13], [250, 560, 0.12], [900, 560, 0.12], [560, 110, 0.11],
	[60, 300, 0.15], [1200, 300, 0.13], [600, 300, 0.11], [180, 95, 0.12],
	[880, 300, 0.13], [430, 560, 0.12], [1000, 95, 0.12], [330, 560, 0.10],
]

# Cor do caminho (borda, miolo) por cena.
const PATH_COLORS := {
	"elis": [Color(0.46, 0.36, 0.24), Color(0.82, 0.70, 0.47)],
	"nemeia": [Color(0.34, 0.26, 0.15), Color(0.60, 0.48, 0.30)],
	"pantano": [Color(0.30, 0.30, 0.22), Color(0.55, 0.54, 0.38)],
	"desfiladeiro": [Color(0.50, 0.30, 0.20), Color(0.80, 0.56, 0.40)],
	"olimpo": [Color(0.55, 0.55, 0.60), Color(0.88, 0.86, 0.84)],
}

# Conjunto de decorações por tema (ids de assets/map). Verdes usam árvore/arbusto;
# deserto/neve usam só pedras (e árvore na neve).
# Decorações por cena (combinam com o nome da fase). Repetem em mais pontos.
const THEME_DECOS := {
	"elis": ["olive_tree", "bush", "statue", "olive_tree", "rock", "bush", "olive_tree", "column",
		"bush", "olive_tree", "rock", "bush", "olive_tree", "bush", "rock", "olive_tree"],
	"nemeia": ["pine", "tree", "pine", "rock", "tree", "pine", "bush", "rock",
		"pine", "tree", "pine", "bush", "tree", "pine", "rock", "tree"],
	"pantano": ["reeds", "lily", "reeds", "rock", "dead_tree", "reeds", "lily", "bush",
		"reeds", "lily", "reeds", "dead_tree", "reeds", "lily", "rock", "reeds"],
	"desfiladeiro": ["cliff_rock", "dead_tree", "rock", "cliff_rock", "rock", "cliff_rock", "dead_tree", "rock",
		"cliff_rock", "rock", "dead_tree", "cliff_rock", "rock", "cliff_rock", "rock", "dead_tree"],
	"olimpo": ["column", "statue", "rock", "column", "cliff_rock", "column", "statue", "rock",
		"column", "rock", "statue", "column", "cliff_rock", "column", "rock", "statue"],
}


func _ground_texture() -> Texture2D:
	# ground_<tema> (ex.: ground_nordica); fallback para o map_grass original.
	var g := Art.map("ground_" + theme.to_lower())
	if g == null:
		g = Art.map("map_grass")
	return g


func _path_pair() -> Array:
	return PATH_COLORS.get(theme, [PATH_BORDER, PATH_FILL])


func _ready() -> void:
	# Chão do tema (sprite cobrindo a tela), ou cor sólida de fallback.
	var grass := _ground_texture()
	if grass != null:
		var bg := Sprite2D.new()
		bg.texture = grass
		bg.centered = true
		bg.position = Vector2(640, 360)
		bg.z_index = -20
		bg.scale = Vector2(1280.0 / grass.get_width(), 720.0 / grass.get_height())
		add_child(bg)

	# Borda densa de árvores emoldurando o mapa (estilo Kingdom Rush).
	var border_id: String = BORDER_BY_THEME.get(theme, "")
	if border_id != "" and Art.map(border_id) != null:
		_add_forest_border(border_id)

	# Decorações do tema (atrás do gameplay), escala CONSISTENTE por tipo + sombra.
	var deco_ids: Array = THEME_DECOS.get(theme, THEME_DECOS["elis"])
	for i in DECO_SPOTS.size():
		var spot: Array = DECO_SPOTS[i]
		var did: String = deco_ids[i % deco_ids.size()]
		var scl: float = DECO_SCALE.get(did, 0.22)
		var pos := Vector2(spot[0], spot[1])
		var base := pos + Vector2(0, 192.0 * scl * 0.46) # pé do objeto
		_add_shadow(base, 192.0 * scl * 0.34, 192.0 * scl * 0.13, -11)
		_add_sprite(Art.map(did), pos, scl, -10, i % 3 == 0)

	# Caminho: sombra (profundidade) + borda + miolo + listra central clara.
	var pc := _path_pair()
	var border: Color = pc[0]
	var fill: Color = pc[1]
	var shadow := Color(0, 0, 0, 0.25)
	var shadow_line := _path_line(60, shadow)
	shadow_line.position = Vector2(0, 5)
	add_child(shadow_line)
	add_child(_path_line(54, border))
	add_child(_path_line(42, fill))
	var stripe := _path_line(8, Color(fill.r * 1.12, fill.g * 1.12, fill.b * 1.12, 0.5))
	add_child(stripe)

	# Portal de entrada (1º waypoint) e castelo/base (último) — grandes, com sombra.
	var portal_pos: Vector2 = WAYPOINTS[0] + Vector2(40, 0)
	_add_shadow(portal_pos + Vector2(0, 38), 56, 20, -6)
	_add_sprite(Art.map("portal"), portal_pos, 0.46, -5)
	var castle_pos: Vector2 = WAYPOINTS[-1] + Vector2(0, -8)
	_add_shadow(castle_pos + Vector2(0, 56), 80, 28, -2)
	_add_sprite(Art.map("castle"), castle_pos, 0.70, -1)
	queue_redraw()


func _add_sprite(tex: Texture2D, pos: Vector2, scl: float, z: int, flip: bool = false) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = Vector2(-scl if flip else scl, scl)
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


func get_build_slots() -> Array:
	return BUILD_SLOTS.duplicate()


## Muro de árvores nas 4 bordas (denso, emoldura o campo de jogo como no KR).
func _add_forest_border(tree_id: String) -> void:
	var scl := 0.40
	var step := 60
	var rows := [-6, 30] # duas fileiras no topo p/ formar copa densa
	# Topo (2 fileiras) e base (1 fileira).
	for ry in rows:
		for x in range(-10, 1300, step):
			_add_sprite(Art.map(tree_id), Vector2(x + (ry * 2), ry), scl, -6)
	for x in range(-10, 1300, step):
		_add_sprite(Art.map(tree_id), Vector2(x + 26, 712), scl, -6)
	# Laterais.
	for y in range(40, 700, step):
		_add_sprite(Art.map(tree_id), Vector2(-4, y), scl, -6)
		_add_sprite(Art.map(tree_id), Vector2(1284, y), scl, -6)


## Sombra elíptica (chão) sob um objeto. center = base do objeto.
func _add_shadow(center: Vector2, rw: float, rh: float, z: int) -> void:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		pts.append(center + Vector2(cos(a) * rw, sin(a) * rh))
	poly.polygon = pts
	poly.color = Color(0, 0, 0, 0.22)
	poly.z_index = z
	add_child(poly)


func _draw() -> void:
	# Fallback: se não houver sprite de chão, pinta o fundo + base/entrada simples.
	if _ground_texture() == null:
		draw_rect(Rect2(0, 0, 1280, 720), GRASS)
		var base_pos: Vector2 = WAYPOINTS[-1]
		draw_circle(base_pos, 24.0, Color(0.2, 0.7, 0.32))
		draw_circle(WAYPOINTS[0] + Vector2(20, 0), 9.0, Color(0.7, 0.3, 0.3))
	# Vinheta: escurece levemente as bordas para dar profundidade (sempre).
	var bands := 26
	for i in bands:
		var a: float = (1.0 - float(i) / float(bands)) * 0.5
		var col := Color(0, 0, 0, a * 0.05)
		var o: float = float(i) * 3.0
		draw_rect(Rect2(0, o, 1280, 3), col)            # topo
		draw_rect(Rect2(0, 717 - o, 1280, 3), col)      # base
		draw_rect(Rect2(o, 0, 3, 720), col)             # esquerda
		draw_rect(Rect2(1277 - o, 0, 3, 720), col)      # direita
