class_name Hud
extends CanvasLayer

## HUD da partida: vida da base, ouro e onda (num painel no canto) + a mensagem
## central de vitória/derrota.

var _hp_label: Label
var _gold_label: Label
var _wave_label: Label
var _center_label: Label


func _ready() -> void:
	layer = 7

	var bg := ColorRect.new()
	bg.position = Vector2(12, 12)
	bg.size = Vector2(232, 98)
	bg.color = Color(0.0, 0.0, 0.0, 0.42)
	add_child(bg)

	_hp_label = _mk(Vector2(24, 18), Color(1.0, 0.5, 0.5))
	_gold_label = _mk(Vector2(24, 46), Color(1.0, 0.85, 0.32))
	_wave_label = _mk(Vector2(24, 74), Color(0.82, 0.9, 1.0))

	_center_label = Label.new()
	_center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.add_theme_font_size_override("font_size", 72)
	_center_label.text = ""
	add_child(_center_label)

	_update_hp(GameState.base_hp)
	_update_gold(GameState.gold)
	_wave_label.text = "Onda: -/-"

	GameState.base_hp_changed.connect(_update_hp)
	GameState.gold_changed.connect(_update_gold)
	GameState.wave_changed.connect(_update_wave)
	GameState.game_over.connect(_on_game_over)


func _mk(pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l


func _update_hp(hp: int) -> void:
	_hp_label.text = "Vida: %d" % hp


func _update_gold(gold: int) -> void:
	_gold_label.text = "Ouro: %d" % gold


func _update_wave(current: int, total: int) -> void:
	_wave_label.text = "Onda: %d/%d" % [current, total]


func _on_game_over(victory: bool) -> void:
	_center_label.text = "VITORIA!" if victory else "DERROTA!"
	_center_label.add_theme_color_override("font_color", \
		Color(0.45, 0.95, 0.5) if victory else Color(0.95, 0.4, 0.4))
