class_name QuestsScreen
extends CanvasLayer

## Tela de missões: campanha + diárias, com progresso e botão de coletar.

signal closed

var _box: VBoxContainer


func _ready() -> void:
	layer = 5
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.10, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 40)
	scroll.custom_minimum_size = Vector2(1160, 640)
	add_child(scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_box)

	_rebuild()


func _rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "MISSOES"
	title.add_theme_font_size_override("font_size", 32)
	_box.add_child(title)

	var amb := Label.new()
	amb.text = "Ambrosia: %d" % Progression.ambrosia
	amb.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	_box.add_child(amb)

	_add_section("Campanha", false)
	_add_section("Diarias", true)

	var back := Button.new()
	back.custom_minimum_size = Vector2(160, 36)
	back.text = "Voltar"
	back.pressed.connect(func(): closed.emit())
	_box.add_child(back)


func _add_section(header: String, daily: bool) -> void:
	var h := Label.new()
	h.text = header
	h.add_theme_font_size_override("font_size", 22)
	_box.add_child(h)
	for q in Quests.all():
		if q.get("daily", false) != daily:
			continue
		_box.add_child(_quest_row(q))


func _quest_row(q: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(520, 0)
	lbl.text = "%s  (%d/%d)" % [q["desc"], Progression.quest_progress(q), q["target"]]
	row.add_child(lbl)

	var rew := Label.new()
	rew.custom_minimum_size = Vector2(150, 0)
	rew.text = "+%d Ambrosia" % q["ambrosia"]
	rew.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	row.add_child(rew)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 30)
	if Progression.quest_claimed(q):
		btn.text = "Coletado"
		btn.disabled = true
	elif Progression.quest_claimable(q):
		btn.text = "Coletar"
		btn.pressed.connect(_on_claim.bind(q["id"]))
	else:
		btn.text = "Em progresso"
		btn.disabled = true
	row.add_child(btn)
	return row


func _on_claim(qid: String) -> void:
	Progression.claim_quest(qid)
	Progression.save_game()
	_rebuild()
