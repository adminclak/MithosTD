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
		Vector2(-40, 215), Vector2(210, 245), Vector2(420, 320), Vector2(600, 380),
		Vector2(780, 325), Vector2(945, 250), Vector2(1055, 360), Vector2(1115, 500),
		Vector2(1150, 590), Vector2(1330, 615),
	],
	# Nemeia: caminho horizontal ondulado, da borda esquerda à direita (centro aberto).
	"nemeia": [
		Vector2(-40, 320), Vector2(230, 290), Vector2(450, 380), Vector2(660, 320),
		Vector2(880, 390), Vector2(1080, 330), Vector2(1330, 360),
	],
	# Pântano: sobe em S da esquerda-baixo até a direita (centro aberto).
	"pantano": [
		Vector2(-40, 610), Vector2(210, 560), Vector2(400, 450), Vector2(580, 500),
		Vector2(770, 380), Vector2(980, 330), Vector2(1330, 310),
	],
	# Desfiladeiro (garganta vulcânica): entra no topo e desce curvando até a direita.
	"desfiladeiro": [
		Vector2(300, -40), Vector2(330, 180), Vector2(470, 330), Vector2(680, 290),
		Vector2(860, 380), Vector2(1040, 320), Vector2(1330, 350),
	],
	# Olimpo: entra à esquerda e sobe até o canto superior-direito (centro aberto).
	"olimpo": [
		Vector2(-40, 470), Vector2(230, 450), Vector2(450, 370), Vector2(670, 410),
		Vector2(880, 290), Vector2(1080, 220), Vector2(1330, 190),
	],
}
const DEFAULT_PATH := [Vector2(-40, 160), Vector2(360, 160), Vector2(360, 420),
	Vector2(760, 420), Vector2(760, 180), Vector2(1040, 180), Vector2(1040, 520),
	Vector2(1240, 520)]

# Mapas com MÚLTIPLOS caminhos até o castelo (bifurcações, estilo Kingdom Rush). A
# 1ª rota de cada lista É IGUAL ao PATHS_BY_THEME (rota principal); a 2ª compartilha
# a entrada e o castelo, mas faz um trajeto alternativo pelo miolo — então o castelo
# recebe inimigos por dois lados. Os inimigos são distribuídos entre as rotas. Mapas
# fora deste dict têm um único caminho (get_paths devolve [caminho único]).
const MULTI_PATHS_BY_THEME := {
	# Elis: a estrada se abre em duas após a 3ª curva — rota de cima (principal) e
	# rota de baixo pelo centro — e as duas se juntam de novo perto do castelo.
	"elis": [
		[Vector2(-40, 215), Vector2(210, 245), Vector2(420, 320), Vector2(600, 380),
			Vector2(780, 325), Vector2(945, 250), Vector2(1055, 360), Vector2(1115, 500),
			Vector2(1150, 590), Vector2(1330, 615)],
		[Vector2(-40, 215), Vector2(210, 245), Vector2(420, 320), Vector2(600, 470),
			Vector2(800, 545), Vector2(1000, 505), Vector2(1115, 500), Vector2(1150, 590),
			Vector2(1330, 615)],
	],
	# Nemeia: a partir da 2ª curva uma rota sobe (arco superior) e a outra desce
	# (rota principal ondulada); ambas chegam ao mesmo castelo à direita.
	"nemeia": [
		[Vector2(-40, 320), Vector2(230, 290), Vector2(450, 380), Vector2(660, 320),
			Vector2(880, 390), Vector2(1080, 330), Vector2(1330, 360)],
		[Vector2(-40, 320), Vector2(230, 290), Vector2(450, 230), Vector2(660, 200),
			Vector2(880, 240), Vector2(1080, 300), Vector2(1330, 360)],
	],
}

# Temas cujo CAMINHO já está PINTADO na arte do mapa (estilo Kingdom Rush). Nesses
# não desenhamos a faixa de caminho por código — o trajeto só segue a trilha da arte.
const PATH_IN_ART := {
	"elis": true, "nemeia": true, "pantano": true, "desfiladeiro": true, "olimpo": true,
}

# Pontos de torre: gerados automaticamente AO LADO da trilha (perpendicular a cada
# segmento, alternando os lados) por _slots_for_path, acompanhando o caminho traçado.
const SLOTS_BY_THEME := {}

# Zonas SÓLIDAS de cada mapa (templos, torres, muralhas, água) onde NÃO se pode
# posicionar herói — assim ninguém fica "em cima de uma parede". São retângulos
# autorais sobre as estruturas pintadas na arte (coords de tela 1280x720). Mapas de
# centro aberto (elis/nemeia) não precisam — a estrutura fica nas bordas, fora da
# faixa de construção. Conservador de propósito: melhor bloquear um pouco a mais
# perto de um prédio do que deixar um herói flutuando sobre ele.
const BLOCKED_BY_THEME := {
	# Pântano é lama (não parede/água profunda) — centro fica livre p/ construir.
	"desfiladeiro": [
		Rect2(650, 16, 210, 196),     # torre de vigia (topo-centro)
		Rect2(946, 446, 176, 176),    # poço/estrutura (canto inferior-direito)
	],
	"olimpo": [
		Rect2(684, 64, 210, 168),     # templo grego (centro-direita)
		Rect2(984, 64, 168, 156),     # santuário menor (topo-direita)
		Rect2(770, 416, 348, 224),    # ruínas/piscina (canto inferior-direito)
	],
}

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

	# Caminho(s) desenhado(s) por CÓDIGO sobre os waypoints (a estrada visível é SEMPRE
	# por onde os inimigos andam — fonte única da verdade). Mapas com bifurcação têm
	# mais de uma rota; cada uma é pintada (os trechos compartilhados se sobrepõem).
	var pc := _path_pair()
	var fill: Color = pc[1]
	var border: Color = pc[0]
	var dark := Color(border.r * 0.5, border.g * 0.5, border.b * 0.4)
	var paths := get_paths()
	for route in paths:
		# Transição esfumada (faixa larga fraca -> média -> miolo opaco -> brilho central).
		add_child(_make_path_line(route, 86, Color(dark.r, dark.g, dark.b, 0.22), null, -10))
		add_child(_make_path_line(route, 66, Color(border.r, border.g, border.b, 0.85), null, -9))
		add_child(_make_path_line(route, 50, fill, null, -8))
		add_child(_make_path_line(route, 22, Color(fill.r * 1.08, fill.g * 1.06, fill.b * 1.04, 0.45), null, -7))

	# Portal por ENTRADA distinta (1º ponto de cada rota) e UM castelo no destino
	# comum (último ponto da rota principal). Tudo grampeado p/ dentro da tela.
	var seen_entries: Array = []
	for route in paths:
		var e: Vector2 = route[0]
		var dup := false
		for s in seen_entries:
			if (s as Vector2).distance_to(e) < 40.0:
				dup = true
				break
		if dup:
			continue
		seen_entries.append(e)
		var portal_pos := Vector2(clampf(e.x, 36, 1244), clampf(e.y, 30, 690))
		_add_shadow(portal_pos + Vector2(0, 38), 56, 20, -6)
		_add_sprite(Art.map("portal"), portal_pos, 0.46, -5)
	var wp: Array = paths[0]
	var castle_pos := Vector2(clampf(wp[-1].x, 40, 1240), clampf(wp[-1].y, 40, 680)) + Vector2(0, -8)
	_add_shadow(castle_pos + Vector2(0, 56), 80, 28, -2)
	_add_sprite(Art.map("castle"), castle_pos, 0.70, -1)

	# Vida ambiente (partículas que se mexem conforme o bioma).
	var amb := MapAmbience.new()
	amb.setup(theme)
	add_child(amb)
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


func _make_path_line(points: Array, w: float, col: Color, tex: Texture2D, z: int) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array(points)
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


## TODAS as rotas dos inimigos (1+). Mapas com bifurcação devolvem várias; os demais,
## uma só. A rota 0 é sempre a principal (= get_waypoints).
func get_paths() -> Array:
	if MULTI_PATHS_BY_THEME.has(theme):
		var out: Array = []
		for p in MULTI_PATHS_BY_THEME[theme]:
			out.append((p as Array).duplicate())
		return out
	return [_theme_path().duplicate()]


## Retângulos sólidos (estruturas) onde NÃO se pode posicionar herói neste mapa.
func get_blocked_zones() -> Array:
	return (BLOCKED_BY_THEME.get(theme, []) as Array).duplicate()


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
