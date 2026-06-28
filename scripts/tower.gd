class_name Tower
extends Node2D

## Torre estática cujo comportamento vem de um TowerData (data-driven).
## - Arqueiro / Mago: miram e disparam projéteis (Mago com dano em área).
## - Guerreiro: invoca e mantém unidades bloqueadoras no caminho.
## - Sacerdote: irradia uma aura de suporte. A aura é aplicada de forma
##   descentralizada: cada torre/inimigo/bloqueador consulta os Sacerdotes
##   próximos (grupo "priests"), então a ordem de processamento não importa.

var data: TowerData
var waypoints: Array = [] ## usado pelo Guerreiro para achar o caminho

var _cooldown: float = 0.0

# Buffs de aura recalculados a cada frame (Arqueiro/Mago).
var _aura_damage_mult: float = 1.0
var _aura_fire_rate_mult: float = 1.0

# Guerreiro
var _blockers: Array = []
var _respawn_timers: Array = [] ## itens: { "time": float, "slot": int }
var _rally_point: Vector2 = Vector2.ZERO

# Estado global via nó autoload (compilável fora do jogo — ver enemy.gd).
@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(d: TowerData) -> void:
	data = d


func _ready() -> void:
	add_to_group("towers")
	if data != null and data.tower_class == TowerData.TowerClass.PRIEST:
		add_to_group("priests")
	if data != null and data.tower_class == TowerData.TowerClass.WARRIOR:
		_init_warrior()
	queue_redraw()


func _process(delta: float) -> void:
	if data == null or (_state != null and _state.is_over()):
		return
	match data.tower_class:
		TowerData.TowerClass.ARCHER, TowerData.TowerClass.MAGE:
			_recompute_aura_buffs()
			_process_attacker(delta)
		TowerData.TowerClass.WARRIOR:
			_process_warrior(delta)
		TowerData.TowerClass.PRIEST:
			pass # a aura é consultada pelas entidades afetadas


# --- Aura: cada torre soma o melhor buff dos Sacerdotes que a cobrem ---
func _recompute_aura_buffs() -> void:
	_aura_damage_mult = 1.0
	_aura_fire_rate_mult = 1.0
	for p in get_tree().get_nodes_in_group("priests"):
		if not is_instance_valid(p) or p == self:
			continue
		if global_position.distance_to(p.global_position) <= p.data.aura_radius:
			_aura_damage_mult = max(_aura_damage_mult, p.data.aura_damage_mult)
			_aura_fire_rate_mult = max(_aura_fire_rate_mult, p.data.aura_fire_rate_mult)


# --- Arqueiro / Mago ---
func _process_attacker(delta: float) -> void:
	_cooldown -= delta
	var target := _find_target()
	if target != null and _cooldown <= 0.0:
		_shoot(target)
		var eff_fire_rate: float = data.fire_rate * _aura_fire_rate_mult
		_cooldown = 1.0 / max(0.1, eff_fire_rate)


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist: float = data.attack_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best


func _shoot(target: Node2D) -> void:
	var p := Projectile.new()
	get_parent().add_child(p)
	p.global_position = global_position
	var eff_damage: int = int(round(data.damage * _aura_damage_mult))
	p.setup(target, eff_damage, data.splash_radius, data.projectile_color)


# --- Guerreiro ---
func _init_warrior() -> void:
	_rally_point = _nearest_point_on_path(global_position)
	for i in data.blocker_count:
		_spawn_blocker(i)


func _process_warrior(delta: float) -> void:
	for i in range(_respawn_timers.size() - 1, -1, -1):
		_respawn_timers[i]["time"] -= delta
		if _respawn_timers[i]["time"] <= 0.0:
			var slot: int = _respawn_timers[i]["slot"]
			_respawn_timers.remove_at(i)
			_spawn_blocker(slot)


func _spawn_blocker(slot_index: int) -> void:
	var b := BlockerUnit.new()
	b.setup(data.blocker_hp, data.blocker_damage, data.blocker_attack_rate, \
			data.blocker_engage_radius, _hold_position_for(slot_index))
	b.slot_index = slot_index
	b.died.connect(_on_blocker_died)
	get_parent().add_child(b)
	b.global_position = global_position
	_blockers.append(b)


func _on_blocker_died(blocker: Node) -> void:
	_blockers.erase(blocker)
	_respawn_timers.append({"time": data.blocker_respawn_time, "slot": blocker.slot_index})


func _hold_position_for(i: int) -> Vector2:
	# Espalha os bloqueadores ao longo da direção do caminho perto do rally point.
	var dir := _path_direction_at(_rally_point)
	var offset: float = (float(i) - (data.blocker_count - 1) / 2.0) * 34.0
	return _rally_point + dir * offset


func _nearest_point_on_path(p: Vector2) -> Vector2:
	if waypoints.size() < 2:
		return p
	var best := p
	var best_d := INF
	for i in range(waypoints.size() - 1):
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(p, waypoints[i], waypoints[i + 1])
		var d: float = p.distance_to(cp)
		if d < best_d:
			best_d = d
			best = cp
	return best


func _path_direction_at(p: Vector2) -> Vector2:
	if waypoints.size() < 2:
		return Vector2.RIGHT
	var best_d := INF
	var dir := Vector2.RIGHT
	for i in range(waypoints.size() - 1):
		var a: Vector2 = waypoints[i]
		var b: Vector2 = waypoints[i + 1]
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
		var d: float = p.distance_to(cp)
		if d < best_d:
			best_d = d
			dir = (b - a).normalized()
	return dir


func _draw() -> void:
	if data == null:
		return
	draw_rect(Rect2(Vector2(-18, -18), Vector2(36, 36)), data.body_color)
	match data.tower_class:
		TowerData.TowerClass.ARCHER, TowerData.TowerClass.MAGE:
			draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.10), 1.0)
		TowerData.TowerClass.PRIEST:
			draw_arc(Vector2.ZERO, data.aura_radius, 0.0, TAU, 64, Color(0.95, 0.85, 0.2, 0.20), 1.5)
