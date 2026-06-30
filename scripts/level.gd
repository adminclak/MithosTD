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
	# Elis: a arte tem um ANEL de terra (oval) em volta do gramado central. Os inimigos
	# seguem a oval — portal no topo, castelo embaixo, dois arcos (ver MULTI). Esta é a
	# rota principal (arco direito/horário). Traçado sobre a terra pintada.
	"elis": [
		Vector2(560, 178), Vector2(770, 186), Vector2(950, 230), Vector2(1078, 340),
		Vector2(1045, 472), Vector2(872, 556), Vector2(620, 588),
	],
	# Nemeia: TRILHA de terra em S — desce do topo (~x420) mantendo-se à esquerda no
	# miolo e curva para a direita embaixo. Traçado SOBRE a terra pintada (portal no
	# topo, castelo no fim visível da trilha, acima da barra).
	"nemeia": [
		Vector2(420, 118), Vector2(440, 214), Vector2(462, 304), Vector2(478, 382),
		Vector2(528, 458), Vector2(600, 528), Vector2(655, 592),
	],
	# Pântano: campo de lama aberto com um LAGO central (intransponível). A rota entra
	# pela esquerda e CONTORNA o lago pela borda inferior/direita (nunca pela água).
	"pantano": [
		Vector2(-40, 415), Vector2(185, 405), Vector2(265, 520), Vector2(430, 588),
		Vector2(655, 602), Vector2(850, 545), Vector2(955, 405), Vector2(985, 285),
		Vector2(1150, 250), Vector2(1330, 248),
	],
	# Desfiladeiro: estrada DESENHADA atravessando o pátio de basalto aberto (entra no
	# topo-esquerda, passa por baixo do altar central e sai embaixo). Caminho claro e
	# bem visível; os heróis posicionam no basalto ao lado.
	"desfiladeiro": [
		Vector2(280, 210), Vector2(380, 360), Vector2(520, 462), Vector2(720, 480),
		Vector2(880, 442), Vector2(820, 560), Vector2(720, 596),
	],
	# Olimpo: planalto nevado com templo (topo-dir), praça/fonte (centro-esq) e piscina
	# (centro-dir). A rota desce pela neve aberta CONTORNANDO o templo e a piscina pela
	# direita — portal no canto superior-direito, castelo embaixo. Caminho único.
	"olimpo": [
		Vector2(1180, 140), Vector2(1090, 300), Vector2(1075, 450), Vector2(1045, 560),
		Vector2(820, 605), Vector2(580, 610),
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
	# Elis: a oval de terra da arte vira bifurcação NATURAL. Portal no topo da oval,
	# castelo embaixo; os inimigos contornam o gramado pelos dois lados (arco direito
	# e arco esquerdo) e convergem no castelo. Traçado sobre a terra pintada.
	"elis": [
		# arco DIREITO (horário): topo -> direita -> baixo
		[Vector2(560, 178), Vector2(770, 186), Vector2(950, 230), Vector2(1078, 340),
			Vector2(1045, 472), Vector2(872, 556), Vector2(620, 588)],
		# arco ESQUERDO (anti-horário): topo -> esquerda -> baixo
		[Vector2(560, 178), Vector2(350, 196), Vector2(220, 256), Vector2(170, 362),
			Vector2(216, 466), Vector2(370, 558), Vector2(620, 588)],
	],
}

# Temas cujo CAMINHO já está PINTADO na arte do mapa (estilo Kingdom Rush) E cujos
# waypoints foram TRAÇADOS sobre essa trilha. Nesses NÃO desenhamos a estrada por
# código — os inimigos andam direto na terra pintada (visual 100% integrado). Os
# demais mapas ainda usam a estrada-código até serem traçados sobre a arte.
const PATH_IN_ART := {
	"elis": true,    # oval de terra clara na arte — inimigos andam direto nela
	"nemeia": true,  # trilha de terra clara na arte
	# pantano/desfiladeiro/olimpo: NÃO têm estrada pintada clara, então DESENHAMOS uma
	# estrada nítida (por área aberta) para o caminho ficar óbvio (saber onde posicionar).
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
	"pantano": [
		Rect2(465, 205, 375, 360),    # lago central (água profunda) — não dá p/ construir
	],
	"desfiladeiro": [
		Rect2(650, 16, 210, 196),     # torre de vigia (topo-centro)
		Rect2(946, 446, 176, 176),    # poço/estrutura (canto inferior-direito)
		Rect2(560, 264, 188, 150),    # altar/braseiro central
	],
	"olimpo": [
		Rect2(700, 70, 335, 230),     # templo grande (topo-direita)
		Rect2(245, 310, 150, 140),    # santuário/colunas (esquerda)
		Rect2(355, 300, 340, 275),    # praça murada + fonte (centro-esquerda)
		Rect2(748, 422, 275, 175),    # piscina/banho (centro-direita)
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
	# Desenhados (estes 3): terra/areia bonita que combina com o bioma e dá contraste.
	"pantano": [Color(0.33, 0.25, 0.16), Color(0.55, 0.44, 0.29)],       # lama marrom
	"desfiladeiro": [Color(0.42, 0.33, 0.22), Color(0.70, 0.58, 0.40)],  # areia s/ basalto escuro
	"olimpo": [Color(0.58, 0.50, 0.38), Color(0.84, 0.76, 0.60)],        # pedra/areia clara na neve
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
	# Mapas com a estrada PINTADA na arte (PATH_IN_ART): não desenhamos nada por cima —
	# os inimigos seguem a terra pintada. Os demais ganham a faixa por código.
	if not PATH_IN_ART.get(theme, false):
		for route in paths:
			# Transição esfumada (faixa larga fraca -> média -> miolo opaco -> brilho central).
			add_child(_make_path_line(route, 86, Color(dark.r, dark.g, dark.b, 0.22), null, -10))
			add_child(_make_path_line(route, 66, Color(border.r, border.g, border.b, 0.85), null, -9))
			add_child(_make_path_line(route, 50, fill, null, -8))
			add_child(_make_path_line(route, 22, Color(fill.r * 1.08, fill.g * 1.06, fill.b * 1.04, 0.45), null, -7))

	# Portal por ENTRADA distinta (1º ponto de cada rota) e UM castelo no destino
	# comum (último ponto da rota principal). Tudo grampeado p/ dentro da tela.
	# Portal/castelo grampeados ACIMA da barra de heróis (y<=600) p/ nunca saírem da
	# tela / ficarem escondidos atrás da barra de baixo.
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
		var portal_pos := Vector2(clampf(e.x, 36, 1244), clampf(e.y, 30, 600))
		_add_shadow(portal_pos + Vector2(0, 38), 56, 20, -6)
		_add_sprite(Art.map("portal"), portal_pos, 0.46, -5)
	var wp: Array = paths[0]
	var castle_pos := Vector2(clampf(wp[-1].x, 40, 1240), clampf(wp[-1].y, 40, 596)) + Vector2(0, -8)
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
