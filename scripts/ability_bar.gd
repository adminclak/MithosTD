class_name AbilityBar
extends CanvasLayer

## Barra de habilidades no rodapé: um botão por personagem (torre com habilidade)
## em campo. Mostra o cooldown e dispara a habilidade ao clicar. Reconstrói os
## botões quando o conjunto de torres em campo muda.

var _bar: HBoxContainer
var _entries: Array = [] ## { button: Button, tower: Tower }
var _tracked: Array = [] ## instance ids das torres atualmente na barra


func _ready() -> void:
	layer = 4
	_bar = HBoxContainer.new()
	_bar.position = Vector2(20, 640)
	_bar.add_theme_constant_override("separation", 8)
	add_child(_bar)


func _process(_delta: float) -> void:
	var towers := _towers_with_ability()
	var ids: Array = []
	for t in towers:
		ids.append(t.get_instance_id())
	if ids != _tracked:
		_rebuild(towers, ids)
	_update_cooldowns()


func _towers_with_ability() -> Array:
	var out: Array = []
	for t in get_tree().get_nodes_in_group("towers"):
		if is_instance_valid(t) and t.has_ability():
			out.append(t)
	return out


func _rebuild(towers: Array, ids: Array) -> void:
	for c in _bar.get_children():
		c.queue_free()
	_entries.clear()
	for t in towers:
		var b := Button.new()
		b.custom_minimum_size = Vector2(132, 46)
		b.pressed.connect(_on_pressed.bind(t))
		_bar.add_child(b)
		_entries.append({"button": b, "tower": t})
	_tracked = ids


func _update_cooldowns() -> void:
	for e in _entries:
		var t = e["tower"]
		if not is_instance_valid(t):
			continue
		var cd: float = t.ability_cooldown_left()
		var b: Button = e["button"]
		b.disabled = cd > 0.0
		var status := "PRONTO" if cd <= 0.0 else "%ds" % int(ceil(cd))
		b.text = "%s\n%s" % [t.data.ability.display_name, status]


func _on_pressed(tower) -> void:
	if is_instance_valid(tower):
		tower.use_ability()
