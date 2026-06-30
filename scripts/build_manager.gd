class_name BuildManager
extends Node2D

## Posicionamento do Mithos TD (modelo: HERÓIS são as unidades, SEM slots).
## - O jogador ARRASTA um herói da barra inferior (HeroBar) para o mapa: place_at()
##   valida (dentro do campo, FORA da estrada, sem sobrepor) e posiciona com ouro.
## - Toca num herói posicionado -> menu Mover/Melhorar/Vender.
##   "Mover" deixa o herói SOLTO (arrasta livre, não ataca, toma dano) até clicar OK.
## A economia (try_place/try_upgrade/sell/can_place) fica testável via /root/GameState.

const MIN_SPACING := 42.0
const PATH_CLEAR := 40.0       ## distância mínima da estrada (não pode posicionar nela)
const BOUNDS := Rect2(24, 90, 1232, 540)

signal changed ## posicionou/vendeu -> a barra de heróis se atualiza

var waypoints: Array = []
var squad: Array = []
var damage_mult: float = 1.0

var _towers: Array = []
var _menu: BuildMenu = null
var _selected: Tower = null
var _pending_tower: Tower = null
var _moving_tower: Tower = null ## herói em move_mode (sendo arrastado p/ reposicionar)
var _ok_layer: CanvasLayer = null
var _ok_btn: Button = null

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(wpoints: Array, squad_datas: Array = [], dmg_mult: float = 1.0) -> void:
	waypoints = wpoints.duplicate()
	squad = squad_datas.duplicate()
	damage_mult = dmg_mult


func _ready() -> void:
	_menu = BuildMenu.new()
	add_child(_menu)
	_menu.upgrade_requested.connect(_on_upgrade_requested)
	_menu.sell_requested.connect(_on_sell_requested)
	_menu.move_requested.connect(_on_move_requested)
	# Botão OK (confirmar reposicionamento), escondido fora do move mode.
	_ok_layer = CanvasLayer.new()
	_ok_layer.layer = 9
	add_child(_ok_layer)
	_ok_btn = Button.new()
	_ok_btn.text = "OK — fixar aqui"
	_ok_btn.add_theme_font_size_override("font_size", 20)
	_ok_btn.custom_minimum_size = Vector2(220, 50)
	_ok_btn.position = Vector2(530, 70)
	_ok_btn.visible = false
	_ok_btn.pressed.connect(_confirm_move)
	_ok_layer.add_child(_ok_btn)


# --- Heróis ainda fora de campo (mostrados na barra) ---
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


func placeable() -> Array:
	return _available_squad()


# --- Entrada: arrastar o herói SOLTO (move mode) ou tocar p/ gerir ---
func _unhandled_input(event: InputEvent) -> void:
	if _state != null and _state.is_over():
		return
	# Em move mode: arrastar/clicar no campo reposiciona o herói (se o ponto é válido).
	if _moving_tower != null and is_instance_valid(_moving_tower):
		var do_move := false
		if event is InputEventMouseMotion:
			do_move = ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			do_move = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		if do_move:
			var p := get_global_mouse_position()
			if _can_stand(p, _moving_tower):
				_moving_tower.reposition(p)
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := get_global_mouse_position()
	# Painel aberto: toque fora fecha.
	if _menu != null and _menu.is_open():
		_menu.close()
		_clear_selection()
		get_viewport().set_input_as_handled()
		return
	# Tocou num herói posicionado -> gerir (Mover/Melhorar/Vender).
	var t := _tower_at(pos)
	if t != null:
		_select(t)
		_pending_tower = t
		_menu.open_manage(t.global_position, t, _gold())
		get_viewport().set_input_as_handled()


func _on_move_requested() -> void:
	if not is_instance_valid(_selected):
		return
	_menu.close()
	_moving_tower = _selected
	_moving_tower.set_move_mode(true)
	_ok_btn.visible = true


func _confirm_move() -> void:
	if is_instance_valid(_moving_tower):
		_moving_tower.set_move_mode(false)
	_moving_tower = null
	_ok_btn.visible = false
	_clear_selection()


func _on_upgrade_requested() -> void:
	if is_instance_valid(_pending_tower):
		try_upgrade(_pending_tower)
	_menu.close()
	_clear_selection()
	_pending_tower = null


func _on_sell_requested() -> void:
	if is_instance_valid(_pending_tower):
		sell(_pending_tower)
	_menu.close()
	_clear_selection()
	_pending_tower = null
	changed.emit()


func _select(t: Tower) -> void:
	_clear_selection()
	_selected = t
	if is_instance_valid(t):
		t.selected = true


func _clear_selection() -> void:
	if is_instance_valid(_selected):
		_selected.selected = false
	_selected = null


# --- Validação / economia ---
## Distância do ponto à estrada (polilinha dos waypoints).
func _dist_to_path(p: Vector2) -> float:
	var best := 1e20
	for i in range(waypoints.size() - 1):
		var d: float = _dist_to_seg(p, waypoints[i], waypoints[i + 1])
		if d < best:
			best = d
	return best


func _dist_to_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = 0.0
	var len2 := ab.length_squared()
	if len2 > 0.0:
		t = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Pode posicionar um NOVO herói aqui? (no campo, fora da estrada, sem sobrepor)
func can_place(pos: Vector2) -> bool:
	if not BOUNDS.has_point(pos):
		return false
	if _dist_to_path(pos) < PATH_CLEAR:
		return false
	for t in _towers:
		if is_instance_valid(t) and t.global_position.distance_to(pos) < MIN_SPACING:
			return false
	return true


## Pode um herói EXISTENTE parar aqui (ao mover)? Igual a can_place, mas ignora a si.
func _can_stand(pos: Vector2, who: Tower) -> bool:
	if not BOUNDS.has_point(pos):
		return false
	if _dist_to_path(pos) < PATH_CLEAR:
		return false
	for t in _towers:
		if is_instance_valid(t) and t != who and t.global_position.distance_to(pos) < MIN_SPACING:
			return false
	return true


func _tower_at(pos: Vector2) -> Tower:
	var best: Tower = null
	var best_d := 34.0
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


## Posiciona o herói arrastado da barra. Retorna true se conseguiu (válido + ouro).
func place_at(pos: Vector2, data: TowerData) -> bool:
	var ok := try_place(pos, data)
	if ok:
		changed.emit()
	return ok


func try_place(pos: Vector2, data: TowerData) -> bool:
	if not can_place(pos):
		return false
	if _state == null or not _state.try_spend(data.cost):
		return false
	var t := Tower.new()
	t.force_building = false ## herói sempre aparece como herói (nunca prédio)
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
