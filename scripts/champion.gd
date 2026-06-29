class_name Champion
extends Node2D

## Campeão: 1 herói do esquadrão que ANDA pelo mapa (estilo Kingdom Rush). Vai até
## o inimigo mais próximo e luta (melee trava e bate; ranged atira de longe); sem
## inimigos por perto, caminha até o ponto de reunião (rally) e aguarda. Cai ao
## zerar a vida e revive depois de um tempo. Usa elemento/equip/atributos do herói.

const SPEED := 100.0
const LEASH := 320.0        ## raio de agressividade ao redor do rally
const MELEE_RANGE := 44.0

var data: TowerData
var _hp: int = 1
var _max: int = 1
var _state: int = Anim.IDLE
var _face_x: float = 1.0
var _phase: float = 0.0
var _atk: float = 0.0
var _rally: Vector2 = Vector2.ZERO
var _down: bool = false
var _down_t: float = 0.0
var _cd: float = 0.0
var _melee_cd: float = 0.0
var _abil_cd: float = 6.0
var _engaged: Node2D = null
var _sprite: Texture2D = null
var _rig: RiggedActor = null

@onready var _gs: Node = get_node_or_null(^"/root/GameState")


func setup(d: TowerData) -> void:
	data = d
	_max = d.max_hp if d.is_melee and d.max_hp > 0 else 70 + d.damage * 4
	_max = int(round(_max * 1.1)) # campeão um pouco mais robusto que torres
	_hp = _max


func _ready() -> void:
	add_to_group("champions")
	add_to_group("melee_allies")
	if data != null:
		_sprite = Art.hero(data.char_id)
	if _sprite != null:
		_rig = RiggedActor.new()
		_rig.setup(_sprite, 54.0) # menor que a torre (~92px)
		_rig.position = Vector2(0, 12) # pés no chão (junto da sombra)
		add_child(_rig)
	_rally = global_position
	queue_redraw()


func move_to(pos: Vector2) -> void:
	_rally = pos


func _process(delta: float) -> void:
	# Movimento no frame de render (fluidez em telas 120/144Hz; ver enemy.gd).
	if _gs != null and _gs.is_over():
		return
	_phase += delta * 9.0
	if _atk > 0.0:
		_atk = maxf(0.0, _atk - delta * 3.0)
	if _abil_cd > 0.0:
		_abil_cd -= delta

	if _down:
		_down_t -= delta
		if _down_t <= 0.0:
			_down = false
			_hp = _max
		queue_redraw()
		return

	var e := _nearest_enemy()
	# Habilidade de assinatura: lança sozinha quando há inimigos por perto.
	if data.ability != null and _abil_cd <= 0.0 and e != null \
			and global_position.distance_to(e.global_position) < 200.0:
		_cast_ability()
	var move_target := _rally
	var attacking := false
	if e != null:
		var d: float = global_position.distance_to(e.global_position)
		if data.is_melee:
			if d <= MELEE_RANGE:
				move_target = global_position
				attacking = true
				_melee_fight(delta, e)
			else:
				move_target = e.global_position
		else:
			if d <= data.attack_range:
				move_target = global_position
				attacking = true
				_ranged_fight(delta, e)
			else:
				move_target = e.global_position
		if absf(e.global_position.x - global_position.x) > 1.0:
			_face_x = signf(e.global_position.x - global_position.x)

	# Movimento.
	if global_position.distance_to(move_target) > 6.0:
		var to := move_target - global_position
		if absf(to.x) > 1.0:
			_face_x = signf(to.x)
		global_position += to.normalized() * SPEED * delta
		_state = Anim.WALK
		_release_engaged()
	else:
		_state = Anim.ATTACK if attacking else Anim.IDLE
	# Atualiza o rig (direção + ação).
	if _rig != null:
		_rig.scale.x = -1.0 if _face_x < 0.0 else 1.0
		_rig.set_pose(_state, _atk)
		_rig.modulate = Color(1, 1, 1, 0.5) if _down else Color.WHITE
	queue_redraw()


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var bd := LEASH
	for en in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(en):
			continue
		var dd: float = _rally.distance_to(en.global_position)
		if dd <= bd:
			bd = dd
			best = en
	return best


func _melee_fight(delta: float, e: Node2D) -> void:
	# Trava o inimigo (ele para e luta) e bate de volta.
	if _engaged != e:
		_release_engaged()
		if e.has_method("engage"):
			e.engage(self)
			_engaged = e
	_melee_cd -= delta
	if _melee_cd <= 0.0:
		_atk = 1.0
		var dmg: int = data.melee_damage if data.melee_damage > 0 else int(round(data.damage * 1.2))
		dmg = int(round(dmg * 1.3))
		if e.has_method("take_damage"):
			e.take_damage(dmg, data.penetration, data.element)
		_melee_cd = 1.0 / maxf(0.3, data.melee_attack_rate if data.melee_attack_rate > 0 else 1.2)


func _ranged_fight(delta: float, e: Node2D) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_atk = 1.0
		var p := Projectile.new()
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -10)
		var dmg := int(round(data.damage * 1.3))
		p.setup(e, dmg, data.splash_radius, data.projectile_color, data.penetration, data.element)
		if data.tower_class == TowerData.TowerClass.MAGE:
			p.set_kind(Projectile.Kind.FIREBALL if data.splash_radius > 0.0 else Projectile.Kind.BOLT)
		else:
			p.set_kind(Projectile.Kind.ARROW if data.tower_class == TowerData.TowerClass.ARCHER else Projectile.Kind.BOLT)
		p.speed = data.proj_speed
		_cd = 1.0 / maxf(0.4, data.fire_rate if data.fire_rate > 0 else 1.0)


## Lança a habilidade do herói: dano em área ao redor + efeito conforme o tipo.
func _cast_ability() -> void:
	var ab: AbilityData = data.ability
	_abil_cd = maxf(6.0, ab.cooldown * 0.5)
	_atk = 1.0
	var r: float = ab.radius if ab.radius > 0.0 else 150.0
	var pw: int = int(ab.power) if ab.power > 0.0 else int(data.damage * 2.0)
	for en in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(en):
			continue
		if global_position.distance_to(en.global_position) > r:
			continue
		match ab.kind:
			AbilityData.Kind.STUN_AOE:
				en.take_damage(pw, data.penetration, data.element)
				if en.has_method("apply_stun"): en.apply_stun(ab.duration)
			AbilityData.Kind.SLOW_AOE:
				en.take_damage(pw, data.penetration, data.element)
				if en.has_method("apply_slow"): en.apply_slow(0.45, ab.duration)
			AbilityData.Kind.DOT_AOE:
				if en.has_method("apply_dot"): en.apply_dot(ab.power, ab.duration)
			AbilityData.Kind.KNOCKBACK:
				en.take_damage(pw, data.penetration, data.element)
				if en.has_method("knockback"): en.knockback(60.0)
			_:
				en.take_damage(pw, data.penetration, data.element)
	# Efeito visual no campeão (cor do elemento).
	var fx := HitEffect.new()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.setup(r, Elements.color_of(data.element), true, 0.4, 8)


func _release_engaged() -> void:
	if _engaged != null and is_instance_valid(_engaged) and _engaged.has_method("release"):
		_engaged.release()
	_engaged = null


# Inimigos travados batem no campeão.
func take_damage(amount: int, _pen: int = 0) -> void:
	if _down:
		return
	if randf() < data.dodge:
		return
	_hp -= max(1, amount - data.defense)
	queue_redraw()
	if _hp <= 0:
		_go_down()


func heal(amount: int) -> void:
	_hp = min(_max, _hp + amount)
	queue_redraw()


func is_down() -> bool:
	return _down


func _go_down() -> void:
	_down = true
	_down_t = max(7.0, data.revive_time)
	_state = Anim.IDLE
	_release_engaged()
	queue_redraw()


func _draw() -> void:
	# Sombra (elíptica no chão).
	draw_set_transform(Vector2(0, 13), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 13.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Anel do elemento (marca o campeão).
	if data != null:
		var ec := Elements.color_of(data.element)
		draw_arc(Vector2(0, 12), 14.0, 0.0, TAU, 24, Color(ec.r, ec.g, ec.b, 0.6), 2.0)
	# O corpo é desenhado pelo _rig (RiggedActor, nó filho).
	# Barra de vida + coroa (acima do rig).
	if not _down:
		var w := 36.0
		var p := Vector2(-18, -52)
		draw_rect(Rect2(p, Vector2(w, 4)), Color(0.1, 0.1, 0.1))
		var ratio := clampf(float(_hp) / float(_max), 0.0, 1.0)
		draw_rect(Rect2(p, Vector2(w * ratio, 4)), Color(0.3, 0.85, 0.4))
		draw_string(ThemeDB.fallback_font, Vector2(-7, -56), "♛", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.85, 0.3))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-26, -44), "%ds" % int(ceil(_down_t)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.6, 0.6))
