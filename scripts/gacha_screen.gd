class_name GachaScreen
extends CanvasLayer

## Altar dos Deuses (gacha): gasta Ambrosia para invocar um personagem aleatório
## (novo = desbloqueia; repetido = fragmentos). Emite closed para voltar ao Hub.

signal closed

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
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.position = Vector2(80, 80)
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "ALTAR DOS DEUSES"
	title.add_theme_font_size_override("font_size", 38)
	box.add_child(title)

	_ambrosia_lbl = Label.new()
	_ambrosia_lbl.add_theme_font_size_override("font_size", 22)
	_ambrosia_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	box.add_child(_ambrosia_lbl)

	var roll := Button.new()
	roll.custom_minimum_size = Vector2(280, 48)
	roll.text = "Invocar  (%d Ambrosia)" % Progression.GACHA_COST
	roll.pressed.connect(_on_roll)
	box.add_child(roll)

	_result = Label.new()
	_result.add_theme_font_size_override("font_size", 26)
	_result.custom_minimum_size = Vector2(600, 80)
	box.add_child(_result)

	var info := Label.new()
	info.text = "Novo heroi = desbloqueado. Repetido = fragmentos (evoluem estrelas)."
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	box.add_child(info)

	var back := Button.new()
	back.custom_minimum_size = Vector2(160, 38)
	back.text = "Voltar"
	back.pressed.connect(func(): closed.emit())
	box.add_child(back)

	_refresh()


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
