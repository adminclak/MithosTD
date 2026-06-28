class_name BuildManager
extends Node2D

## Posicionamento estilo Kingdom Rush:
## - O jogador clica num herói na SquadBar (rodapé) -> entra em modo de colocação.
## - Um "fantasma" (PlacementGhost) segue o mouse, verde (pode) / vermelho (não).
## - Clique esquerdo posiciona (valida limites, espaçamento e ouro); direito/ESC cancela.
## - Clique numa torre já em campo abre a gestão (upar/vender).
## Sem zonas — qualquer herói em qualquer lugar válido (melee tanka onde for posto).

const CLICK_RADIUS := 26.0
const MIN_SPACING := 38.0
const BOUNDS := Rect2(20, 20, 1240, 600) ## área jogável (acima da SquadBar)

var waypoints: Array = []
var squad: Array = []

var _towers: Array = []
var _menu: BuildMenu = null
var _active_tower: Tower = null
var _placing: TowerData = null
var _ghost: PlacementGhost = null
var _toast: Label = null

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(wpoints: Array, squad_datas: Array = []) -> void:
	waypoints = wpoints.duplicate()
	squad = squad_datas.duplicate()


func _ready() -> void:
	_menu = BuildMenu.new()
	add_child(_menu)
	_menu.upgrade_requested.connect(_on_upgrade_requested)
	_menu.sell_requested.connect(_on_sell_requested)
	_menu.closed.connect(_on_menu_closed)
	_ghost = PlacementGhost.new()
	add_child(_ghost)


func _process(_delta: float) -> void:
	if _placing != null:
		var pos := get_global_mouse_position()
		_ghost.position = pos
		_ghost.valid = can_place(_placing.tower_class, pos) and _gold() >= _placing.cost
		_ghost.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _state != null and _state.is_over():
		return
	if event is InputEventMouseButton and event.pressed:
		if _placing != null:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var pos := get_global_mouse_position()
				if can_place(_placing.tower_class, pos) and _gold() >= _placing.cost:
					try_place(pos, _placing)
					_stop_placing()
				else:
					var why := _place_reason(_placing.tower_class, pos)
					_show_toast(pos, why if why != "" else "sem ouro")
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_stop_placing()
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var t := _tower_at(get_global_mouse_position())
			if t != null:
				_active_tower = t
				_menu.open_manage(t.global_position, t, _gold())
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _placing != null:
			_stop_placing()
			get_viewport().set_input_as_handled()


# --- Modo de colocação (chamado pela SquadBar) ---
func start_placing(data: TowerData) -> void:
	_placing = data
	_close_menu()
	_ghost.show_for(data)


func _stop_placing() -> void:
	_placing = null
	_ghost.clear()


# --- Validação ---
func can_place(_tower_class: int, pos: Vector2) -> bool:
	if not BOUNDS.has_point(pos):
		return false
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < MIN_SPACING:
			return false
	return true


func _place_reason(_tower_class: int, pos: Vector2) -> String:
	if not BOUNDS.has_point(pos):
		return "fora do mapa"
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < MIN_SPACING:
			return "perto demais"
	return ""


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


# --- Economia (sem UI — testável) ---
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


# --- Sinais do BuildMenu (gestão) ---
func _on_upgrade_requested() -> void:
	if _active_tower != null:
		try_upgrade(_active_tower)
	if _active_tower != null and is_instance_valid(_active_tower):
		_menu.open_manage(_active_tower.global_position, _active_tower, _gold())
	else:
		_close_menu()


func _on_sell_requested() -> void:
	if _active_tower != null:
		sell(_active_tower)
	_close_menu()


func _on_menu_closed() -> void:
	_active_tower = null


func _close_menu() -> void:
	if _menu != null:
		_menu.close()


func _show_toast(pos: Vector2, msg: String) -> void:
	if msg == "":
		return
	if _toast == null:
		_toast = Label.new()
		_toast.add_theme_font_size_override("font_size", 20)
		_toast.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		add_child(_toast)
	_toast.text = "Nao da pra posicionar (%s)" % msg
	_toast.position = pos + Vector2(-80, -36)
	_toast.visible = true
	_toast.z_index = 120
	get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(_toast): _toast.visible = false)
