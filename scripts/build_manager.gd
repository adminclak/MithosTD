class_name BuildManager
extends Node2D

## Orquestra os slots de torre: captura o clique (por proximidade do mouse),
## abre o menu (BuildMenu) e executa a economia. A lógica de gasto fica em
## try_build/try_upgrade/sell (sem UI), o que a deixa testável headless.

const CLICK_RADIUS := 34.0

var waypoints: Array = []
var slot_positions: Array = []
var squad: Array = [] ## TowerData (com char_id) do esquadrão levado à fase

var _slots: Array = [] ## TowerSlot
var _menu: BuildMenu = null
var _active_slot: TowerSlot = null

# Estado global via nó autoload (compilável/testável fora do jogo — ver enemy.gd).
@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(positions: Array, wpoints: Array, squad_datas: Array = []) -> void:
	slot_positions = positions.duplicate()
	waypoints = wpoints.duplicate()
	squad = squad_datas.duplicate()


func _ready() -> void:
	for pos in slot_positions:
		var s := TowerSlot.new()
		s.position = pos
		add_child(s)
		_slots.append(s)
	_menu = BuildMenu.new()
	add_child(_menu)
	_menu.build_requested.connect(_on_build_requested)
	_menu.upgrade_requested.connect(_on_upgrade_requested)
	_menu.sell_requested.connect(_on_sell_requested)
	_menu.closed.connect(_on_menu_closed)


func _unhandled_input(event: InputEvent) -> void:
	if _state != null and _state.is_over():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var slot := _slot_at(get_global_mouse_position())
		if slot != null:
			_open_for(slot)
		else:
			_close_menu()


func _slot_at(world: Vector2) -> TowerSlot:
	var best: TowerSlot = null
	var best_d := CLICK_RADIUS
	for s in _slots:
		var d: float = s.global_position.distance_to(world)
		if d <= best_d:
			best_d = d
			best = s
	return best


func _open_for(slot: TowerSlot) -> void:
	_set_active(slot)
	if slot.is_empty():
		_menu.open_build(slot.global_position, _available_squad(), _gold())
	else:
		_menu.open_manage(slot.global_position, slot.tower, _gold())


## Personagens do esquadrão que ainda não estão em campo (cada um é único).
## Sem esquadrão definido, cai nas 4 classes genéricas (modo de protótipo).
func _available_squad() -> Array:
	if squad.is_empty():
		return TowerData.all_classes()
	var in_field := {}
	for s in _slots:
		if not s.is_empty() and s.tower.data.char_id != "":
			in_field[s.tower.data.char_id] = true
	var out: Array = []
	for d in squad:
		if not in_field.has(d.char_id):
			out.append(d)
	return out


func _set_active(slot) -> void:
	if _active_slot != null and is_instance_valid(_active_slot):
		_active_slot.set_highlighted(false)
	_active_slot = slot
	if slot != null:
		slot.set_highlighted(true)


func _close_menu() -> void:
	_set_active(null)
	if _menu != null:
		_menu.close()


func _gold() -> int:
	return _state.gold if _state != null else 0


# --- Economia (sem UI — testável) ---
func try_build(slot: TowerSlot, data: TowerData) -> bool:
	if not slot.is_empty():
		return false
	if _state == null or not _state.try_spend(data.cost):
		return false
	var t := Tower.new()
	t.setup(data)
	t.waypoints = waypoints
	t.position = slot.position
	add_child(t)
	slot.tower = t
	slot.queue_redraw()
	return true


func try_upgrade(slot: TowerSlot) -> bool:
	if slot.is_empty():
		return false
	var t: Tower = slot.tower
	if not t.can_upgrade():
		return false
	if _state == null or not _state.try_spend(t.upgrade_cost()):
		return false
	t.apply_upgrade()
	return true


func sell(slot: TowerSlot) -> bool:
	if slot.is_empty():
		return false
	var t: Tower = slot.tower
	if _state != null:
		_state.add_gold(t.sell_value())
	t.queue_free()
	slot.tower = null
	slot.queue_redraw()
	return true


# --- Sinais vindos do BuildMenu ---
func _on_build_requested(data: TowerData) -> void:
	if _active_slot != null:
		try_build(_active_slot, data)
	_close_menu()


func _on_upgrade_requested() -> void:
	if _active_slot != null:
		try_upgrade(_active_slot)
	# Reabre o menu de gestão com o estado atualizado (permite upar/vender de novo).
	if _active_slot != null and not _active_slot.is_empty():
		_menu.open_manage(_active_slot.global_position, _active_slot.tower, _gold())
	else:
		_close_menu()


func _on_sell_requested() -> void:
	if _active_slot != null:
		sell(_active_slot)
	_close_menu()


func _on_menu_closed() -> void:
	_set_active(null)
