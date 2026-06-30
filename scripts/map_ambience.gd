class_name MapAmbience
extends Node2D

## Vida ambiente do mapa (estilo Kingdom Rush): partículas que se mexem conforme o
## bioma — pólen na campina, vaga-lumes na floresta, névoa/bolhas no pântano,
## brasas subindo no desfiladeiro, neve caindo no Olimpo. Desenhado por código,
## acima do fundo e abaixo das unidades. Dá "movimento" sem regerar a arte.

var theme: String = "elis"
var _parts: Array = []   ## cada: {pos, vel, phase, blink, size, col}
var _t: float = 0.0
var _base_col: Color = Color(1, 1, 0.7)
var _drift: Vector2 = Vector2(14, -8)
var _blink: bool = false
var _count: int = 46


func setup(t: String) -> void:
	theme = t


func _ready() -> void:
	z_index = -3
	_config_theme()
	for i in _count:
		_parts.append(_spawn(true))
	set_process(true)


func _config_theme() -> void:
	match theme:
		"nemeia":   # floresta — vaga-lumes verdes que piscam
			_base_col = Color(0.75, 1.0, 0.45); _drift = Vector2(8, -4); _blink = true; _count = 40
		"pantano":  # pântano — névoa/bolhas pálidas subindo devagar
			_base_col = Color(0.7, 0.9, 0.85); _drift = Vector2(6, -10); _blink = false; _count = 50
		"desfiladeiro":  # garganta — brasas alaranjadas subindo
			_base_col = Color(1.0, 0.6, 0.25); _drift = Vector2(10, -22); _blink = true; _count = 44
		"olimpo":   # montanha — neve/luz caindo
			_base_col = Color(0.95, 0.97, 1.0); _drift = Vector2(-12, 26); _blink = false; _count = 60
		_:          # elis / campina — pólen claro subindo
			_base_col = Color(1.0, 0.97, 0.7); _drift = Vector2(14, -8); _blink = false; _count = 46


func _spawn(anywhere: bool) -> Dictionary:
	var pos: Vector2
	if anywhere:
		pos = Vector2(randf_range(0, 1280), randf_range(60, 700))
	else:
		# Reentra pela borda oposta ao drift.
		if _drift.y < 0:
			pos = Vector2(randf_range(0, 1280), 720 + randf_range(0, 30))
		elif _drift.y > 0:
			pos = Vector2(randf_range(0, 1280), -randf_range(0, 30))
		else:
			pos = Vector2(-20, randf_range(60, 700))
	return {
		"pos": pos,
		"vel": _drift * randf_range(0.6, 1.4) + Vector2(randf_range(-6, 6), randf_range(-3, 3)),
		"phase": randf() * TAU,
		"size": randf_range(1.4, 3.2),
		"col": _base_col,
	}


func _process(delta: float) -> void:
	_t += delta
	for p in _parts:
		p["pos"] += p["vel"] * delta
		p["pos"].x += sin(_t * 0.8 + p["phase"]) * 6.0 * delta  # vai e volta de leve
		var pos: Vector2 = p["pos"]
		if pos.x < -30 or pos.x > 1310 or pos.y < -40 or pos.y > 760:
			var np := _spawn(false)
			p["pos"] = np["pos"]; p["vel"] = np["vel"]; p["phase"] = np["phase"]
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var a := 0.55
		if _blink:
			a = 0.15 + 0.55 * (0.5 + 0.5 * sin(_t * 3.0 + p["phase"]))
		var c: Color = p["col"]
		var pos: Vector2 = p["pos"]
		var s: float = p["size"]
		draw_circle(pos, s * 1.8, Color(c.r, c.g, c.b, a * 0.25))  # halo
		draw_circle(pos, s, Color(c.r, c.g, c.b, a))
