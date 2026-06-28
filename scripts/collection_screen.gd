class_name CollectionScreen
extends CanvasLayer

## Coleção + Loja: equipar Arma/Relíquia nos personagens, evoluir estrela
## (gastando Essência + ouro meta) e comprar itens. Reconstrói a tela a cada
## ação e persiste o progresso. Emite closed para voltar ao Hub.

signal closed

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]
const STAR := "*"

var _root: ScrollContainer
var _box: VBoxContainer


func _ready() -> void:
	layer = 5
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_root = ScrollContainer.new()
	_root.position = Vector2(40, 24)
	_root.custom_minimum_size = Vector2(1200, 670)
	add_child(_root)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_root.add_child(_box)

	_rebuild()


func _rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "COLECAO / LOJA"
	title.add_theme_font_size_override("font_size", 30)
	_box.add_child(title)

	var res := Label.new()
	res.text = "Ouro meta: %d    Essencia: %d" % [Progression.meta_gold, Progression.meta_essence]
	res.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_box.add_child(res)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 48)
	_box.add_child(cols)

	cols.add_child(_build_characters())
	cols.add_child(_build_shop())
	cols.add_child(_build_character_shop())

	var back := Button.new()
	back.custom_minimum_size = Vector2(160, 36)
	back.text = "Voltar"
	back.pressed.connect(func(): closed.emit())
	_box.add_child(back)


func _build_characters() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var head := Label.new()
	head.text = "Personagens"
	head.add_theme_font_size_override("font_size", 22)
	col.add_child(head)

	for id in Progression.unlocked_ids():
		var ch := Roster.by_id(id)
		var panel := PanelContainer.new()
		var v := VBoxContainer.new()
		panel.add_child(v)

		var name_lbl := Label.new()
		name_lbl.text = "%s  (%s)  Nv %d  %s  | Frag: %d" % [ch.display_name, \
			CLASS_NAMES[ch.tower_class], Progression.level_of(id), \
			STAR.repeat(Progression.stars_of(id)), Progression.fragments_of(id)]
		v.add_child(name_lbl)

		var slots := HBoxContainer.new()
		slots.add_theme_constant_override("separation", 6)
		slots.add_child(_slot_button(id, EquipmentData.Slot.WEAPON, "Arma"))
		slots.add_child(_slot_button(id, EquipmentData.Slot.RELIC, "Reliquia"))
		v.add_child(slots)

		var evo := Button.new()
		evo.custom_minimum_size = Vector2(260, 30)
		var cost := Progression.evolve_cost(id)
		if cost.is_empty():
			evo.text = "Evolucao maxima"
			evo.disabled = true
		else:
			evo.text = "Evoluir (%d frag + %d ouro)" % [cost["frag"], cost["gold"]]
			evo.disabled = not Progression.can_evolve(id)
			evo.pressed.connect(_on_evolve.bind(id))
		v.add_child(evo)

		col.add_child(panel)
	return col


func _slot_button(char_id: String, slot: int, slot_label: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 28)
	var cur: String = Progression.equipped_ids(char_id).get("weapon" if slot == EquipmentData.Slot.WEAPON else "relic", "")
	var item := EquipmentList.by_id(cur) if cur != "" else null
	b.text = "%s: %s" % [slot_label, (item.display_name if item != null else "-")]
	b.pressed.connect(_on_cycle_slot.bind(char_id, slot))
	return b


func _build_shop() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var head := Label.new()
	head.text = "Loja (itens)"
	head.add_theme_font_size_override("font_size", 22)
	col.add_child(head)

	for item in EquipmentList.all():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(230, 0)
		lbl.text = "%s (%s)" % [item.display_name, EquipmentData.rarity_name(item.rarity)]
		row.add_child(lbl)
		var buy := Button.new()
		buy.custom_minimum_size = Vector2(120, 28)
		if Progression.owns_item(item.id):
			buy.text = "Possui"
			buy.disabled = true
		else:
			var price := EquipmentList.price(item.rarity)
			buy.text = "Comprar %d" % price
			buy.disabled = Progression.meta_gold < price
			buy.pressed.connect(_on_buy.bind(item.id))
		row.add_child(buy)
		col.add_child(row)
	return col


func _build_character_shop() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var head := Label.new()
	head.text = "Recrutar herois (Ambrosia: %d)" % Progression.ambrosia
	head.add_theme_font_size_override("font_size", 22)
	col.add_child(head)
	for d in Roster.defs():
		var id: String = d[0]
		if Progression.is_unlocked(id):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(230, 0)
		lbl.text = "%s (%s)" % [d[1], Roster.rarity_name(Roster.rarity_of(id))]
		row.add_child(lbl)
		var buy := Button.new()
		buy.custom_minimum_size = Vector2(140, 28)
		var price := Progression.character_price(id)
		buy.text = "Recrutar %d" % price
		buy.disabled = Progression.ambrosia < price
		buy.pressed.connect(_on_buy_char.bind(id))
		row.add_child(buy)
		col.add_child(row)
	return col


func _on_buy_char(char_id: String) -> void:
	Progression.buy_character(char_id)
	Progression.save_game()
	_rebuild()


func _on_cycle_slot(char_id: String, slot: int) -> void:
	var key := "weapon" if slot == EquipmentData.Slot.WEAPON else "relic"
	var cur: String = Progression.equipped_ids(char_id).get(key, "")
	var options: Array = [""]
	for id in Progression.inventory:
		var item := EquipmentList.by_id(id)
		if item != null and item.slot == slot and (Progression.is_item_available(id) or id == cur):
			options.append(id)
	var idx: int = options.find(cur)
	var nxt: String = options[(idx + 1) % options.size()]
	if nxt == "":
		Progression.unequip(char_id, slot)
	else:
		Progression.equip(char_id, slot, nxt)
	Progression.save_game()
	_rebuild()


func _on_buy(item_id: String) -> void:
	Progression.buy_item(item_id)
	Progression.save_game()
	_rebuild()


func _on_evolve(char_id: String) -> void:
	Progression.evolve(char_id)
	Progression.save_game()
	_rebuild()
