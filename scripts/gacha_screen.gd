class_name GachaScreen
extends CanvasLayer

## Altar dos Deuses (gacha): gasta Ambrosia para invocar um personagem aleatório
## (novo = desbloqueia; repetido = fragmentos). Emite closed para voltar ao Hub.

signal closed
signal section_selected(id: String)

const RARITY_COLORS := {
	0: Color(0.8, 0.8, 0.8),   # Comum
	1: Color(0.4, 0.7, 1.0),   # Raro
	2: Color(0.8, 0.5, 1.0),   # Epico
	3: Color(1.0, 0.8, 0.3),   # Lendario
}

var _ambrosia_lbl: Label
var _result: Label


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.08, 0.40)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	add_child(_clabel("ALTAR DOS DEUSES", Vector2(0, 60), 1280, 40, Color(1.0, 0.9, 0.5), true))
	add_child(_clabel("Invoque heróis com a bênção dos deuses", Vector2(0, 116), 1280, 18, Color(0.9, 0.85, 0.72)))

	# Card central (pergaminho) com o altar.
	var card := Panel.new()
	card.position = Vector2(400, 168)
	card.size = Vector2(480, 384)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.10, 0.07, 0.95)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.85, 0.66, 0.30)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	add_child(card)

	# Emblema do altar (estrela dourada desenhada).
	var emblem := _AltarEmblem.new()
	emblem.position = Vector2(640, 250)
	add_child(emblem)

	_ambrosia_lbl = _clabel("", Vector2(400, 322), 480, 22, Color(1.0, 0.82, 0.4))
	add_child(_ambrosia_lbl)

	var roll := _gold_btn("INVOCAR  (%d Ambrosia)" % Progression.GACHA_COST, 24)
	roll.position = Vector2(470, 366)
	roll.size = Vector2(340, 58)
	roll.pressed.connect(_on_roll)
	add_child(roll)

	_result = _clabel("", Vector2(400, 440), 480, 24, Color.WHITE)
	add_child(_result)

	add_child(_clabel("Novo herói = desbloqueado · Repetido = fragmentos (evoluem estrelas)",
		Vector2(0, 568), 1280, 15, Color(0.72, 0.70, 0.64)))

	NavBar.add_to(self, "altar", func(id): section_selected.emit(id), func(): closed.emit())
	_refresh()


func _clabel(text: String, pos: Vector2, width: int, fsize: int, col: Color, fancy: bool = false) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(width, fsize + 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fancy:
		var ff := UiTheme.fancy_font()
		if ff != null:
			l.add_theme_font_override("font", ff)
	return l


func _gold_btn(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	var mk := func(top: Color, bot: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bot.lerp(top, 0.5)
		s.set_corner_radius_all(11)
		s.set_border_width_all(3)
		s.border_color = border
		s.set_content_margin_all(8)
		return s
	b.add_theme_stylebox_override("normal", mk.call(Color(0.97, 0.80, 0.34), Color(0.76, 0.54, 0.16), Color(1.0, 0.93, 0.62)))
	b.add_theme_stylebox_override("hover", mk.call(Color(1.0, 0.88, 0.46), Color(0.84, 0.62, 0.22), Color(1.0, 0.97, 0.74)))
	b.add_theme_stylebox_override("pressed", mk.call(Color(0.80, 0.62, 0.22), Color(0.6, 0.43, 0.13), Color(0.95, 0.86, 0.52)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(0.22, 0.12, 0.02))
	return b


## Emblema do altar (estrela dourada com brilho) desenhado por código.
class _AltarEmblem extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 58, Color(1.0, 0.85, 0.4, 0.12))
		draw_circle(Vector2.ZERO, 44, Color(1.0, 0.85, 0.4, 0.16))
		var pts := PackedVector2Array()
		for i in 10:
			var ang := -PI / 2 + i * PI / 5
			var rad := 46.0 if i % 2 == 0 else 20.0
			pts.append(Vector2(cos(ang), sin(ang)) * rad)
		pts.append(pts[0])
		draw_colored_polygon(pts, Color(0.95, 0.78, 0.34))
		draw_polyline(pts, Color(1.0, 0.93, 0.6), 2.0)


func _on_roll() -> void:
	var r := Progression.gacha_roll()
	if not r.get("ok", false):
		_result.text = "Ambrosia insuficiente!"
		_result.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		return
	var ch := Roster.by_id(r["id"])
	var nm: String = ch.display_name if ch != null else r["id"]
	var col: Color = RARITY_COLORS.get(r["rarity"], Color.WHITE)
	if r["is_new"]:
		_result.text = "NOVO HEROI!\n%s  (%s)" % [nm, Roster.rarity_name(r["rarity"])]
	else:
		_result.text = "%s (repetido)\n+%d fragmentos" % [nm, r["fragments"]]
	_result.add_theme_color_override("font_color", col)
	Progression.save_game()
	_refresh()


func _refresh() -> void:
	_ambrosia_lbl.text = "Ambrosia: %d" % Progression.ambrosia
