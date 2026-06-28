class_name WorldMapScreen
extends CanvasLayer

## Mapa-múndi: as fases como nós ligados por um caminho. Nó liberado = jogável;
## bloqueado = escuro; próximo = brilhando. Clicar inicia a fase com o esquadrão
## salvo. Emite stage_chosen(stage) e back.

signal stage_chosen(stage: StageData)
signal back

# Posições dos nós no mapa (5 fases), numa jornada diagonal.
const NODES := [
	Vector2(170, 540), Vector2(400, 380), Vector2(650, 500),
	Vector2(880, 320), Vector2(1090, 180),
]

var _msg: Label


func _ready() -> void:
	layer = 5
	var bg_tex := Art.map("world_map")
	if bg_tex != null:
		var tr := TextureRect.new()
		tr.texture = bg_tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(tr)
	var scrim := ColorRect.new()
	scrim.color = Color(0.04, 0.05, 0.09, 0.30)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	# Moldura de madeira ornamentada emoldurando o mapa (estilo Kingdom Rush).
	add_child(UiTheme.ornate_frame())

	# Caminho ligando as fases.
	var stages := StageList.all()
	var path := Line2D.new()
	for i in min(NODES.size(), stages.size()):
		path.add_point(NODES[i])
	path.width = 8.0
	path.default_color = Color(0.95, 0.85, 0.5, 0.7)
	path.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(path)

	var title := Label.new()
	title.position = Vector2(0, 80)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.text = "ESCOLHA A FASE"
	add_child(title)

	# Marcadores das fases (disco + estrelas) desenhados pelo overlay.
	var overlay := MapOverlay.new()
	add_child(overlay)
	var empty_sb := StyleBoxEmpty.new()
	for i in min(NODES.size(), stages.size()):
		var s: StageData = stages[i]
		var locked: bool = s.index > Progression.highest_stage_unlocked
		var is_next: bool = s.index == Progression.highest_stage_unlocked
		var state := 0
		if not locked:
			state = 2 if s.index < Progression.highest_stage_unlocked else 1
		overlay.nodes.append({"pos": NODES[i], "idx": s.index, "state": state})
		# Botão transparente só para captar o clique.
		var b := Button.new()
		b.size = Vector2(80, 80)
		b.custom_minimum_size = Vector2(80, 80)
		b.position = NODES[i] - Vector2(40, 40)
		b.add_theme_stylebox_override("normal", empty_sb)
		b.add_theme_stylebox_override("hover", empty_sb)
		b.add_theme_stylebox_override("pressed", empty_sb)
		b.add_theme_stylebox_override("disabled", empty_sb)
		b.disabled = locked
		b.tooltip_text = "%s\n%s" % [s.display_name, ("BLOQUEADA" if locked else "Jogar")]
		if not locked:
			b.pressed.connect(_on_node.bind(s))
		add_child(b)
		# Nome da fase numa plaquinha sob o nó.
		var nl := Label.new()
		nl.position = NODES[i] + Vector2(-90, 44)
		nl.size = Vector2(180, 20)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", Color(1, 1, 0.85) if not locked else Color(0.6, 0.6, 0.65))
		nl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		nl.add_theme_constant_override("outline_size", 4)
		nl.text = s.display_name
		add_child(nl)

	# Esquadrão atual + voltar.
	_msg = Label.new()
	_msg.position = Vector2(0, 636)
	_msg.size = Vector2(1280, 24)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	add_child(_msg)
	_update_squad_msg()

	var back_btn := Button.new()
	back_btn.position = Vector2(96, 648)
	back_btn.custom_minimum_size = Vector2(150, 42)
	back_btn.text = "Voltar"
	back_btn.pressed.connect(func(): back.emit())
	add_child(back_btn)


func _update_squad_msg() -> void:
	var squad := Progression.current_squad()
	if squad.is_empty():
		_msg.text = "Equipe %d vazia — monte em HEROIS antes de jogar" % (Progression.active_team + 1)
		return
	var names: Array = []
	for id in squad:
		var c := Roster.by_id(id)
		if c != null:
			names.append(c.display_name)
	_msg.text = "Equipe %d: %s" % [Progression.active_team + 1, ", ".join(names)]


func _on_node(stage: StageData) -> void:
	if Progression.current_squad().is_empty():
		_update_squad_msg()
		return
	stage_chosen.emit(stage)
