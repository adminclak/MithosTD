class_name Enemy
extends Node2D

@export var max_hp: int = 12
@export var speed: float = 140.0
@export var gold_reward: int = 8
@export var base_damage: int = 1
@export var body_color: Color = Color(0.85, 0.3, 0.3)

var hp: int
var _waypoints: Array = []
var _index: int = 0

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
	if GameState.is_over():
		return
	if _waypoints.is_empty() or _index >= _waypoints.size():
		return
	var target: Vector2 = _waypoints[_index]
	global_position = global_position.move_toward(target, speed * delta)
	if global_position.distance_to(target) < 4.0:
		_index += 1
		if _index >= _waypoints.size():
			_reach_end()


func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		_die()


func _die() -> void:
	GameState.add_gold(gold_reward)
	died.emit(self)
	queue_free()


func _reach_end() -> void:
	GameState.take_base_damage(base_damage)
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
