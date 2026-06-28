class_name Tower
extends Node2D

## Torre estática que mira no inimigo mais próximo dentro do alcance e dispara projéteis.

@export var attack_range: float = 190.0
@export var damage: int = 4
@export var fire_rate: float = 1.8 ## tiros por segundo
@export var body_color: Color = Color(0.3, 0.5, 0.9)

var _cooldown: float = 0.0

func _process(delta) -> void:
	_cooldown -= delta
	var target = _find_target()
	if target != null and _cooldown <= 0.0:
		_shoot(target)
		_cooldown = 1.0 / max(0.1, fire_rate)

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist = attack_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d = global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best

func _shoot(target: Node2D) -> void:
	var p = Projectile.new()
	get_parent().add_child(p) # projétil vai pro mesmo espaço da torre (Main)
	p.global_position = global_position
	p.setup(target, damage)

func _draw() -> void:
	# base da torre: retângulo preenchido centrado em Vector2.ZERO
	draw_rect(Rect2(Vector2(-18, -18), Vector2(36, 36)), body_color)
	# alcance: círculo de contorno (translúcido), raio = attack_range
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.12), 1.0)
