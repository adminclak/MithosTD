class_name Enemy
extends Node2D

@export var max_hp: int = 12
@export var speed: float = 140.0
@export var gold_reward: int = 8
@export var base_damage: int = 1 ## dano à base ao escapar
@export var attack_damage: int = 3 ## dano corpo-a-corpo nos bloqueadores
@export var attack_rate: float = 1.0 ## ataques por segundo quando bloqueado
@export var body_color: Color = Color(0.85, 0.3, 0.3)

var data: EnemyData = null
var hp: int
var _radius: float = 14.0
var _waypoints: Array = []
var _index: int = 0

# Combate corpo-a-corpo: quando preso por um bloqueador do Guerreiro.
var _blocked_by: Node2D = null
var _attack_cd: float = 0.0

# Status de habilidades.
var _stun_timer: float = 0.0          ## atordoado: para tudo
var _slow_timer: float = 0.0          ## lentidão temporária
var _slow_mult: float = 1.0
var _dot_timer: float = 0.0           ## dano ao longo do tempo (veneno/fogo)
var _dot_dps: float = 0.0
var _dot_accum: float = 0.0

# Animação leve (puro código): balanço ao andar + flash branco ao levar dano.
var _bob: float = 0.0
var _flash: float = 0.0

# Estado global resolvido pelo nó autoload (/root/GameState). Acessar por nó em
# vez do identificador global deixa a entidade compilável fora do jogo (testes
# headless com -s), onde o global não é registrado mas o nó existe.
var _sprite: Texture2D = null

@onready var _state: Node = get_node_or_null(^"/root/GameState")

signal died(enemy)
signal reached_end(enemy)


## Aplica os stats de um EnemyData (data-driven). hp_mult vem da dificuldade da fase.
func apply_data(d: EnemyData, hp_mult: float = 1.0) -> void:
	data = d
	max_hp = int(round(d.max_hp * hp_mult))
	speed = d.speed
	gold_reward = d.gold_reward
	base_damage = d.base_damage
	attack_damage = d.attack_damage
	attack_rate = d.attack_rate
	body_color = d.color
	_radius = d.radius


func setup(points: Array, start_index: int = 0) -> void:
	_waypoints = points.duplicate()
	_index = clampi(start_index, 0, max(0, points.size() - 1))
	if not points.is_empty():
		global_position = points[_index]


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	if data != null:
		_sprite = Art.enemy(data.id)
	if not _waypoints.is_empty():
		global_position = _waypoints[_index]
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _state != null and _state.is_over():
		return

	_process_status(delta)
	if not is_instance_valid(self) or hp <= 0:
		return

	# Atordoado: não move, não luta.
	if _stun_timer > 0.0:
		_stun_timer -= delta
		queue_redraw()
		return

	# Preso por um bloqueador: para e luta em vez de andar.
	if _blocked_by != null:
		if not is_instance_valid(_blocked_by):
			_blocked_by = null
		else:
			_fight(delta)
			return

	if _waypoints.is_empty() or _index >= _waypoints.size():
		return
	var target: Vector2 = _waypoints[_index]
	var spd: float = speed * _aura_speed_mult() * _slow_factor()
	global_position = global_position.move_toward(target, spd * delta)
	_bob += delta * 10.0 # balanço de caminhada
	queue_redraw()
	if global_position.distance_to(target) < 4.0:
		_index += 1
		if _index >= _waypoints.size():
			_reach_end()


func _fight(delta: float) -> void:
	_attack_cd -= delta
	if _attack_cd <= 0.0:
		if _blocked_by.has_method("take_damage"):
			_blocked_by.take_damage(attack_damage)
		_attack_cd = 1.0 / max(0.1, attack_rate)


func _aura_speed_mult() -> float:
	# Menor (mais lento) multiplicador entre os Sacerdotes que cobrem o inimigo.
	var m := 1.0
	for p in get_tree().get_nodes_in_group("priests"):
		if not is_instance_valid(p):
			continue
		if global_position.distance_to(p.global_position) <= p.aura_radius():
			m = min(m, p.aura_slow_mult())
	return m


# Chamado por um BlockerUnit ao prender este inimigo.
func engage(blocker: Node2D) -> void:
	_blocked_by = blocker


# Chamado quando o bloqueador morre/libera.
func release() -> void:
	_blocked_by = null


func is_blocked() -> bool:
	return _blocked_by != null and is_instance_valid(_blocked_by)


func apply_stun(duration: float) -> void:
	_stun_timer = max(_stun_timer, duration)
	queue_redraw()


func is_stunned() -> bool:
	return _stun_timer > 0.0


func apply_slow(mult: float, duration: float) -> void:
	_slow_mult = mult
	_slow_timer = max(_slow_timer, duration)


func is_slowed() -> bool:
	return _slow_timer > 0.0


func apply_dot(dps: float, duration: float) -> void:
	_dot_dps = max(_dot_dps, dps)
	_dot_timer = max(_dot_timer, duration)


func has_dot() -> bool:
	return _dot_timer > 0.0


func knockback(amount: float) -> void:
	if _waypoints.is_empty() or _index >= _waypoints.size():
		return
	var dir: Vector2 = (_waypoints[_index] - global_position).normalized()
	global_position -= dir * amount


func _slow_factor() -> float:
	return _slow_mult if _slow_timer > 0.0 else 1.0


func _process_status(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()
	if _slow_timer > 0.0:
		_slow_timer -= delta
	if _dot_timer > 0.0:
		_dot_timer -= delta
		_dot_accum += _dot_dps * delta
		var whole := int(_dot_accum)
		if whole > 0:
			_dot_accum -= whole
			take_damage(whole, 999) # veneno/fogo ignora defesa
			queue_redraw()


## pen (penetração) fura a defesa do inimigo. element (Elements.E) aplica vantagem/
## desvantagem elemental do atacante contra este inimigo. Dano mínimo de 1.
func take_damage(amount: int, pen: int = 0, element: int = -1) -> void:
	var dealt := amount
	if element >= 0 and data != null:
		dealt = int(round(dealt * Elements.mult(element, data.element)))
	if data != null and data.defense > 0:
		dealt = max(1, dealt - max(0, data.defense - pen))
	hp -= dealt
	_flash = 0.12
	queue_redraw()
	if hp <= 0:
		_die()


func _die() -> void:
	if _state != null:
		_state.add_gold(gold_reward)
	if data != null and data.special == EnemyData.Special.SPLIT and data.split_into != "":
		_spawn_split()
	died.emit(self)
	queue_free()


## Hidra: ao morrer gera filhotes que continuam do mesmo ponto do caminho.
func _spawn_split() -> void:
	var child := GreekBestiary.by_id(data.split_into)
	if child == null:
		return
	for i in data.split_count:
		var c := Enemy.new()
		c.apply_data(child)
		c.setup(_waypoints, _index)
		get_parent().add_child(c)
		c.global_position = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))


func _reach_end() -> void:
	if _state != null:
		_state.take_base_damage(base_damage)
	reached_end.emit(self)
	queue_free()


func _draw() -> void:
	# Sombra (fica fixa no chão).
	draw_circle(Vector2(0, _radius * 0.6), _radius * 0.95, Color(0, 0, 0, 0.20))
	# Balanço vertical da caminhada (o corpo sobe/desce; a sombra não).
	var off := Vector2(0, sin(_bob) * 2.0)
	if _sprite != null:
		var s := _radius * 2.4
		var dest := Rect2(off + Vector2(-s * 0.5, -s * 0.55), Vector2(s, s))
		Anim.draw_swayed(self, _sprite, dest, _bob, 2.6, 0.0, 0.04)
	else:
		# "Monstrinho" placeholder: corpo + olhos (vivos/aterrorizantes).
		draw_circle(off, _radius, body_color)
		draw_arc(off, _radius, 0.0, TAU, 24, Color(0.08, 0.08, 0.08, 0.7), 1.5)
		var eye := _radius * 0.28
		draw_circle(off + Vector2(-_radius * 0.35, -_radius * 0.15), eye, Color(1, 1, 1))
		draw_circle(off + Vector2(_radius * 0.35, -_radius * 0.15), eye, Color(1, 1, 1))
		draw_circle(off + Vector2(-_radius * 0.35, -_radius * 0.15), eye * 0.5, Color(0.8, 0.1, 0.1))
		draw_circle(off + Vector2(_radius * 0.35, -_radius * 0.15), eye * 0.5, Color(0.8, 0.1, 0.1))
	# Flash branco ao levar dano.
	if _flash > 0.0:
		draw_circle(off, _radius, Color(1, 1, 1, clampf(_flash / 0.12, 0.0, 1.0) * 0.55))
	# Barra de vida acima do corpo (largura proporcional ao tamanho).
	var bar_width: float = _radius * 2.0
	var bar_height: float = 4.0
	var bar_pos: Vector2 = Vector2(-_radius, -_radius - 10.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.1, 0.1, 0.1))
	var ratio: float = 0.0
	if max_hp > 0:
		ratio = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * ratio, bar_height)), Color(0.2, 0.8, 0.2))
	# Atordoado: anel ciano em volta.
	if _stun_timer > 0.0:
		draw_arc(Vector2.ZERO, _radius + 2.0, 0.0, TAU, 20, Color(0.6, 0.9, 1.0), 2.0)
