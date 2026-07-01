class_name EquipmentScreen
extends CanvasLayer

## Tela de EQUIPAR (paper-doll): escolhe o herói (lista à esquerda), ele aparece
## GRANDE e CENTRALIZADO num pedestal, com os 8 slots organizados em duas colunas
## ao lado; à direita o inventário — clicar num item o encaixa no slot certo. Se o
## slot já estiver ocupado, pede confirmação da troca. Tudo salvo no Progression.
## (O equipamento DESENHADO sobre o corpo virá com o rig de "ossos" — frente própria.)

signal closed
signal section_selected(id: String)

# Slots em DUAS COLUNAS flanqueando o herói centralizado (centro do herói ~ x=512).
const SLOT_POS := {
	0: Vector2(348, 196),   # Elmo
	1: Vector2(348, 312),   # Peito
	2: Vector2(348, 428),   # Pernas
	3: Vector2(348, 544),   # Botas
	4: Vector2(676, 196),   # Arma
	5: Vector2(676, 312),   # Escudo
	6: Vector2(676, 428),   # Amuleto
	7: Vector2(676, 544),   # Anel
}
const HERO_CENTER := Vector2(512, 360)

var _sel: String = ""
var _center: Control
var _inv: VBoxContainer
var _hero_list: VBoxContainer
var _overlay: Control = null


func _ready() -> void:
	layer = 5
	add_child(UiTheme.wood_bg())
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.04, 0.03, 0.32)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	add_child(_title("EQUIPAR", Vector2(28, 24), 32))

	# Coluna esquerda: lista de heróis.
	add_child(_title("Herois", Vector2(28, 86), 16, Color(0.85, 0.82, 0.7)))
	var hscroll := ScrollContainer.new()
	hscroll.position = Vector2(20, 114)
	hscroll.custom_minimum_size = Vector2(168, 480)
	hscroll.size = Vector2(168, 480)
	hscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(hscroll)
	_hero_list = VBoxContainer.new()
	_hero_list.add_theme_constant_override("separation", 6)
	hscroll.add_child(_hero_list)

	# Painel central (palco do herói + slots).
	var stage := Panel.new()
	stage.position = Vector2(208, 96)
	stage.size = Vector2(620, 510)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.11, 0.09, 0.07, 0.82)
	ssb.set_corner_radius_all(16)
	ssb.set_border_width_all(2)
	ssb.border_color = Color(0.72, 0.56, 0.28)
	stage.add_theme_stylebox_override("panel", ssb)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	_center = Control.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)

	# Coluna direita: inventário.
	add_child(_title("Inventario", Vector2(854, 86), 16, Color(0.85, 0.82, 0.7)))
	var panel := Panel.new()
	panel.position = Vector2(850, 114)
	panel.size = Vector2(410, 480)
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(0.96))
	add_child(panel)
	var mar := MarginContainer.new()
	mar.position = Vector2(10, 10)
	mar.size = Vector2(390, 460)
	panel.add_child(mar)
	var iscroll := ScrollContainer.new()
	iscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mar.add_child(iscroll)
	_inv = VBoxContainer.new()
	_inv.add_theme_constant_override("separation", 5)
	_inv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iscroll.add_child(_inv)

	var unlocked: Array = Progression.unlocked_ids()
	_sel = unlocked[0] if not unlocked.is_empty() else ""
	_build_hero_list()
	_rebuild()
	NavBar.add_to(self, "equip", func(id): section_selected.emit(id), func(): closed.emit())


## Seleciona um herói pela id (usado por atalhos/telas externas).
func select_hero(id: String) -> void:
	if id in Progression.unlocked_ids():
		_sel = id
		_build_hero_list()
		_rebuild()


func _build_hero_list() -> void:
	for c in _hero_list.get_children():
		c.queue_free()
	for id in Progression.unlocked_ids():
		var ch := Roster.by_id(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(158, 58)
		b.text = "  " + (ch.display_name if ch != null else id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		var tex := Art.hero(id)
		if tex != null:
			b.icon = tex
			b.expand_icon = true
		if id == _sel:
			b.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
		b.pressed.connect(func(i = id): _sel = i; _build_hero_list(); _rebuild())
		_hero_list.add_child(b)


func _rebuild() -> void:
	_rebuild_center()
	_rebuild_inventory()


func _rebuild_center() -> void:
	for c in _center.get_children():
		c.queue_free()
	if _sel == "":
		return
	var ch := Roster.by_id(_sel)
	_center.add_child(_ctitle(ch.display_name if ch != null else _sel))

	# Brilho radial atrás do herói.
	var glow := _Glow.new()
	glow.position = HERO_CENTER + Vector2(0, -10)
	_center.add_child(glow)

	# Pedestal sob os pés.
	var ped := TextureRect.new()
	ped.texture = Art.map("pedestal")
	ped.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ped.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ped.size = Vector2(260, 120)
	ped.position = HERO_CENTER + Vector2(-130, 150)
	ped.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(ped)

	# Herói GRANDE em 3D — mostra o EQUIPAMENTO VESTIDO no corpo.
	var worn_now: Dictionary = Progression.equipped_ids(_sel)
	var v := preload("res://scripts/hero_view_3d.gd").new()
	if v.setup(_sel, 440):
		v.position = HERO_CENTER + Vector2(0, 172)  # pés ~ sobre o pedestal
		_center.add_child(v)
		# Veste os itens equipados (1 modelo 3D por slot — set lendário como visual).
		var eq_keys := ["helmet", "armor", "legs", "boots", "weapon", "shield", "amulet", "ring"]
		for slot_s in worn_now.keys():
			if str(worn_now[slot_s]) == "":
				continue  # slot vazio -> não veste nada
			var si := int(slot_s)
			if si >= 0 and si < eq_keys.size():
				v.equip(eq_keys[si], "res://assets/models/props/%s_legend.glb" % eq_keys[si])
	else:
		# Fallback: arte 2D se não houver modelo 3D do herói.
		var art := TextureRect.new()
		art.texture = Art.hero(_sel)
		art.size = Vector2(300, 400)
		art.position = HERO_CENTER + Vector2(-150, -210)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_center.add_child(art)

	# Slots (botão + rótulo) nas duas colunas.
	var worn: Dictionary = Progression.equipped_ids(_sel)
	for slot in range(EquipmentData.SLOT_NAMES.size()):
		var pos: Vector2 = SLOT_POS.get(slot, HERO_CENTER)
		_center.add_child(_make_slot(slot, str(worn.get(str(slot), "")), pos))
		var lbl := _title(EquipmentData.slot_name(slot), pos + Vector2(-40, 36), 13, Color(0.82, 0.78, 0.66))
		lbl.size = Vector2(80, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_center.add_child(lbl)


func _ctitle(text: String) -> Label:
	var l := _title(text, Vector2(208, 100), 26)
	l.size = Vector2(620, 34)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _make_slot(slot: int, item_id: String, center: Vector2) -> Control:
	const R := 30.0
	var item: EquipmentData = EquipmentList.by_id(item_id) if item_id != "" else null
	var b := Button.new()
	b.position = center - Vector2(R, R)
	b.custom_minimum_size = Vector2(R * 2, R * 2)
	b.size = Vector2(R * 2, R * 2)
	b.tooltip_text = EquipmentData.slot_name(slot) + ("" if item == null else (": " + item.display_name))
	var border := EquipmentData.rarity_color(item.rarity) if item != null else Color(0.7, 0.62, 0.42)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.95) if item != null else Color(0.07, 0.06, 0.05, 0.85)
	sb.set_corner_radius_all(int(R))
	sb.set_border_width_all(3 if item != null else 2)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if item != null:
		var tex := Art.item(item.icon_id())
		if tex != null:
			b.icon = tex
			b.expand_icon = true
		b.pressed.connect(func(): Progression.unequip(_sel, slot); Progression.save_game(); _rebuild())
	return b


func _rebuild_inventory() -> void:
	for c in _inv.get_children():
		c.queue_free()
	if _sel == "":
		return
	var ids: Array = Progression.inventory.duplicate()
	if ids.is_empty():
		var none := Label.new()
		none.text = "Sem itens. Compre na Loja."
		none.add_theme_color_override("font_color", Color(0.8, 0.76, 0.66))
		_inv.add_child(none)
		return
	ids.sort_custom(func(a, b):
		var ia := EquipmentList.by_id(a)
		var ib := EquipmentList.by_id(b)
		if ia == null or ib == null:
			return false
		if ia.slot != ib.slot:
			return ia.slot < ib.slot
		return ia.rarity > ib.rarity)
	for id in ids:
		var item := EquipmentList.by_id(id)
		if item != null:
			_inv.add_child(_inv_row(item))


func _inv_row(item: EquipmentData) -> Button:
	var owner: String = Progression._item_owner(item.id)
	var here := owner == _sel
	var b := Button.new()
	b.custom_minimum_size = Vector2(360, 48)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var tex := Art.item(item.icon_id())
	if tex != null:
		b.icon = tex
		b.expand_icon = true
	var tag := ""
	if here:
		tag = "  [usando]"
	elif owner != "":
		var oc := Roster.by_id(owner)
		tag = "  [%s]" % (oc.display_name if oc != null else owner)
	b.text = "  %s  ·  %s%s" % [item.display_name, EquipmentData.slot_name(item.slot), tag]
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", EquipmentData.rarity_color(item.rarity))
	if here:
		b.disabled = true
	else:
		b.pressed.connect(func(): _pick_item(item))
	return b


## Clicou num item do inventário: encaixa no slot certo (confirma se já houver um lá).
func _pick_item(item: EquipmentData) -> void:
	var cur: String = Progression.equipped_ids(_sel).get(str(item.slot), "")
	if cur != "" and cur != item.id:
		var old := EquipmentList.by_id(cur)
		var old_name: String = old.display_name if old != null else "item atual"
		_show_confirm("Trocar %s\npor %s\nno slot %s?" % [old_name, item.display_name, EquipmentData.slot_name(item.slot)],
			func(): _do_equip(item))
	else:
		_do_equip(item)


func _do_equip(item: EquipmentData) -> void:
	var owner: String = Progression._item_owner(item.id)
	if owner != "" and owner != _sel:
		Progression.unequip(owner, item.slot)
	Progression.equip(_sel, item.slot, item.id)
	Progression.save_game()
	_rebuild()


## Diálogo de confirmação (overlay centralizado) com Aceitar / Cancelar.
func _show_confirm(text: String, on_yes: Callable) -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _close_overlay())
	_overlay.add_child(dim)
	var card := Panel.new()
	card.position = Vector2(440, 250)
	card.size = Vector2(400, 220)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.11, 0.08, 0.98)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.85, 0.66, 0.30)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	_overlay.add_child(card)
	var lbl := _title(text, Vector2(440, 272), 22, Color(1.0, 0.92, 0.72))
	lbl.size = Vector2(400, 120)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(lbl)
	var yes := _gold_btn("Aceitar")
	yes.position = Vector2(470, 408)
	yes.size = Vector2(150, 46)
	yes.pressed.connect(func(): _close_overlay(); on_yes.call())
	_overlay.add_child(yes)
	var no := Button.new()
	no.text = "Cancelar"
	no.position = Vector2(660, 408)
	no.custom_minimum_size = Vector2(150, 46)
	no.pressed.connect(_close_overlay)
	_overlay.add_child(no)


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null


func _gold_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 20)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.86, 0.66, 0.24)
	s.set_corner_radius_all(10)
	s.set_border_width_all(2)
	s.border_color = Color(1.0, 0.93, 0.62)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_color_override("font_color", Color(0.2, 0.12, 0.02))
	return b


func _title(text: String, pos: Vector2, fsize: int, col: Color = Color(1.0, 0.9, 0.6)) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ff := UiTheme.fancy_font()
	if ff != null:
		l.add_theme_font_override("font", ff)
	return l


## Brilho radial suave (atrás do herói).
class _Glow extends Node2D:
	func _draw() -> void:
		for i in 6:
			var t := 1.0 - i / 6.0
			draw_circle(Vector2.ZERO, 70 + i * 22, Color(1.0, 0.86, 0.45, 0.05 * t))
