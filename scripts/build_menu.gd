class_name BuildMenu
extends CanvasLayer

## Painel flutuante de construção/gestão, montado em código.
## - open_build: lista as 4 classes (nome + custo), desabilitando as sem ouro.
## - open_manage: mostra a torre (nível) com botões de upar e vender.
## Emite sinais; quem executa a economia é o BuildManager.

signal build_requested(data: TowerData)
signal upgrade_requested
signal sell_requested
signal move_requested
signal closed

const PANEL_WIDTH := 196.0
const ROW_HEIGHT := 34.0

var _panel: Panel
var _box: VBoxContainer


func _ready() -> void:
	layer = 10
	_panel = Panel.new()
	_panel.visible = false
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.position = Vector2(8, 8)
	_box.custom_minimum_size = Vector2(PANEL_WIDTH - 16, 0)
	_box.add_theme_constant_override("separation", 4)
	_panel.add_child(_box)


## entries: lista de TowerData (compat) OU de { data, allowed, reason } (zonas).
func open_build(world_pos: Vector2, entries: Array, gold: int) -> void:
	_clear()
	_add_title("Invocar  (ouro: %d)" % gold)
	for item in entries:
		var data: TowerData
		var allowed := true
		var reason := ""
		if item is Dictionary:
			data = item["data"]
			allowed = item.get("allowed", true)
			reason = item.get("reason", "")
		else:
			data = item
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 30)
		var suffix := ("  [%s]" % reason) if (not allowed and reason != "") else ""
		# Mostra a CLASSE no texto (ajuda a saber guerreiro/mago/sacerdote/arqueiro).
		var cls := ClassBadge.name_of(data.tower_class)
		b.text = "%s (%s)   %d%s" % [data.display_name, cls, data.cost, suffix]
		b.add_theme_color_override("font_color", data.body_color)
		b.disabled = (gold < data.cost) or (not allowed)
		b.pressed.connect(func(): build_requested.emit(data))
		_box.add_child(b)
	if entries.is_empty():
		_add_label("Sem herois disponiveis")
	_add_close_button()
	_show_at(world_pos)


func open_manage(world_pos: Vector2, tower: Tower, gold: int) -> void:
	_clear()
	_add_title("%s  Nv %d" % [tower.data.display_name, tower.level])
	var mv := Button.new()
	mv.custom_minimum_size = Vector2(0, 30)
	mv.text = "Mover"
	mv.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	mv.pressed.connect(func(): move_requested.emit())
	_box.add_child(mv)
	if tower.can_upgrade():
		var cost := tower.upgrade_cost()
		var up := Button.new()
		up.custom_minimum_size = Vector2(0, 30)
		up.text = "Upar p/ Nv %d   %d" % [tower.level + 1, cost]
		up.disabled = gold < cost
		up.pressed.connect(func(): upgrade_requested.emit())
		_box.add_child(up)
	else:
		_add_label("Nivel maximo")
	var sell := Button.new()
	sell.custom_minimum_size = Vector2(0, 30)
	sell.text = "Vender   +%d" % tower.sell_value()
	sell.pressed.connect(func(): sell_requested.emit())
	_box.add_child(sell)
	_add_close_button()
	_show_at(world_pos)


func close() -> void:
	if _panel != null:
		_panel.visible = false


func is_open() -> bool:
	return _panel != null and _panel.visible


func _show_at(world_pos: Vector2) -> void:
	var rows := _box.get_child_count()
	var height := rows * ROW_HEIGHT + 16.0
	_panel.size = Vector2(PANEL_WIDTH, height)
	var vp := get_viewport().get_visible_rect().size
	var p := world_pos + Vector2(28, -height * 0.5)
	p.x = clampf(p.x, 8.0, vp.x - PANEL_WIDTH - 8.0)
	p.y = clampf(p.y, 8.0, vp.y - height - 8.0)
	_panel.position = p
	_panel.visible = true


func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()


func _add_title(text: String) -> void:
	var l := Label.new()
	l.text = text
	_box.add_child(l)


func _add_label(text: String) -> void:
	var l := Label.new()
	l.text = text
	_box.add_child(l)


func _add_close_button() -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 28)
	b.text = "Fechar"
	b.pressed.connect(func(): close(); closed.emit())
	_box.add_child(b)
