class_name HubScreen
extends CanvasLayer

## Tela de base: monta o esquadrão (até SQUAD_MAX personagens) filtrando por
## mitologia, e escolhe a fase. Emite start_stage(stage, squad_ids).

signal start_stage(stage: StageData, squad_ids: Array)
signal open_collection
signal open_gacha
signal open_quests

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]

var _selected: Array = []
var _filter: String = "Todas"
var _list_box: VBoxContainer
var _stage_buttons: Array = []
var _hint: Label
var _squad_label: Label


func _ready() -> void:
	layer = 5
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.10, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.position = Vector2(40, 20)
	title.text = "MITHOS TD"
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)

	var meta := Label.new()
	meta.position = Vector2(40, 66)
	meta.text = "Fase liberada: %d/%d    Ouro: %d    Ambrosia: %d    Herois: %d/%d" % \
		[Progression.highest_stage_unlocked, StageList.count(), Progression.meta_gold, \
		Progression.ambrosia, Progression.unlocked_ids().size(), Roster.count()]
	add_child(meta)

	var menu_bar := HBoxContainer.new()
	menu_bar.position = Vector2(40, 94)
	menu_bar.add_theme_constant_override("separation", 8)
	add_child(menu_bar)
	var b_col := _menu_btn("Colecao / Loja")
	b_col.pressed.connect(func(): open_collection.emit())
	menu_bar.add_child(b_col)
	var b_gacha := _menu_btn("Altar (Gacha)")
	b_gacha.pressed.connect(func(): open_gacha.emit())
	menu_bar.add_child(b_gacha)
	var b_quests := _menu_btn("Missoes")
	b_quests.pressed.connect(func(): open_quests.emit())
	menu_bar.add_child(b_quests)

	# Filtro de mitologia.
	var filter_bar := HBoxContainer.new()
	filter_bar.position = Vector2(40, 138)
	filter_bar.add_theme_constant_override("separation", 4)
	add_child(filter_bar)
	for myth in (["Todas"] + Roster.MYTHOLOGIES):
		var fb := Button.new()
		fb.custom_minimum_size = Vector2(96, 28)
		fb.text = myth
		fb.pressed.connect(_set_filter.bind(myth))
		filter_bar.add_child(fb)

	# Lista de personagens (rolável).
	var squad_head := Label.new()
	squad_head.position = Vector2(40, 176)
	squad_head.text = "Esquadrao (ate %d) — clique para selecionar:" % Progression.SQUAD_MAX
	add_child(squad_head)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 204)
	scroll.custom_minimum_size = Vector2(560, 440)
	add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 2)
	scroll.add_child(_list_box)

	# Coluna das fases.
	var stage_head := Label.new()
	stage_head.position = Vector2(640, 176)
	stage_head.text = "Fases"
	stage_head.add_theme_font_size_override("font_size", 20)
	add_child(stage_head)
	var stage_col := VBoxContainer.new()
	stage_col.position = Vector2(640, 206)
	stage_col.add_theme_constant_override("separation", 6)
	add_child(stage_col)
	for s in StageList.all():
		var b := Button.new()
		b.custom_minimum_size = Vector2(320, 36)
		b.text = "Fase %d  -  %s" % [s.index, s.display_name]
		b.pressed.connect(_try_start.bind(s))
		stage_col.add_child(b)
		_stage_buttons.append({"button": b, "stage": s})

	_squad_label = Label.new()
	_squad_label.position = Vector2(640, 440)
	add_child(_squad_label)
	_hint = Label.new()
	_hint.position = Vector2(640, 470)
	_hint.custom_minimum_size = Vector2(560, 0)
	add_child(_hint)

	_refresh_list()
	_refresh()


func _menu_btn(text: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 32)
	b.text = text
	return b


func _set_filter(myth: String) -> void:
	_filter = myth
	_refresh_list()


func _refresh_list() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	for ch in Roster.all():
		if _filter != "Todas" and ch.mythology != _filter:
			continue
		if not Progression.is_unlocked(ch.id):
			continue
		var cb := CheckButton.new()
		cb.text = "%s  [%s]  (%s)  Nv %d" % [ch.display_name, ch.mythology, \
			CLASS_NAMES[ch.tower_class], Progression.level_of(ch.id)]
		cb.set_pressed_no_signal(_selected.has(ch.id))
		cb.toggled.connect(_on_char_toggled.bind(ch.id, cb))
		_list_box.add_child(cb)


func _on_char_toggled(pressed: bool, id: String, cb: CheckButton) -> void:
	if pressed:
		if _selected.size() >= Progression.SQUAD_MAX:
			cb.set_pressed_no_signal(false)
			return
		if not _selected.has(id):
			_selected.append(id)
	else:
		_selected.erase(id)
	_refresh()


func _try_start(stage: StageData) -> void:
	if _selected.is_empty() or stage.index > Progression.highest_stage_unlocked:
		return
	start_stage.emit(stage, _selected.duplicate())


func _refresh() -> void:
	for entry in _stage_buttons:
		var locked: bool = entry["stage"].index > Progression.highest_stage_unlocked
		entry["button"].disabled = locked or _selected.is_empty()
	_squad_label.text = "Esquadrao: %d/%d" % [_selected.size(), Progression.SQUAD_MAX]
	if _selected.is_empty():
		_hint.text = "Selecione ao menos 1 heroi para liberar as fases."
	else:
		var names: Array = []
		for id in _selected:
			var c := Roster.by_id(id)
			if c != null:
				names.append(c.display_name)
		_hint.text = "Levando: " + ", ".join(names)
