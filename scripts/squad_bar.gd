class_name SquadBar
extends CanvasLayer

## Barra de heróis no rodapé (estilo Kingdom Rush): mostra os personagens do
## esquadrão ainda disponíveis (não em campo). Clicar num card entra no modo de
## colocação (o BuildManager mostra o "fantasma" seguindo o mouse). Tooltip mostra
## classe, tipo (melee/ranged), atributos, stats e habilidade.

signal char_selected(data: TowerData)

const CLASS_NAMES := ["Arqueiro", "Mago", "Guerreiro", "Sacerdote"]

var build_manager: BuildManager
var _bar: HBoxContainer
var _cards: Array = [] ## { btn, data }
var _last_ids: Array = []

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(bm: BuildManager) -> void:
	build_manager = bm


func _ready() -> void:
	layer = 6
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.40)
	bg.position = Vector2(0, 628)
	bg.size = Vector2(1280, 92)
	add_child(bg)
	_bar = HBoxContainer.new()
	_bar.position = Vector2(16, 636)
	_bar.add_theme_constant_override("separation", 8)
	add_child(_bar)


func _process(_delta: float) -> void:
	if build_manager == null:
		return
	var avail := build_manager._available_squad()
	var ids: Array = []
	for d in avail:
		ids.append(d.char_id)
	if ids != _last_ids:
		_rebuild(avail)
		_last_ids = ids
	# Habilita/desabilita por ouro a cada frame.
	var gold: int = _state.gold if _state != null else 0
	for c in _cards:
		c["btn"].disabled = gold < c["data"].cost


func _rebuild(avail: Array) -> void:
	for c in _bar.get_children():
		c.queue_free()
	_cards.clear()
	for d in avail:
		var b := Button.new()
		b.custom_minimum_size = Vector2(98, 80)
		b.tooltip_text = _tooltip(d)
		var tex := Art.hero(d.char_id)
		if tex != null:
			b.icon = tex
			b.expand_icon = true
			b.text = "\n%d" % d.cost
		else:
			b.text = "%s\n%d" % [d.display_name, d.cost]
			b.add_theme_color_override("font_color", d.body_color)
		b.pressed.connect(_on_card.bind(d))
		_bar.add_child(b)
		_cards.append({"btn": b, "data": d})


func _on_card(d: TowerData) -> void:
	char_selected.emit(d)


func _tooltip(d: TowerData) -> String:
	var tipo := "Melee (tanque, segura inimigos)" if d.is_melee else "Ranged (ataca a distancia)"
	var t := "%s\n%s  -  %s\nCusto: %d ouro\n" % [d.display_name, CLASS_NAMES[d.tower_class], tipo, d.cost]
	var a: AttributeSet = d.attributes
	if a != null:
		t += "FOR %d  AGI %d  VIT %d\nINT %d  DES %d  SOR %d\n" % \
			[a.strength, a.agility, a.vitality, a.intelligence, a.dexterity, a.luck]
	if d.is_melee:
		t += "Vida %d - Defesa %d - Dano %d - Segura %d\n" % \
			[d.max_hp, d.defense, d.melee_damage, d.block_capacity]
	else:
		t += "Dano %d - Alcance %d - Cadencia %.1f/s\n" % [d.damage, int(d.attack_range), d.fire_rate]
	if d.crit_chance > 0.0:
		t += "Critico %d%%\n" % int(round(d.crit_chance * 100))
	if d.ability != null:
		t += "Habilidade: %s" % d.ability.display_name
	return t
