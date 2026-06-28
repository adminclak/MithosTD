class_name Hud
extends CanvasLayer

var _hp_label: Label
var _gold_label: Label
var _wave_label: Label
var _center_label: Label

func _ready() -> void:
	_hp_label = Label.new()
	_hp_label.position = Vector2(20, 16)
	add_child(_hp_label)

	_gold_label = Label.new()
	_gold_label.position = Vector2(20, 44)
	add_child(_gold_label)

	_wave_label = Label.new()
	_wave_label.position = Vector2(20, 72)
	add_child(_wave_label)

	_center_label = Label.new()
	_center_label.position = Vector2(480, 300)
	_center_label.add_theme_font_size_override("font_size", 64)
	_center_label.text = ""
	add_child(_center_label)

	_update_hp(GameState.base_hp)
	_update_gold(GameState.gold)
	_wave_label.text = "Onda: -/-"

	GameState.base_hp_changed.connect(_update_hp)
	GameState.gold_changed.connect(_update_gold)
	GameState.wave_changed.connect(_update_wave)
	GameState.game_over.connect(_on_game_over)

func _update_hp(hp: int) -> void:
	_hp_label.text = "Vida: %d" % hp

func _update_gold(gold: int) -> void:
	_gold_label.text = "Ouro: %d" % gold

func _update_wave(current: int, total: int) -> void:
	_wave_label.text = "Onda: %d/%d" % [current, total]

func _on_game_over(victory: bool) -> void:
	_center_label.text = "VITORIA!" if victory else "DERROTA!"
