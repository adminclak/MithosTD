class_name Projectile
extends Node2D

## Projétil que persegue um alvo. No impacto causa dano só no alvo (Arqueiro)
## ou em área a todos os inimigos dentro de `_splash` (Mago). O visual depende
## de `kind`: FLECHA (gira na direção do voo), BOLA DE FOGO (chamejante, explode)
## ou RAIO MÁGICO (orbe brilhante com rastro).

enum Kind { ARROW, FIREBALL, BOLT }

@export var speed: float = 460.0
@export var color: Color = Color(1, 1, 0.4)

var kind: int = Kind.ARROW
var _target: Node2D = null
var _damage: int = 0
var _splash: float = 0.0
var _pen: int = 0
var _life: float = 0.0
var _trail: Array = [] ## últimas posições (rastro)


func setup(target: Node2D, dmg: int, splash: float = 0.0, col: Color = Color(1, 1, 0.4), pen: int = 0) -> void:
	_target = target
	_damage = dmg
	_splash = splash
	color = col
	_pen = pen


func set_kind(k: int) -> void:
	kind = k
	z_index = 20


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	var to: Vector2 = _target.global_position - global_position
	var dist: float = to.length()
	rotation = to.angle()
	_life += delta
	# Rastro (em coordenadas globais; convertido na hora de desenhar).
	_trail.push_front(global_position)
	if _trail.size() > 6:
		_trail.pop_back()
	if dist <= 8.0:
		_impact()
		return
	global_position += to.normalized() * speed * delta
	queue_redraw()


func _impact() -> void:
	if _splash > 0.0:
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			if global_position.distance_to(e.global_position) <= _splash:
				if e.has_method("take_damage"):
					e.take_damage(_damage, _pen)
	else:
		if is_instance_valid(_target) and _target.has_method("take_damage"):
			_target.take_damage(_damage, _pen)
	_spawn_impact()
	queue_free()


func _spawn_impact() -> void:
	var fx := HitEffect.new()
	get_parent().add_child(fx)
	fx.global_position = global_position
	match kind:
		Kind.FIREBALL:
			fx.setup(max(26.0, _splash), Color(1.0, 0.5, 0.15), true, 0.35, 8)
		Kind.BOLT:
			fx.setup(18.0, color, true, 0.28, 6)
		_:
			fx.setup(12.0, Color(1.0, 0.95, 0.7), false, 0.18, 4)


func _draw() -> void:
	# Rastro: pontos esmaecendo (desenhados em espaço local, "atrás" do projétil).
	for i in _trail.size():
		var local: Vector2 = to_local(_trail[i])
		var a: float = (1.0 - float(i) / float(_trail.size())) * 0.5
		var rr: float = (4.0 if kind == Kind.ARROW else 6.0) * (1.0 - float(i) / float(_trail.size()))
		draw_circle(local, rr, Color(color.r, color.g, color.b, a))

	match kind:
		Kind.ARROW:
			# Flecha apontando para +X (o nó já gira na direção do voo).
			draw_line(Vector2(-10, 0), Vector2(8, 0), Color(0.45, 0.30, 0.16), 2.5)
			var head := PackedVector2Array([Vector2(8, -4), Vector2(15, 0), Vector2(8, 4)])
			draw_colored_polygon(head, Color(0.85, 0.85, 0.9))
			# Penas.
			draw_line(Vector2(-10, 0), Vector2(-13, -3), color, 2.0)
			draw_line(Vector2(-10, 0), Vector2(-13, 3), color, 2.0)
		Kind.FIREBALL:
			var flick: float = 7.0 + sin(_life * 40.0) * 1.6
			draw_circle(Vector2.ZERO, flick + 4.0, Color(1.0, 0.35, 0.05, 0.28)) # brilho
			draw_circle(Vector2.ZERO, flick, Color(1.0, 0.5, 0.12))              # corpo
			draw_circle(Vector2.ZERO, flick * 0.55, Color(1.0, 0.92, 0.5))       # núcleo
		Kind.BOLT:
			draw_circle(Vector2.ZERO, 9.0, Color(color.r, color.g, color.b, 0.30))
			draw_circle(Vector2.ZERO, 5.5, color)
			draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1, 0.9))
