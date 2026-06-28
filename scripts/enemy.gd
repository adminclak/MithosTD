class_name Enemy
extends Node2D

@export var max_hp: int = 12
@export var speed: float = 140.0
@export var gold_reward: int = 8
@export var base_damage: int = 1 ## dano à base ao escapar
@export var attack_damage: int = 3 ## dano corpo-a-corpo nos bloqueadores
@export var attack_rate: float = 1.0 ## ataques por segundo quando bloqueado
@export var body_color: Color = Color(0.85, 0.3, 0.3)

var hp: int
var _waypoints: Array = []
var _index: int = 0

# Combate corpo-a-corpo: quando preso por um bloqueador do Guerreiro.
var _blocked_by: Node2D = null
var _attack_cd: float = 0.0

# Estado global resolvido pelo nó autoload (/root/GameState). Acessar por nó em
# vez do identificador global deixa a entidade compilável fora do jogo (testes
# headless com -s), onde o global não é registrado mas o nó existe.
@onready var _state: Node = get_node_or_null(^"/root/GameState")

signal died(enemy)
signal reached_end(enemy)


func setup(points: Array) -> void:
	_waypoints = points.duplicate()
	_index = 0
	if not points.is_empty():
		global_position = points[0]


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	if not _waypoints.is_empty():
		global_position = _waypoints[0]
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _state != null and _state.is_over():
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
	var spd: float = speed * _aura_speed_mult()
	global_position = global_position.move_toward(target, spd * delta)
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


func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		_die()


func _die() -> void:
	if _state != null:
		_state.add_gold(gold_reward)
	died.emit(self)
	queue_free()


func _reach_end() -> void:
	if _state != null:
		_state.take_base_damage(base_damage)
	reached_end.emit(self)
	queue_free()


func _draw() -> void:
	# Corpo do inimigo: circulo preenchido na cor body_color.
	draw_circle(Vector2.ZERO, 14.0, body_color)
	# Barra de vida acima do corpo.
	var bar_pos: Vector2 = Vector2(-14.0, -24.0)
	var bar_width: float = 28.0
	var bar_height: float = 4.0
	# Fundo escuro da barra.
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.1, 0.1, 0.1))
	# Proporcao de vida atual em verde.
	var ratio: float = 0.0
	if max_hp > 0:
		ratio = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * ratio, bar_height)), Color(0.2, 0.8, 0.2))
