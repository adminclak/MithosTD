class_name BuildManager
extends Node2D

## Construção estilo Kingdom Rush (slots): pontos estratégicos fixos no mapa.
## - Toca num slot vazio -> menu radial com as 4 torres (Arqueiro/Guerreiro/
##   Sacerdote/Mago) + custo -> constrói com ouro.
## - Toca numa torre -> radial Melhorar/Vender.
## A API de economia (try_place/try_upgrade/sell/can_place) é mantida e testável.

const CLICK_RADIUS := 30.0
const MIN_SPACING := 36.0
const SLOT_PICK_RADIUS := 46.0
const BOUNDS := Rect2(20, 20, 1240, 600)

var waypoints: Array = []
var squad: Array = []
var slots: Array = [] ## Vector2 dos pontos estratégicos

var _towers: Array = []
var _radial: RadialMenu = null
var _pending_slot: int = -1
var _mode: String = ""

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(wpoints: Array, squad_datas: Array = [], slot_positions: Array = []) -> void:
	waypoints = wpoints.duplicate()
	squad = squad_datas.duplicate()
	slots = slot_positions.duplicate()


func _ready() -> void:
	_radial = RadialMenu.new()
	add_child(_radial)
	_radial.chosen.connect(_on_radial_chosen)
	queue_redraw()


# --- Entrada: tocar slot (construir) ou torre (gerir) ---
func _unhandled_input(event: InputEvent) -> void:
	if _state != null and _state.is_over():
		return
	if _radial != null and _radial.is_open():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := get_global_mouse_position()
		var si := _slot_at(pos)
		if si < 0:
			return
		if _tower_near(slots[si]) != null:
			_open_manage(si)
		else:
			_open_build(si)
		get_viewport().set_input_as_handled()


## Torre construída sobre/perto de um slot (robusto p/ radial e demo).
func _tower_near(pos: Vector2, r: float = 26.0) -> Tower:
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < r:
			return t
	return null


func _slot_at(pos: Vector2) -> int:
	var best := -1
	var best_d := SLOT_PICK_RADIUS
	for i in slots.size():
		var d: float = slots[i].distance_to(pos)
		if d <= best_d:
			best_d = d
			best = i
	return best


func _options_classes() -> Array:
	# Ordem: Arqueiro, Guerreiro, Sacerdote, Mago (TowerData.all_classes()).
	var out: Array = []
	for d in TowerData.all_classes():
		out.append({"text": "%s\n%d" % [d.display_name.left(8), d.cost],
			"color": d.body_color, "enabled": _gold() >= d.cost})
	return out


func _open_build(si: int) -> void:
	_pending_slot = si
	_mode = "build"
	_radial.open_menu(slots[si], _options_classes())


func _open_manage(si: int) -> void:
	_pending_slot = si
	_mode = "manage"
	var t: Tower = _tower_near(slots[si])
	if t == null:
		return
	var up_ok := t.can_upgrade() and _gold() >= t.upgrade_cost()
	var up_text := ("Melhorar\n%d" % t.upgrade_cost()) if t.can_upgrade() else "Maximo"
	_radial.open_menu(t.global_position, [
		{"text": up_text, "color": Color(0.6, 1, 0.6), "enabled": up_ok},
		{"text": "Vender\n+%d" % t.sell_value(), "color": Color(1, 0.85, 0.4), "enabled": true},
	])


func _on_radial_chosen(index: int) -> void:
	if _pending_slot < 0:
		return
	if _mode == "build":
		var data: TowerData = TowerData.all_classes()[index]
		if try_place(slots[_pending_slot], data):
			queue_redraw()
	elif _mode == "manage":
		var t: Tower = _tower_near(slots[_pending_slot])
		if t == null:
			return
		if index == 0:
			try_upgrade(t)
		elif index == 1:
			sell(t)
			queue_redraw()
	_pending_slot = -1
	_mode = ""


# --- Desenho dos slots vazios ---
func _draw() -> void:
	for i in slots.size():
		if _tower_near(slots[i]) != null:
			continue
		var p: Vector2 = slots[i]
		draw_circle(p + Vector2(0, 3), 20.0, Color(0, 0, 0, 0.25))
		draw_circle(p, 18.0, Color(0.52, 0.40, 0.24, 0.85))
		draw_arc(p, 18.0, 0.0, TAU, 24, Color(0.30, 0.22, 0.12), 3.0)
		# "+" indicando ponto de construção.
		draw_line(p + Vector2(-7, 0), p + Vector2(7, 0), Color(1, 0.95, 0.7, 0.9), 3.0)
		draw_line(p + Vector2(0, -7), p + Vector2(0, 7), Color(1, 0.95, 0.7, 0.9), 3.0)


# --- Validação / economia (testável, sem UI) ---
func can_place(_tower_class: int, pos: Vector2) -> bool:
	if not BOUNDS.has_point(pos):
		return false
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < MIN_SPACING:
			return false
	return true


func _available_squad() -> Array:
	if squad.is_empty():
		return TowerData.all_classes()
	var in_field := {}
	for t in _towers:
		if is_instance_valid(t) and t.data.char_id != "":
			in_field[t.data.char_id] = true
	var out: Array = []
	for d in squad:
		if not in_field.has(d.char_id):
			out.append(d)
	return out


func _tower_at(pos: Vector2) -> Tower:
	var best: Tower = null
	var best_d := CLICK_RADIUS
	for t in _towers:
		if not is_instance_valid(t):
			continue
		var dd: float = t.global_position.distance_to(pos)
		if dd <= best_d:
			best_d = dd
			best = t
	return best


func _gold() -> int:
	return _state.gold if _state != null else 0


func try_place(pos: Vector2, data: TowerData) -> bool:
	if not can_place(data.tower_class, pos):
		return false
	if _state == null or not _state.try_spend(data.cost):
		return false
	var t := Tower.new()
	t.setup(data)
	t.waypoints = waypoints
	t.position = pos
	add_child(t)
	_towers.append(t)
	return true


func try_upgrade(tower: Tower) -> bool:
	if tower == null or not is_instance_valid(tower) or not tower.can_upgrade():
		return false
	if _state == null or not _state.try_spend(tower.upgrade_cost()):
		return false
	tower.apply_upgrade()
	return true


func sell(tower: Tower) -> bool:
	if tower == null or not is_instance_valid(tower):
		return false
	if _state != null:
		_state.add_gold(tower.sell_value())
	_towers.erase(tower)
	tower.queue_free()
	return true
