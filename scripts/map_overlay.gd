class_name MapOverlay
extends Node2D

## Desenha os marcadores das fases no mapa-múndi: disco dourado (liberada) ou
## cinza (bloqueada), o número da fase e 3 estrelas de conquista acima (estilo
## Kingdom Rush). Os cliques ficam em Buttons transparentes por cima.

var nodes: Array = [] ## [{pos:Vector2, idx:int, state:int, stars:int}] state: 0=lock 1=next 2=clear
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for n in nodes:
		var p: Vector2 = n["pos"]
		var st: int = n["state"]
		# Sombra + disco.
		draw_circle(p + Vector2(0, 4), 30.0, Color(0, 0, 0, 0.35))
		var face: Color
		var border: Color
		match st:
			2: face = Color(0.95, 0.78, 0.30); border = Color(0.45, 0.30, 0.08) # concluída (ouro)
			1: face = Color(0.55, 0.85, 1.0); border = Color(0.12, 0.30, 0.5)   # próxima (azul)
			_: face = Color(0.4, 0.4, 0.45); border = Color(0.2, 0.2, 0.24)     # bloqueada
		# Pulso na próxima fase.
		var r := 28.0
		if st == 1:
			r += sin(_t * 4.0) * 2.5
		draw_circle(p, r, face)
		draw_arc(p, r, 0.0, TAU, 32, border, 4.0)
		draw_circle(p - Vector2(r * 0.35, r * 0.35), r * 0.32, Color(1, 1, 1, 0.25)) # brilho
		# Número.
		var label := str(n["idx"]) if st != 0 else "?"
		draw_string(font, p + Vector2(-9, 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28,
			Color(0.2, 0.15, 0.05) if st == 2 else Color(1, 1, 1))
		# 3 estrelas de conquista acima (preenchidas = conquistadas na fase).
		var earned: int = n.get("stars", 0)
		for s in 3:
			var sp := p + Vector2((s - 1) * 20.0, -r - 16.0)
			_star(sp, 9.0, 4.0, s < earned)


func _star(c: Vector2, ro: float, ri: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rr := ro if i % 2 == 0 else ri
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	if filled:
		draw_colored_polygon(pts, Color(1.0, 0.9, 0.3))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.5, 0.35, 0.05), 1.5)
	else:
		draw_colored_polygon(pts, Color(0.15, 0.15, 0.2, 0.5))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.6, 0.6, 0.65), 1.2)
