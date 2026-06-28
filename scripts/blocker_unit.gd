class_name BlockerUnit
extends Node2D

## Unidade invocada pelo Guerreiro. Anda até um ponto no caminho e segura a
## linha: ao encontrar um inimigo livre, o prende em combate corpo-a-corpo
## (ambos trocam dano nos próprios timers). Pode ser curada pela aura do
## Sacerdote. Ao morrer, libera o inimigo e avisa o Guerreiro para respawn.

@export var move_speed: float = 120.0

var max_hp: int = 30
var hp: int = 0
var attack_damage: int = 4
var attack_rate: float = 1.0 ## ataques por segundo
var engage_radius: float = 50.0
var hold_position: Vector2 = Vector2.ZERO
var slot_index: int = 0
var body_color: Color = Color(0.85, 0.25, 0.25)

var _target_enemy: Node2D = null
var _attack_cd: float = 0.0
var _at_hold: bool = false
var _heal_accum: float = 0.0
var _shield_timer: float = 0.0 ## invulnerável enquanto > 0 (Força Indomável)

# Estado global via nó autoload (compilável fora do jogo — ver enemy.gd).
@onready var _state: Node = get_node_or_null(^"/root/GameState")

signal died(blocker)


func setup(hp_: int, dmg: int, rate: float, radius: float, hold: Vector2, move_spd: float = 120.0) -> void:
	max_hp = max(1, hp_)
	hp = max_hp
	attack_damage = dmg
	attack_rate = rate
	engage_radius = radius
	hold_position = hold
	move_speed = move_spd


func _ready() -> void:
	add_to_group("blockers")
	if hp <= 0:
		hp = max_hp
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _state != null and _state.is_over():
		return
	if _shield_timer > 0.0:
		_shield_timer -= delta
	_heal_from_auras(delta)

	# Vai até o ponto de bloqueio no caminho antes de combater.
	if not _at_hold:
		global_position = global_position.move_toward(hold_position, move_speed * delta)
		if global_position.distance_to(hold_position) < 2.0:
			_at_hold = true
		return

	# Solta o alvo se ele morreu/saiu.
	if _target_enemy != null and not is_instance_valid(_target_enemy):
		_target_enemy = null

	# Procura um inimigo livre para prender.
	if _target_enemy == null:
		_target_enemy = _find_enemy()
		if _target_enemy != null and _target_enemy.has_method("engage"):
			_target_enemy.engage(self)

	# Combate: bate no timer.
	if _target_enemy != null:
		_attack_cd -= delta
		if _attack_cd <= 0.0:
			if _target_enemy.has_method("take_damage"):
				_target_enemy.take_damage(attack_damage)
			_attack_cd = 1.0 / max(0.1, attack_rate)


func _find_enemy() -> Node2D:
	var best: Node2D = null
	var best_d: float = engage_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.has_method("is_blocked") and e.is_blocked():
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _heal_from_auras(delta: float) -> void:
	if hp >= max_hp:
		return
	var heal_rate := 0.0
	for p in get_tree().get_nodes_in_group("priests"):
		if not is_instance_valid(p):
			continue
		if global_position.distance_to(p.global_position) <= p.aura_radius():
			heal_rate = max(heal_rate, p.aura_heal_per_sec())
	if heal_rate > 0.0:
		_heal_accum += heal_rate * delta
		var whole := int(_heal_accum)
		if whole > 0:
			hp = min(max_hp, hp + whole)
			_heal_accum -= whole
			queue_redraw()


func take_damage(amount: int) -> void:
	if _shield_timer > 0.0:
		return # invulnerável
	hp -= amount
	queue_redraw()
	if hp <= 0:
		_die()


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	queue_redraw()


func apply_shield(duration: float) -> void:
	_shield_timer = max(_shield_timer, duration)
	queue_redraw()


func _die() -> void:
	if is_instance_valid(_target_enemy) and _target_enemy.has_method("release"):
		_target_enemy.release()
	died.emit(self)
	queue_free()


func _draw() -> void:
	# Corpo: quadrado menor que a torre.
	draw_rect(Rect2(Vector2(-11, -11), Vector2(22, 22)), body_color)
	# Barra de vida.
	var bar_pos := Vector2(-12.0, -20.0)
	var bar_w := 24.0
	var bar_h := 3.0
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.1, 0.1, 0.1))
	var ratio := 0.0
	if max_hp > 0:
		ratio = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, bar_h)), Color(0.95, 0.75, 0.2))
	# Escudo ativo: anel dourado.
	if _shield_timer > 0.0:
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 20, Color(1.0, 0.95, 0.5), 2.0)
