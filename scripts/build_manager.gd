class_name BuildManager
extends Node2D

## Construção do Mithos TD (modelo: HERÓIS são as unidades — ver pilar de design).
## Slots fixos no mapa; tocar num slot vazio abre um painel com OS SEUS HERÓIS do
## esquadrão que ainda não estão em campo (e que não são o campeão móvel) -> você
## escolhe qual posicionar, gastando ouro. Tocar numa unidade abre Melhorar/Vender.
## Cada herói é único em campo. A economia (try_place/try_upgrade/sell/can_place)
## fica separada da UI e é testável via /root/GameState.

const CLICK_RADIUS := 30.0
const MIN_SPACING := 36.0
const SLOT_PICK_RADIUS := 46.0
const BOUNDS := Rect2(20, 20, 1240, 600)

var waypoints: Array = []
var squad: Array = []
var slots: Array = [] ## Vector2 dos pontos estratégicos
var damage_mult: float = 1.0 ## bênção Fúria de Ares (futuras torres utilitárias)

var _towers: Array = []
var _menu: BuildMenu = null
var _pending_slot: int = -1
var _pending_tower: Tower = null
var _selected: Tower = null  ## herói escolhido (anel) para gerir/mover
var _move_mode: bool = false ## aguardando o toque de destino do herói selecionado

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(wpoints: Array, squad_datas: Array = [], slot_positions: Array = [], dmg_mult: float = 1.0) -> void:
	waypoints = wpoints.duplicate()
	squad = squad_datas.duplicate()
	slots = slot_positions.duplicate()
	damage_mult = dmg_mult


func _ready() -> void:
	_menu = BuildMenu.new()
	add_child(_menu)
	_menu.build_requested.connect(_on_build_requested)
	_menu.upgrade_requested.connect(_on_upgrade_requested)
	_menu.sell_requested.connect(_on_sell_requested)
	_menu.move_requested.connect(_on_move_requested)
	queue_redraw()


# --- Entrada: posicionar herói (slot) / gerir / mover (todos os heróis são móveis) ---
func _unhandled_input(event: InputEvent) -> void:
	if _state != null and _state.is_over():
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := get_global_mouse_position()
	# 1) Modo mover: o próximo toque manda o herói selecionado andar até ali.
	if _move_mode and is_instance_valid(_selected):
		_selected.move_to(pos)
		_clear_selection()
		get_viewport().set_input_as_handled()
		return
	# 2) Painel aberto: um toque fora fecha e limpa a seleção.
	if _menu != null and _menu.is_open():
		_menu.close()
		_clear_selection()
		get_viewport().set_input_as_handled()
		return
	# 3) Tocou num herói posicionado (em qualquer lugar): gerir (Mover/Melhorar/Vender).
	var t := _tower_at(pos)
	if t != null:
		_select(t)
		_pending_tower = t
		_menu.open_manage(t.global_position, t, _gold())
		get_viewport().set_input_as_handled()
		return
	# 4) Tocou num slot vazio: posicionar um herói do esquadrão.
	var si := _slot_at(pos)
	if si >= 0 and _tower_near(slots[si]) == null:
		_open_build(si)
		get_viewport().set_input_as_handled()


func _select(t: Tower) -> void:
	_clear_selection()
	_selected = t
	if is_instance_valid(t):
		t.selected = true


func _clear_selection() -> void:
	if is_instance_valid(_selected):
		_selected.selected = false
	_selected = null
	_move_mode = false


func _on_move_requested() -> void:
	if is_instance_valid(_selected):
		_move_mode = true ## próximo toque no mapa define o destino
	_menu.close()


## Heróis do esquadrão que ainda podem entrar (fora de campo). Cada herói é único.
func _available_squad() -> Array:
	var in_field := {}
	for t in _towers:
		if is_instance_valid(t) and t.data.char_id != "":
			in_field[t.data.char_id] = true
	var out: Array = []
	for d in squad:
		if d.char_id == "":
			continue
		if not in_field.has(d.char_id):
			out.append(d)
	return out


## Exposto para o smoke/--auto-stage posicionar a demo sem UI.
func placeable() -> Array:
	return _available_squad()


func _open_build(si: int) -> void:
	_pending_slot = si
	_pending_tower = null
	_menu.open_build(slots[si], _available_squad(), _gold())


func _on_build_requested(data: TowerData) -> void:
	if _pending_slot < 0:
		return
	if try_place(slots[_pending_slot], data):
		_menu.close()
		queue_redraw()
	_pending_slot = -1


func _on_upgrade_requested() -> void:
	if _pending_tower != null and is_instance_valid(_pending_tower):
		try_upgrade(_pending_tower)
	_menu.close()
	_clear_selection()
	_pending_tower = null


func _on_sell_requested() -> void:
	if _pending_tower != null and is_instance_valid(_pending_tower):
		sell(_pending_tower)
		queue_redraw()
	_menu.close()
	_clear_selection()
	_pending_tower = null


## Unidade construída sobre/perto de um slot (robusto p/ menu e demo).
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


# --- Desenho dos slots vazios ---
func _draw() -> void:
	for i in slots.size():
		if _tower_near(slots[i]) != null:
			continue
		var p: Vector2 = slots[i]
		draw_circle(p + Vector2(0, 3), 20.0, Color(0, 0, 0, 0.25))
		draw_circle(p, 18.0, Color(0.52, 0.40, 0.24, 0.85))
		draw_arc(p, 18.0, 0.0, TAU, 24, Color(0.30, 0.22, 0.12), 3.0)
		# "+" indicando ponto de posicionamento.
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
	t.force_building = (data.char_id == "") ## herói aparece como herói; utilitária = prédio
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
