class_name Level
extends Node2D

## Mapa da fase: fundo de grama, rota (caminho), portal de entrada, castelo (base)
## e decorações. Usa as artes de assets/map/ quando existem; senão cai num visual
## desenhado por código.

# Caminho (trajeto dos inimigos) POR FASE — cada uma com um traçado próprio, do
# portal (1º ponto, fora da tela) até o castelo (último ponto, numa borda).
# Waypoints TRAÇADOS AUTOMATICAMENTE sobre a trilha pintada de cada mapa
# (tools/tracepath.py: segmenta a cor da trilha -> A* pelo miolo -> simplifica).
# Assim os inimigos andam exatamente sobre a faixa desenhada na arte.
const PATHS_BY_THEME := {
	# Elis: entra pelo topo, desce e segue a faixa bege até o canto inferior-direito.
	"elis": [
		Vector2(262, -30), Vector2(258, 140), Vector2(272, 205), Vector2(430, 190),
		Vector2(620, 182), Vector2(800, 186), Vector2(945, 205), Vector2(1040, 290),
		Vector2(1075, 420), Vector2(1095, 520), Vector2(1185, 560),
	],
	# Nemeia: trilha bege quase horizontal, da borda esquerda à direita (ondas suaves).
	"nemeia": [
		Vector2(34, 390), Vector2(225, 362), Vector2(342, 362), Vector2(462, 348),
		Vector2(612, 368), Vector2(800, 348), Vector2(985, 390), Vector2(1215, 387),
	],
	# Pântano: trilha única de terra batida, sobe em S da esquerda-baixo ao topo e sai
	# pela direita contornando o lago.
	"pantano": [
		Vector2(-3, 462), Vector2(55, 462), Vector2(145, 550), Vector2(168, 550),
		Vector2(255, 498), Vector2(288, 492), Vector2(322, 458), Vector2(345, 415),
		Vector2(455, 312), Vector2(565, 240), Vector2(615, 240), Vector2(700, 220),
		Vector2(748, 172), Vector2(752, 135), Vector2(802, 92), Vector2(865, 92),
		Vector2(908, 78), Vector2(1005, 78), Vector2(1038, 95), Vector2(1098, 100),
		Vector2(1148, 142), Vector2(1222, 142), Vector2(1268, 95),
	],
	# Desfiladeiro (garganta vulcânica): entra no topo-esquerda, desce o braço esquerdo,
	# contorna a rocha central e sobe o braço direito até o topo-direita.
	"desfiladeiro": [
		Vector2(242, -23), Vector2(260, 60), Vector2(308, 118), Vector2(308, 192),
		Vector2(285, 215), Vector2(292, 282), Vector2(430, 392), Vector2(480, 392),
		Vector2(658, 375), Vector2(748, 292), Vector2(775, 222), Vector2(815, 182),
		Vector2(848, 115), Vector2(870, 92), Vector2(905, 85), Vector2(955, 35),
		Vector2(955, -13),
	],
	# Olimpo: entra à esquerda, segue a faixa de pedra dourada e sobe à direita
	# contornando as ilhas de neve.
	"olimpo": [
		Vector2(82, 460), Vector2(128, 415), Vector2(195, 415), Vector2(222, 442),
		Vector2(385, 490), Vector2(450, 490), Vector2(512, 510), Vector2(598, 508),
		Vector2(662, 470), Vector2(725, 450), Vector2(745, 430), Vector2(772, 365),
		Vector2(785, 265), Vector2(800, 250), Vector2(818, 240), Vector2(955, 235),
		Vector2(1062, 330), Vector2(1095, 475), Vector2(1120, 500), Vector2(1235, 500),
	],
}
const DEFAULT_PATH := [Vector2(-40, 160), Vector2(360, 160), Vector2(360, 420),
	Vector2(760, 420), Vector2(760, 180), Vector2(1040, 180), Vector2(1040, 520),
	Vector2(1240, 520)]

# Temas cujo CAMINHO já está PINTADO na arte do mapa (estilo Kingdom Rush). Nesses
# não desenhamos a faixa de caminho por código — o trajeto só segue a trilha da arte.
const PATH_IN_ART := {
	"elis": true, "nemeia": true, "pantano": true, "desfiladeiro": true, "olimpo": true,
}

# Pontos de torre: gerados automaticamente AO LADO da trilha (perpendicular a cada
# segmento, alternando os lados) por _slots_for_path, acompanhando o caminho traçado.
const SLOTS_BY_THEME := {}

const GRASS := Color(0.27, 0.45, 0.22)
const PATH_BORDER := Color(0.46, 0.36, 0.24)
const PATH_FILL := Color(0.78, 0.66, 0.45)

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


## Mapa pintado HD de tela cheia (estilo Kingdom Rush), embute grama + borda de
## floresta + pedras na própria arte. Quando existe, dispensa o chão lado a lado,
## a borda de árvores por código e as decorações por código.
func _painted_map() -> Texture2D:
	return Art.map("map_" + theme.to_lower())


## Traçado do caminho desta fase (cai no padrão se o tema não tiver um próprio).
func _theme_path() -> Array:
	return PATHS_BY_THEME.get(theme, DEFAULT_PATH)


func _ground_texture() -> Texture2D:
	# ground_<tema> (ex.: ground_nordica); fallback para o map_grass original.
	var g := Art.map("ground_" + theme.to_lower())
	if g == null:
		g = Art.map("map_grass")
	return g


func _path_pair() -> Array:
	return PATH_COLORS.get(theme, [PATH_BORDER, PATH_FILL])


func _ready() -> void:
	# Preferência: mapa pintado HD de tela cheia (estilo Kingdom Rush). Se existir,
	# ele já traz grama + borda de floresta + pedras, então pulamos chão lado a
	# lado, borda de árvores por código e decorações por código.
	var painted := _painted_map()
	if painted != null:
		var bg := Sprite2D.new()
		bg.texture = painted
		bg.centered = true
		bg.position = Vector2(640, 360)
		bg.z_index = -20
		bg.scale = Vector2(1280.0 / painted.get_width(), 720.0 / painted.get_height())
		add_child(bg)
	else:
		# Fallback: chão do tema (sprite lado a lado) + borda + decorações por código.
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

	# Caminho desenhado por CÓDIGO sobre os waypoints (a estrada visível é SEMPRE por
	# onde os inimigos andam — fonte única da verdade, independente da arte de fundo).
	var pc := _path_pair()
	var fill: Color = pc[1]
	var border: Color = pc[0]
	var dark := Color(border.r * 0.5, border.g * 0.5, border.b * 0.4)
	# Transição esfumada (faixa larga fraca -> média -> miolo opaco -> brilho central).
	add_child(_make_path_line(86, Color(dark.r, dark.g, dark.b, 0.22), null, -10))
	add_child(_make_path_line(66, Color(border.r, border.g, border.b, 0.85), null, -9))
	add_child(_make_path_line(50, fill, null, -8))
	add_child(_make_path_line(22, Color(fill.r * 1.08, fill.g * 1.06, fill.b * 1.04, 0.45), null, -7))

	# Portal de entrada (1º ponto) e castelo/base (último) — grampeados p/ dentro da
	# tela (o trajeto pode entrar/sair por qualquer borda), grandes, com sombra.
	var wp := _theme_path()
	var portal_pos := Vector2(clampf(wp[0].x, 36, 1244), clampf(wp[0].y, 30, 690))
	_add_shadow(portal_pos + Vector2(0, 38), 56, 20, -6)
	_add_sprite(Art.map("portal"), portal_pos, 0.46, -5)
	var castle_pos := Vector2(clampf(wp[-1].x, 40, 1240), clampf(wp[-1].y, 40, 680)) + Vector2(0, -8)
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


func _make_path_line(w: float, col: Color, tex: Texture2D, z: int) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array(_theme_path())
	l.width = w
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.z_index = z
	if tex != null:
		l.texture = tex
		l.texture_mode = Line2D.LINE_TEXTURE_TILE
	return l


func get_waypoints() -> Array:
	return _theme_path().duplicate()


func get_build_slots() -> Array:
	# Slots fixos em terreno livre (temas com caminho na arte) ou gerados ao lado.
	if SLOTS_BY_THEME.has(theme):
		return (SLOTS_BY_THEME[theme] as Array).duplicate()
	return _slots_for_path(_theme_path())


## Gera os pontos de construção AO LADO do caminho desta fase: ao longo de cada
## segmento, posiciona slots na perpendicular (alternando os lados), descartando os
## que caem fora da área jogável, sobre a UI ou perto demais de outro slot.
func _slots_for_path(path: Array) -> Array:
	var out: Array = []
	var side := 1.0
	var off := 76.0
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var seg: Vector2 = b - a
		var seg_len: float = seg.length()
		if seg_len < 70.0:
			continue
		var dir: Vector2 = seg / seg_len
		var nrm := Vector2(-dir.y, dir.x)
		var n: int = 1 if seg_len < 260.0 else 2
		for k in n:
			var t: float = float(k + 1) / float(n + 1)
			var base: Vector2 = a + seg * t
			var cand: Vector2 = base + nrm * off * side
			if not _slot_ok(cand, out):
				cand = base - nrm * off * side
			if _slot_ok(cand, out):
				out.append(cand)
			side = -side
	return out


## Slot válido: dentro da área jogável, fora dos cantos de UI e longe de outros.
func _slot_ok(p: Vector2, existing: Array) -> bool:
	if p.x < 70.0 or p.x > 1210.0 or p.y < 95.0 or p.y > 600.0:
		return false
	if p.y < 155.0 and p.x < 275.0:                      # HUD (canto sup-esq)
		return false
	if p.y > 565.0 and (p.x < 250.0 or p.x > 1035.0):    # botões (cantos inf)
		return false
	for s in existing:
		if p.distance_to(s) < 98.0:
			return false
	return true


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
	if _painted_map() == null and _ground_texture() == null:
		var wp := _theme_path()
		draw_rect(Rect2(0, 0, 1280, 720), GRASS)
		draw_circle(wp[-1], 24.0, Color(0.2, 0.7, 0.32))
		draw_circle(wp[0] + Vector2(20, 0), 9.0, Color(0.7, 0.3, 0.3))
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
