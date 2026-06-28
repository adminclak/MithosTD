class_name Projectile
extends Node2D

## Projétil que persegue um alvo e causa dano ao alcançá-lo.

@export var speed: float = 460.0
@export var color: Color = Color(1, 1, 0.4)

var _target: Node2D = null
var _damage: int = 0

func setup(target: Node2D, dmg: int) -> void:
	_target = target
	_damage = dmg

func _physics_process(delta) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	var to = _target.global_position - global_position
	var dist = to.length()
	if dist <= 8.0:
		if _target.has_method("take_damage"):
			_target.take_damage(_damage)
		queue_free()
		return
	global_position += to.normalized() * speed * delta
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, color)
