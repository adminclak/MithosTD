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
		var ch := Roster.by_id(id)
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
		box.add_child(_unlock_card(id))

	var cont := Button.new()
	cont.custom_minimum_size = Vector2(180, 38)
	cont.text = "Continuar"
	cont.pressed.connect(func(): continue_pressed.emit())
	box.add_child(cont)


## Card de destaque do herói conquistado na campanha (retrato + nome + classe).
func _unlock_card(id: String) -> PanelContainer:
	const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]
	var ch := Roster.by_id(id)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.20, 0.95)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3)
	sb.border_color = Color(1.0, 0.82, 0.35)
	sb.shadow_color = Color(1.0, 0.8, 0.3, 0.35)
	sb.shadow_size = 10
	card.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 10)
	card.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	m.add_child(hb)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(84, 84)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex := Art.hero(id)
	if tex != null:
		art.texture = tex
	hb.add_child(art)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	hb.add_child(v)
	var tag := Label.new()
	tag.text = "★ NOVO HERÓI CONQUISTADO!"
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	v.add_child(tag)
	var nm := Label.new()
	nm.text = ch.display_name if ch != null else id
	nm.add_theme_font_size_override("font_size", 26)
	var ff := UiTheme.fancy_font()
	if ff != null:
		nm.add_theme_font_override("font", ff)
	v.add_child(nm)
	if ch != null:
		var sub := Label.new()
		var el := Elements.of_character(id)
		sub.text = "%s · %s · %s" % [ch.mythology, CLASS_NAMES[ch.tower_class], Elements.name_of(el)]
		sub.add_theme_font_size_override("font_size", 14)
		sub.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		v.add_child(sub)
	return card
