class_name ResultScreen
extends CanvasLayer

## Tela de resultado da fase: vitória/derrota, XP ganho por personagem, níveis
## subidos e personagens recém-desbloqueados. Emite continue_pressed.

signal continue_pressed

var _victory: bool = false
var _xp: int = 0
var _summary: Dictionary = {}
var _newly: Array = []
var _rewards: Dictionary = {}


func setup(victory: bool, xp: int, summary: Dictionary, newly: Array, rewards: Dictionary = {}) -> void:
	_victory = victory
	_xp = xp
	_summary = summary
	_newly = newly
	_rewards = rewards


func _ready() -> void:
	layer = 6
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.position = Vector2(64, 60)
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := Label.new()
	title.text = "VITORIA!" if _victory else "DERROTA"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if _victory else Color(0.9, 0.4, 0.4))
	box.add_child(title)

	var xp_label := Label.new()
	xp_label.text = "XP concedido ao esquadrao: +%d cada" % _xp
	box.add_child(xp_label)

	if not _rewards.is_empty():
		var rew := Label.new()
		rew.text = "Recompensas: +%d ouro, +%d essencia" % \
			[_rewards.get("gold", 0), _rewards.get("essence", 0)]
		rew.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		box.add_child(rew)
		var item_id: String = _rewards.get("item_id", "")
		if item_id != "":
			var item := EquipmentList.by_id(item_id)
			if item != null:
				var il := Label.new()
				il.text = "ITEM encontrado: %s (%s)!" % [item.display_name, EquipmentData.rarity_name(item.rarity)]
				il.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
				box.add_child(il)

	for id in _summary.keys():
		var ch := GreekRoster.by_id(id)
		var info: Dictionary = _summary[id]
		var line := Label.new()
		var name_txt: String = ch.display_name if ch != null else id
		if info["levels_gained"] > 0:
			line.text = "%s  ->  Nv %d  (+%d nivel)" % [name_txt, info["new_level"], info["levels_gained"]]
			line.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		else:
			line.text = "%s  ->  Nv %d" % [name_txt, info["new_level"]]
		box.add_child(line)

	for id in _newly:
		var ch := GreekRoster.by_id(id)
		var line := Label.new()
		line.text = "NOVO PERSONAGEM desbloqueado: %s!" % (ch.display_name if ch != null else id)
		line.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
		box.add_child(line)

	var cont := Button.new()
	cont.custom_minimum_size = Vector2(180, 38)
	cont.text = "Continuar"
	cont.pressed.connect(func(): continue_pressed.emit())
	box.add_child(cont)
