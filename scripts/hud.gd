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

	# Painel com moldura arredondada + borda dourada (estilo Kingdom Rush).
	var panel := Panel.new()
	panel.position = Vector2(12, 12)
	panel.size = Vector2(236, 104)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.13, 0.78)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.86, 0.70, 0.34)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_hp_label = _mk(Vector2(24, 18), Color(1.0, 0.55, 0.55))
	_gold_label = _mk(Vector2(24, 47), Color(1.0, 0.86, 0.36))
	_wave_label = _mk(Vector2(24, 76), Color(0.82, 0.9, 1.0))

	_center_label = Label.new()
	_center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.add_theme_font_size_override("font_size", 72)
	_center_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_center_label.add_theme_constant_override("shadow_offset_x", 3)
	_center_label.add_theme_constant_override("shadow_offset_y", 4)
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
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	add_child(l)
	return l


func _update_hp(hp: int) -> void:
	_hp_label.text = "❤ Vida: %d" % hp


func _update_gold(gold: int) -> void:
	_gold_label.text = "⛁ Ouro: %d" % gold


func _update_wave(current: int, total: int) -> void:
	_wave_label.text = "⚔ Onda: %d/%d" % [current, total]


func _on_game_over(victory: bool) -> void:
	_center_label.text = "VITORIA!" if victory else "DERROTA!"
	_center_label.add_theme_color_override("font_color", \
		Color(0.45, 0.95, 0.5) if victory else Color(0.95, 0.4, 0.4))
