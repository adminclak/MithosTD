class_name HubScreen
extends CanvasLayer

## Tela de base: monta o esquadrão (até SQUAD_MAX personagens desbloqueados) e
## escolhe a fase a jogar. Emite start_stage(stage, squad_ids).

signal start_stage(stage: StageData, squad_ids: Array)

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]

var _selected: Array = []
var _stage_buttons: Array = [] ## { button, stage }
var _hint: Label


func _ready() -> void:
	layer = 5
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.position = Vector2(48, 32)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "MITHOS TD  -  Mundo Grego"
	title.add_theme_font_size_override("font_size", 36)
	root.add_child(title)

	var meta := Label.new()
	meta.text = "Fase mais alta liberada: %d/%d    Essencia: %d" % \
		[Progression.highest_stage_unlocked, StageList.count(), Progression.meta_essence]
	root.add_child(meta)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 64)
	root.add_child(cols)

	# Coluna do esquadrão.
	var squad_col := VBoxContainer.new()
	squad_col.add_theme_constant_override("separation", 4)
	cols.add_child(squad_col)
	var squad_title := Label.new()
	squad_title.text = "Esquadrao (max %d)" % Progression.SQUAD_MAX
	squad_col.add_child(squad_title)
	for id in Progression.unlocked_ids():
		squad_col.add_child(_make_char_row(id))

	# Coluna das fases.
	var stage_col := VBoxContainer.new()
	stage_col.add_theme_constant_override("separation", 4)
	cols.add_child(stage_col)
	var stage_title := Label.new()
	stage_title.text = "Fases"
	stage_col.add_child(stage_title)
	for s in StageList.all():
		var b := Button.new()
		b.custom_minimum_size = Vector2(280, 34)
		b.text = "Fase %d  -  %s" % [s.index, s.display_name]
		b.pressed.connect(_try_start.bind(s))
		stage_col.add_child(b)
		_stage_buttons.append({"button": b, "stage": s})

	_hint = Label.new()
	root.add_child(_hint)

	_refresh()


func _make_char_row(id: String) -> CheckButton:
	var ch := GreekRoster.by_id(id)
	var cb := CheckButton.new()
	cb.text = "%s  (%s)  Nv %d" % [ch.display_name, CLASS_NAMES[ch.tower_class], Progression.level_of(id)]
	cb.toggled.connect(_on_char_toggled.bind(id, cb))
	return cb


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
	if _selected.is_empty():
		_hint.text = "Selecione ao menos 1 personagem para liberar as fases."
	else:
		_hint.text = "Esquadrao: %d/%d  -  escolha uma fase." % [_selected.size(), Progression.SQUAD_MAX]
