class_name BuildManager
extends Node2D

## Posicionamento LIVRE com zonas: o jogador clica em qualquer lugar do mapa.
## - Guerreiro (melee) só pode ficar perto da rota (zona do meio).
## - Arqueiro/Mago/Sacerdote (ranged) só nas laterais (longe da rota).
## Também valida limites do mapa, espaçamento entre torres e unicidade do
## esquadrão. A lógica (try_place/try_upgrade/sell/can_place) é sem UI e testável.

const CLICK_RADIUS := 26.0     ## clicar perto de uma torre abre a gestão dela
const MELEE_BAND := 48.0       ## dist. à rota <= isto = zona melee (Guerreiro)
const MIN_SPACING := 40.0      ## distância mínima entre torres
const BOUNDS := Rect2(24, 24, 1232, 672)

var waypoints: Array = []
var squad: Array = []          ## TowerData (com char_id) do esquadrão

var _towers: Array = []        ## Tower posicionadas
var _menu: BuildMenu = null
var _active_tower: Tower = null
var _pending_pos: Vector2 = Vector2.ZERO
var _zone_line: Line2D = null
var _toast: Label = null

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(wpoints: Array, squad_datas: Array = []) -> void:
	waypoints = wpoints.duplicate()
	squad = squad_datas.duplicate()


func _ready() -> void:
	# Faixa translúcida mostrando a zona do meio (corpo-a-corpo / Guerreiro).
	_zone_line = Line2D.new()
	_zone_line.points = PackedVector2Array(waypoints)
	_zone_line.width = MELEE_BAND * 2.0
	_zone_line.default_color = Color(0.85, 0.3, 0.3, 0.10)
	_zone_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_zone_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_zone_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_zone_line)

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
		var pos := get_global_mouse_position()
		var t := _tower_at(pos)
		if t != null:
			_active_tower = t
			_pending_pos = Vector2.ZERO
			_menu.open_manage(t.global_position, t, _gold())
		else:
			_active_tower = null
			_pending_pos = pos
			_menu.open_build(pos, _build_entries(pos), _gold())


# --- Validação de zona / posição ---
func dist_to_path(p: Vector2) -> float:
	if waypoints.size() < 2:
		return INF
	var best := INF
	for i in range(waypoints.size() - 1):
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(p, waypoints[i], waypoints[i + 1])
		best = min(best, p.distance_to(cp))
	return best


func is_melee_class(tower_class: int) -> bool:
	return tower_class == TowerData.TowerClass.WARRIOR


func can_place(tower_class: int, pos: Vector2) -> bool:
	if not BOUNDS.has_point(pos):
		return false
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < MIN_SPACING:
			return false
	var d := dist_to_path(pos)
	if is_melee_class(tower_class):
		return d <= MELEE_BAND # Guerreiro fica no meio (sobre/junto à rota)
	return d > MELEE_BAND      # ranged fica nas laterais


func _place_reason(tower_class: int, pos: Vector2) -> String:
	if not BOUNDS.has_point(pos):
		return "fora do mapa"
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < MIN_SPACING:
			return "perto demais"
	var d := dist_to_path(pos)
	if is_melee_class(tower_class) and d > MELEE_BAND:
		return "melee: so no meio"
	if not is_melee_class(tower_class) and d <= MELEE_BAND:
		return "ranged: so na lateral"
	return ""


func _build_entries(pos: Vector2) -> Array:
	var entries: Array = []
	for d in _available_squad():
		entries.append({"data": d, "allowed": can_place(d.tower_class, pos), \
			"reason": _place_reason(d.tower_class, pos)})
	return entries


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
		var d: float = t.global_position.distance_to(pos)
		if d <= best_d:
			best_d = d
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


# --- Sinais do BuildMenu ---
func _on_build_requested(data: TowerData) -> void:
	if not try_place(_pending_pos, data):
		_show_toast(_place_reason(data.tower_class, _pending_pos))
	_close_menu()


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


func _show_toast(msg: String) -> void:
	if msg == "":
		return
	if _toast == null:
		_toast = Label.new()
		_toast.add_theme_font_size_override("font_size", 22)
		_toast.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		add_child(_toast)
	_toast.text = "Nao pode posicionar aqui (%s)" % msg
	_toast.position = _pending_pos + Vector2(-90, -40)
	_toast.visible = true
	get_tree().create_timer(1.3).timeout.connect(func(): if is_instance_valid(_toast): _toast.visible = false)
