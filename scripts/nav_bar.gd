class_name NavBar
extends Control

## Barra de navegação inferior (estilo mobile) — PADRÃO reutilizável em todas as telas.
## Abas com ícone desenhado + rótulo; a aba ativa fica destacada. Emite selected(id).
## Uso: var nav := NavBar.new(); nav.setup([{id,label,icon}, ...], "herois");
##      add_child(nav); nav.selected.connect(_on_nav)

signal selected(id: String)

const BAR_H := 92.0
const GOLD := Color(0.95, 0.78, 0.32)

## Abas PADRÃO do jogo (a mesma barra em todas as telas). id casa com main._goto_section.
const MAIN_TABS := [
	{"id": "herois", "label": "Herois", "icon": "herois"},
	{"id": "equip", "label": "Equipar", "icon": "equip"},
	{"id": "bestiario", "label": "Bestiario", "icon": "bestiario"},
	{"id": "loja", "label": "Loja", "icon": "loja"},
	{"id": "missoes", "label": "Missoes", "icon": "missoes"},
	{"id": "altar", "label": "Altar", "icon": "altar"},
	{"id": "bencaos", "label": "Bencaos", "icon": "bencaos"},
]

var _tabs: Array = []     ## [{id, label, icon}]
var _active: String = ""
var _hover: int = -1


func setup(tabs: Array, active_id: String = "") -> void:
	_tabs = tabs
	_active = active_id


func _ready() -> void:
	position = Vector2(0, 720.0 - BAR_H)
	size = Vector2(1280, BAR_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func _process(_dt: float) -> void:
	var mp := get_local_mouse_position()
	var h := -1
	if mp.y >= 0 and mp.x >= 0 and mp.x < size.x:
		h = int(mp.x / (size.x / max(1, _tabs.size())))
	if h != _hover:
		_hover = h
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := int((event as InputEventMouseButton).position.x / (size.x / max(1, _tabs.size())))
		if i >= 0 and i < _tabs.size():
			_active = _tabs[i]["id"]
			queue_redraw()
			selected.emit(_active)


func _draw() -> void:
	# Fundo da barra (madeira escura) + traço dourado no topo.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.09, 0.06, 0.97))
	draw_rect(Rect2(Vector2(0, 0), Vector2(size.x, 3)), GOLD)
	var n := _tabs.size()
	if n == 0:
		return
	var tw := size.x / n
	var font := _font()
	for i in n:
		var t: Dictionary = _tabs[i]
		var is_active: bool = t["id"] == _active
		var is_hover: bool = i == _hover
		var cx := tw * (i + 0.5)
		# Destaque da aba ativa (placa dourada) / hover (leve).
		if is_active:
			var hl := StyleBoxFlat.new()
			var r := Rect2(Vector2(tw * i + 4, 6), Vector2(tw - 8, BAR_H - 12))
			draw_rect(r, Color(0.95, 0.78, 0.32, 0.18))
			draw_rect(r, GOLD, false, 2.0)
		elif is_hover:
			draw_rect(Rect2(Vector2(tw * i + 4, 6), Vector2(tw - 8, BAR_H - 12)), Color(1, 1, 1, 0.06))
		var icol := GOLD if (is_active or is_hover) else Color(0.78, 0.72, 0.60)
		_draw_icon(t.get("icon", ""), Vector2(cx, 32), 15.0, icol)
		var label: String = t["label"]
		var tcol := Color(1.0, 0.95, 0.78) if (is_active or is_hover) else Color(0.80, 0.76, 0.66)
		if font != null:
			var fs := 15
			var tsize := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(font, Vector2(cx - tsize.x * 0.5, 70), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tcol)


func _font() -> Font:
	if UiTheme.body_font() != null:
		return UiTheme.body_font()
	return ThemeDB.fallback_font


## Ícones simples desenhados por código (sem depender de assets).
func _draw_icon(kind: String, c: Vector2, r: float, col: Color) -> void:
	match kind:
		"herois":   # espada
			draw_line(c + Vector2(-r * 0.7, r), c + Vector2(r * 0.7, -r), col, 3.0)
			draw_line(c + Vector2(-r * 0.4, r * 0.3), c + Vector2(r * 0.2, r), col, 3.0) # guarda
		"equip":    # escudo
			var pts := PackedVector2Array([c + Vector2(-r, -r * 0.8), c + Vector2(r, -r * 0.8),
				c + Vector2(r, r * 0.3), c + Vector2(0, r), c + Vector2(-r, r * 0.3)])
			draw_polyline(pts + PackedVector2Array([pts[0]]), col, 2.5)
		"bestiario":  # livro
			draw_rect(Rect2(c + Vector2(-r, -r * 0.8), Vector2(r * 2, r * 1.6)), col, false, 2.5)
			draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.8), col, 2.0)
		"loja":     # moeda
			draw_arc(c, r, 0, TAU, 24, col, 2.5)
			if _font() != null:
				draw_string(_font(), c + Vector2(-r * 0.45, r * 0.5), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 1.6), col)
		"missoes":  # pergaminho c/ check
			draw_rect(Rect2(c + Vector2(-r * 0.8, -r), Vector2(r * 1.6, r * 2)), col, false, 2.5)
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.4, 0), c + Vector2(-r * 0.05, r * 0.4), c + Vector2(r * 0.5, -r * 0.4)]), col, 2.5)
		"altar":    # estrela
			_draw_star(c, r, col)
		"bencaos":  # raio / louro
			draw_polyline(PackedVector2Array([c + Vector2(r * 0.2, -r), c + Vector2(-r * 0.3, r * 0.1),
				c + Vector2(r * 0.1, r * 0.1), c + Vector2(-r * 0.2, r)]), col, 3.0)
		_:
			draw_arc(c, r, 0, TAU, 20, col, 2.5)


func _draw_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2 + i * PI / 5
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	pts.append(pts[0])
	draw_polyline(pts, col, 2.2)
