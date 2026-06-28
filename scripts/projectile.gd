class_name Projectile
extends Node2D

## Projétil que persegue um alvo. No impacto causa dano só no alvo (Arqueiro)
## ou em área a todos os inimigos dentro de `_splash` (Mago).

@export var speed: float = 460.0
@export var color: Color = Color(1, 1, 0.4)

var _target: Node2D = null
var _damage: int = 0
var _splash: float = 0.0
var _pen: int = 0

func setup(target: Node2D, dmg: int, splash: float = 0.0, col: Color = Color(1, 1, 0.4), pen: int = 0) -> void:
	_target = target
	_damage = dmg
	_splash = splash
	color = col
	_pen = pen

func _physics_process(delta) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	var to = _target.global_position - global_position
	var dist = to.length()
	if dist <= 8.0:
		_impact()
		return
	global_position += to.normalized() * speed * delta
	queue_redraw()

func _impact() -> void:
	if _splash > 0.0:
		# Dano em área: atinge todos os inimigos dentro do raio de splash.
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			if global_position.distance_to(e.global_position) <= _splash:
				if e.has_method("take_damage"):
					e.take_damage(_damage, _pen)
	else:
		# Dano de alvo único.
		if is_instance_valid(_target) and _target.has_method("take_damage"):
			_target.take_damage(_damage, _pen)
	queue_free()

func _draw() -> void:
	var r := 5.0 if _splash <= 0.0 else 8.0
	draw_circle(Vector2.ZERO, r, color)
