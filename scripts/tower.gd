class_name Tower
extends Node2D

## Torre estática cujo comportamento vem de um TowerData (data-driven).
## - Arqueiro / Mago: miram e disparam projéteis (Mago com dano em área).
## - Guerreiro: invoca e mantém unidades bloqueadoras no caminho.
## - Sacerdote: irradia uma aura de suporte. A aura é aplicada de forma
##   descentralizada: cada torre/inimigo/bloqueador consulta os Sacerdotes
##   próximos (grupo "priests") chamando os métodos aura_*() — que já embutem
##   o nível atual da torre.
##
## Upgrade temporário de partida: nível 1→2→3, cada nível intensifica os stats
## (_stat_mult) e custa ouro (calculado aqui; quem debita é o BuildManager).

const MAX_LEVEL := 3
const LEVEL_STAT_STEP := 0.35  ## +35% nos stats principais por nível acima do 1
const UPGRADE_COST_FACTOR := 0.6 ## custo do 1º upgrade ≈ 60% do custo de invocar
const UPGRADE_COST_GROWTH := 1.6 ## cada upgrade seguinte ≈ +60% do anterior
const SELL_RATE := 0.6 ## devolve 60% do ouro investido ao vender

var data: TowerData
var waypoints: Array = [] ## usado pelo Guerreiro para achar o caminho
var level: int = 1
var invested_gold: int = 0 ## total gasto (invocar + upgrades), base da venda

var _cooldown: float = 0.0

# Buffs de aura recalculados a cada frame (Arqueiro/Mago).
var _aura_damage_mult: float = 1.0
var _aura_fire_rate_mult: float = 1.0

# Habilidade ativa de assinatura (cooldown) e buff temporário que ela concede.
var _ability_cd: float = 0.0
var _temp_buff_mult: float = 1.0
var _temp_buff_timer: float = 0.0

# Guerreiro
var _blockers: Array = []
var _respawn_timers: Array = [] ## itens: { "time": float, "slot": int }
var _rally_point: Vector2 = Vector2.ZERO

# Estado global via nó autoload (compilável fora do jogo — ver enemy.gd).
@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(d: TowerData) -> void:
	data = d
	invested_gold = d.cost


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
	if _ability_cd > 0.0:
		_ability_cd -= delta
	if _temp_buff_timer > 0.0:
		_temp_buff_timer -= delta
	match data.tower_class:
		TowerData.TowerClass.ARCHER, TowerData.TowerClass.MAGE:
			_recompute_aura_buffs()
			_process_attacker(delta)
		TowerData.TowerClass.WARRIOR:
			_process_warrior(delta)
		TowerData.TowerClass.PRIEST:
			pass # a aura é consultada pelas entidades afetadas


# --- Upgrade / venda ---
func _stat_mult() -> float:
	return 1.0 + (level - 1) * LEVEL_STAT_STEP


func can_upgrade() -> bool:
	return level < MAX_LEVEL


func upgrade_cost() -> int:
	return int(round(data.cost * UPGRADE_COST_FACTOR * pow(UPGRADE_COST_GROWTH, level - 1)))


func sell_value() -> int:
	return int(round(invested_gold * SELL_RATE))


## Sobe um nível e registra o gasto. Não debita ouro (o BuildManager faz isso).
func apply_upgrade() -> void:
	if not can_upgrade():
		return
	invested_gold += upgrade_cost()
	level += 1
	queue_redraw()


# --- Aura efetiva (já com o nível embutido) — consultada pelas entidades ---
func aura_radius() -> float:
	return data.aura_radius


func aura_damage_mult() -> float:
	return 1.0 + (data.aura_damage_mult - 1.0) * _stat_mult()


func aura_fire_rate_mult() -> float:
	return 1.0 + (data.aura_fire_rate_mult - 1.0) * _stat_mult()


func aura_slow_mult() -> float:
	# data.aura_slow_mult é < 1 (lentidão); o nível torna a lentidão mais forte.
	return clampf(1.0 - (1.0 - data.aura_slow_mult) * _stat_mult(), 0.2, 1.0)


func aura_heal_per_sec() -> float:
	return data.aura_heal_per_sec * _stat_mult()


# --- Buff que esta torre recebe dos Sacerdotes que a cobrem ---
func _recompute_aura_buffs() -> void:
	_aura_damage_mult = 1.0
	_aura_fire_rate_mult = 1.0
	for p in get_tree().get_nodes_in_group("priests"):
		if not is_instance_valid(p) or p == self:
			continue
		if global_position.distance_to(p.global_position) <= p.aura_radius():
			_aura_damage_mult = max(_aura_damage_mult, p.aura_damage_mult())
			_aura_fire_rate_mult = max(_aura_fire_rate_mult, p.aura_fire_rate_mult())


# --- Arqueiro / Mago ---
func _process_attacker(delta: float) -> void:
	_cooldown -= delta
	var target := _find_target()
	if target != null and _cooldown <= 0.0:
		_shoot(target)
		var eff_fire_rate: float = data.fire_rate * _stat_mult() * _aura_fire_rate_mult * _temp_mult()
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
	var eff_damage: int = int(round(data.damage * _stat_mult() * _aura_damage_mult * _temp_mult()))
	# Crítico (derivado de LUK/DEX).
	var col: Color = data.projectile_color
	if randf() < data.crit_chance:
		eff_damage = int(round(eff_damage * data.crit_mult))
		col = Color(1.0, 0.55, 0.2) # projétil laranja no crit
	p.setup(target, eff_damage, data.splash_radius, col)


func _temp_mult() -> float:
	return _temp_buff_mult if _temp_buff_timer > 0.0 else 1.0


# --- Habilidade ativa ---
func has_ability() -> bool:
	return data != null and data.ability != null


func ability_cooldown_left() -> float:
	return max(0.0, _ability_cd)


func apply_temp_buff(mult: float, dur: float) -> void:
	var current := _temp_buff_mult if _temp_buff_timer > 0.0 else 1.0
	_temp_buff_mult = max(current, mult)
	_temp_buff_timer = max(_temp_buff_timer, dur)


## Dispara a habilidade do personagem (se houver e fora de cooldown).
func use_ability() -> bool:
	if not has_ability() or _ability_cd > 0.0:
		return false
	var ab: AbilityData = data.ability
	_ability_cd = ab.cooldown
	match ab.kind:
		AbilityData.Kind.DAMAGE_AOE:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)))
		AbilityData.Kind.STUN_AOE:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)))
				if e.has_method("apply_stun"):
					e.apply_stun(ab.duration)
		AbilityData.Kind.BUFF_TOWER:
			for t in _towers_in(ab.radius):
				t.apply_temp_buff(ab.power, ab.duration)
		AbilityData.Kind.HEAL_BLOCKERS:
			for b in _blockers_in(ab.radius):
				b.heal(int(round(ab.power)))
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power * 0.4)))
		AbilityData.Kind.SHIELD_BLOCKERS:
			for b in _blockers_in(ab.radius):
				b.apply_shield(ab.duration)
	return true


func _enemies_in(r: float) -> Array:
	return _nodes_in_group_within("enemies", r)


func _blockers_in(r: float) -> Array:
	return _nodes_in_group_within("blockers", r)


func _towers_in(r: float) -> Array:
	return _nodes_in_group_within("towers", r)


func _nodes_in_group_within(group: String, r: float) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group(group):
		if is_instance_valid(n) and global_position.distance_to(n.global_position) <= r:
			out.append(n)
	return out


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
	var hp: int = int(round(data.blocker_hp * _stat_mult()))
	var dmg: int = int(round(data.blocker_damage * _stat_mult()))
	b.setup(hp, dmg, data.blocker_attack_rate, data.blocker_engage_radius, \
			_hold_position_for(slot_index), data.blocker_move_speed)
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
	var c: Color = data.body_color
	var dark := Color(c.r * 0.45, c.g * 0.45, c.b * 0.45)
	var faint := Color(c.r, c.g, c.b, 0.07)
	# Sombra sob a torre.
	draw_circle(Vector2(0, 5), 18.0, Color(0, 0, 0, 0.22))
	# Forma própria por classe.
	match data.tower_class:
		TowerData.TowerClass.ARCHER:
			draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, faint, 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -19), Vector2(17, 15), Vector2(-17, 15)]), c)
		TowerData.TowerClass.MAGE:
			draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, faint, 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -19), Vector2(18, 0), Vector2(0, 19), Vector2(-18, 0)]), c)
		TowerData.TowerClass.WARRIOR:
			draw_rect(Rect2(-16, -16, 32, 32), c)
			draw_rect(Rect2(-16, -16, 32, 32), dark, false, 2.0)
		TowerData.TowerClass.PRIEST:
			draw_arc(Vector2.ZERO, data.aura_radius, 0.0, TAU, 64, Color(c.r, c.g, c.b, 0.14), 1.5)
			draw_circle(Vector2.ZERO, 17.0, c)
			draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, dark, 2.0)
	# Pips de nível (acima da torre): 1 a 3 marcadores dourados.
	for i in level:
		draw_rect(Rect2(Vector2(-18 + i * 8, -32), Vector2(6, 5)), Color(1.0, 0.9, 0.3))
