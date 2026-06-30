class_name Tower
extends Node2D

## Personagem em campo. Dois modos (data.is_melee):
## - MELEE: fica onde foi posto, trava até block_capacity inimigos no raio e luta
##   corpo-a-corpo (com defesa/esquiva/regen/lifesteal). Ao zerar a vida, CAI e se
##   recupera após revive_time, com vida cheia. Substitui o antigo BlockerUnit.
## - RANGED: Arqueiro/Mago miram e atiram (com penetração e crítico); Sacerdote
##   irradia aura (consumida pelas entidades próximas).
## Sacerdote melee tanka E irradia aura. Upgrade temporário (nível 1->3) e
## habilidade ativa valem para ambos.

const MAX_LEVEL := 3
const LEVEL_STAT_STEP := 0.35
const UPGRADE_COST_FACTOR := 0.6
const UPGRADE_COST_GROWTH := 1.6
const SELL_RATE := 0.6

var data: TowerData
var waypoints: Array = []
var level: int = 1
var invested_gold: int = 0

# Reposicionamento manual (modelo "heróis móveis"): anda até o ponto comandado e
# volta a agir (estático) ao chegar. selected = unidade escolhida pelo jogador.
const MOVE_SPEED := 115.0
var _moving: bool = false
var _move_target: Vector2 = Vector2.ZERO
var selected: bool = false

var _cooldown: float = 0.0
var _aura_damage_mult: float = 1.0
var _aura_fire_rate_mult: float = 1.0

# Habilidade
var _ability_cd: float = 0.0
var _temp_buff_mult: float = 1.0
var _temp_buff_timer: float = 0.0

# Melee
var _hp: int = 0
var _melee_targets: Array = []
var _melee_cd: float = 0.0
var _down: bool = false
var _down_timer: float = 0.0
var _regen_accum: float = 0.0
var _contact_accum: float = 0.0 ## dano de contato acumulado (heróis ranged expostos)
var _shield_timer: float = 0.0

var _sprite: Texture2D = null
var _is_building: bool = false ## desenha como prédio (sem balanço, maior)
var force_building: bool = true ## torre de slot = prédio da classe (mesmo com herói)

# Animação (puro código): respiração idle, ataque (recoil/espadada/escudo) e
# direção do golpe. _atk vai de 1→0 a cada ação.
var _idle: float = 0.0
var _atk: float = 0.0
var _face: Vector2 = Vector2.RIGHT

@onready var _state: Node = get_node_or_null(^"/root/GameState")


func setup(d: TowerData) -> void:
	data = d
	invested_gold = d.cost
	_hp = max_hp()


## Reposiciona a unidade: anda até `pos` e fica estática lá (volta a lutar). Solta
## inimigos que estava travando ao começar a andar.
func move_to(pos: Vector2) -> void:
	_move_target = pos
	_moving = true
	for e in _melee_targets:
		if is_instance_valid(e) and e.has_method("release"):
			e.release()
	_melee_targets.clear()


func _ready() -> void:
	add_to_group("towers")
	if data != null:
		if data.tower_class == TowerData.TowerClass.PRIEST:
			add_to_group("priests")
		if data.is_melee:
			add_to_group("melee_allies")
		_hp = max_hp()
		if force_building:
			# Torre de slot = prédio da classe (Arqueira/Quartel/Guilda/Templo),
			# mesmo usando os stats/elemento/equip do herói do esquadrão.
			var bnames := {
				TowerData.TowerClass.ARCHER: "tower_archer",
				TowerData.TowerClass.MAGE: "tower_mage",
				TowerData.TowerClass.WARRIOR: "tower_warrior",
				TowerData.TowerClass.PRIEST: "tower_priest",
			}
			var bname: String = bnames.get(data.tower_class, "")
			_sprite = Art.map(bname)
			_is_building = _sprite != null
		elif data.char_id != "":
			_sprite = Art.hero(data.char_id)
	queue_redraw()


func _process(delta: float) -> void:
	if data == null or (_state != null and _state.is_over()):
		return
	# Reposicionamento manual: anda até o ponto e fica estático lá (não ataca andando).
	if _moving:
		var to: Vector2 = _move_target - global_position
		if to.length() <= 3.0:
			_moving = false
		else:
			global_position += to.normalized() * MOVE_SPEED * delta
			_face = to.normalized()
			_idle += delta * 3.2
			queue_redraw()
			return
	# Caído (vale p/ TODOS os heróis): aguarda reviver com vida cheia.
	if _down:
		_down_timer -= delta
		if _down_timer <= 0.0:
			_down = false
			_hp = max_hp()
		_idle += delta * 3.2
		queue_redraw()
		return
	if _ability_cd > 0.0:
		_ability_cd -= delta
	if _temp_buff_timer > 0.0:
		_temp_buff_timer -= delta
	if _shield_timer > 0.0:
		_shield_timer -= delta
	_recompute_aura_buffs()
	if data.is_melee:
		_process_melee(delta)
	else:
		# Ranged: sobrevive (dano de contato / regeneração) e atira.
		_process_ranged_survival(delta)
		if data.damage > 0 and data.attack_range > 0.0:
			_process_attacker(delta)
	# A aura do Sacerdote também é consultada pelas entidades próximas.

	# Animação: respiração contínua + decaimento do golpe + redesenho por frame.
	_idle += delta * 3.2
	if _atk > 0.0:
		_atk = max(0.0, _atk - delta * 4.0)
	queue_redraw()


# --- Upgrade / venda ---
func _stat_mult() -> float:
	return 1.0 + (level - 1) * LEVEL_STAT_STEP

func can_upgrade() -> bool:
	return level < MAX_LEVEL

func upgrade_cost() -> int:
	return int(round(data.cost * UPGRADE_COST_FACTOR * pow(UPGRADE_COST_GROWTH, level - 1)))

func sell_value() -> int:
	return int(round(invested_gold * SELL_RATE))

func apply_upgrade() -> void:
	if not can_upgrade():
		return
	invested_gold += upgrade_cost()
	level += 1
	if data.is_melee:
		# Upar aumenta o teto de vida do tanque tambem.
		var new_max := int(round(data.max_hp * _stat_mult()))
		_hp += new_max - int(round(data.max_hp * (1.0 + (level - 2) * LEVEL_STAT_STEP)))
		_hp = min(_hp, max_hp())
	queue_redraw()

func max_hp() -> int:
	if data.is_melee:
		return int(round(data.max_hp * _stat_mult()))
	# Heróis ranged também têm vida (mais frágeis): morrem se ficarem expostos na rota.
	var base: int = data.max_hp if data.max_hp > 0 else _ranged_base_hp()
	return int(round(base * _stat_mult()))


func _ranged_base_hp() -> int:
	var vit: int = data.attributes.vitality if data.attributes != null else 12
	return 35 + vit * 2


# --- Aura efetiva (com nível) ---
func aura_radius() -> float:
	return data.aura_radius

func aura_damage_mult() -> float:
	return 1.0 + (data.aura_damage_mult - 1.0) * _stat_mult()

func aura_fire_rate_mult() -> float:
	return 1.0 + (data.aura_fire_rate_mult - 1.0) * _stat_mult()

func aura_slow_mult() -> float:
	return clampf(1.0 - (1.0 - data.aura_slow_mult) * _stat_mult(), 0.2, 1.0)

func aura_heal_per_sec() -> float:
	return data.aura_heal_per_sec * _stat_mult()


## Maior cura/seg entre os Sacerdotes cuja aura cobre este personagem.
func _aura_heal_near() -> float:
	var h := 0.0
	for p in get_tree().get_nodes_in_group("priests"):
		if not is_instance_valid(p) or p == self:
			continue
		if global_position.distance_to(p.global_position) <= p.aura_radius():
			h = max(h, p.aura_heal_per_sec())
	return h


func _recompute_aura_buffs() -> void:
	_aura_damage_mult = 1.0
	_aura_fire_rate_mult = 1.0
	for p in get_tree().get_nodes_in_group("priests"):
		if not is_instance_valid(p) or p == self:
			continue
		if global_position.distance_to(p.global_position) <= p.aura_radius():
			_aura_damage_mult = max(_aura_damage_mult, p.aura_damage_mult())
			_aura_fire_rate_mult = max(_aura_fire_rate_mult, p.aura_fire_rate_mult())


# --- RANGED (Arqueiro / Mago) ---
func _process_attacker(delta: float) -> void:
	_cooldown -= delta
	var target := _find_target()
	if target != null and _cooldown <= 0.0:
		_shoot(target)
		var eff_fr: float = data.fire_rate * _stat_mult() * _aura_fire_rate_mult * _temp_mult()
		_cooldown = 1.0 / max(0.1, eff_fr)

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist: float = data.attack_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var dd: float = global_position.distance_to(e.global_position)
		if dd <= best_dist:
			best_dist = dd
			best = e
	return best

func _shoot(target: Node2D) -> void:
	var p := Projectile.new()
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -6)
	var dmg: int = int(round(data.damage * _stat_mult() * _aura_damage_mult * _temp_mult()))
	var col: Color = data.projectile_color
	if randf() < data.crit_chance:
		dmg = int(round(dmg * data.crit_mult))
		col = Color(1.0, 0.55, 0.2)
	p.setup(target, dmg, data.splash_radius, col, data.penetration, data.element, data.slow_mult, data.slow_duration)
	p.speed = data.proj_speed
	# Tipo de projétil pela classe: Mago = bola de fogo; Sacerdote = raio dourado;
	# Arqueiro = flecha.
	if data.tower_class == TowerData.TowerClass.MAGE:
		p.set_kind(Projectile.Kind.FIREBALL if data.splash_radius > 0.0 else Projectile.Kind.BOLT)
	elif data.tower_class == TowerData.TowerClass.PRIEST:
		p.set_kind(Projectile.Kind.BOLT)
	else:
		p.set_kind(Projectile.Kind.ARROW)
	# Artilharia: projétil arremessado em arco balístico (lob) em vez de linha reta.
	if data.proj_arc:
		p.set_arc(data.arc_height, target)
	# Dispara a animação de ataque (recuo + arco/flash) virada para o alvo.
	_atk = 1.0
	_face = (target.global_position - global_position).normalized()


## Heróis RANGED: tomam dano de contato de inimigos colados (ficam expostos se
## postos/movidos para a rota; seguros se ficam ao lado dela) e regeneram devagar
## quando seguros. Caem e revivem como os melee.
func _process_ranged_survival(delta: float) -> void:
	var contact := 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= 28.0:
			contact += float(e.attack_damage)
	if contact > 0.0:
		_contact_accum += contact * delta
		var whole := int(_contact_accum)
		if whole > 0:
			_contact_accum -= whole
			take_damage(whole)
	elif _hp < max_hp():
		_regen_accum += (2.0 + _aura_heal_near()) * delta
		var w := int(_regen_accum)
		if w > 0:
			_regen_accum -= w
			_hp = min(max_hp(), _hp + w)
			queue_redraw()


# --- MELEE (tanque que trava inimigos) ---
func _process_melee(delta: float) -> void:
	if _down:
		_down_timer -= delta
		if _down_timer <= 0.0:
			_down = false
			_hp = max_hp()
			queue_redraw()
		return

	# Regeneração própria + cura da aura de Sacerdotes próximos.
	var heal_rate: float = data.regen + _aura_heal_near()
	if _hp < max_hp() and heal_rate > 0.0:
		_regen_accum += heal_rate * delta
		var whole := int(_regen_accum)
		if whole > 0:
			_hp = min(max_hp(), _hp + whole)
			_regen_accum -= whole
			queue_redraw()

	# Solta alvos inválidos.
	for i in range(_melee_targets.size() - 1, -1, -1):
		if not is_instance_valid(_melee_targets[i]):
			_melee_targets.remove_at(i)

	# Trava novos inimigos até a capacidade.
	var cap := data.block_capacity
	if _melee_targets.size() < cap:
		for e in get_tree().get_nodes_in_group("enemies"):
			if _melee_targets.size() >= cap:
				break
			if not is_instance_valid(e) or _melee_targets.has(e):
				continue
			if e.has_method("is_blocked") and e.is_blocked():
				continue
			if global_position.distance_to(e.global_position) <= data.engage_radius:
				if e.has_method("engage"):
					e.engage(self)
					_melee_targets.append(e)

	# Ataca os travados.
	if not _melee_targets.is_empty():
		# Vira o personagem para o primeiro alvo válido (escudo/espada apontam pra lá).
		for e in _melee_targets:
			if is_instance_valid(e):
				_face = (e.global_position - global_position).normalized()
				break
		_melee_cd -= delta
		if _melee_cd <= 0.0:
			_atk = 1.0 # dispara a espadada / investida de escudo
			var dmg := int(round(data.melee_damage * _stat_mult() * _aura_damage_mult * _temp_mult()))
			for e in _melee_targets:
				if not is_instance_valid(e):
					continue
				var d2 := dmg
				if randf() < data.crit_chance:
					d2 = int(round(dmg * data.crit_mult))
				if e.has_method("take_damage"):
					e.take_damage(d2, data.penetration, data.element)
				if data.lifesteal > 0.0:
					heal(int(round(d2 * data.lifesteal)))
			_melee_cd = 1.0 / max(0.1, data.melee_attack_rate * _temp_mult())


# Recebe dano (vale p/ TODOS os heróis). Chamado pelos inimigos travados (melee) ou
# pelo dano de contato (ranged). Ranged têm defesa/esquiva 0 = mais frágeis.
func take_damage(amount: int, _pen: int = 0) -> void:
	if data == null or _down:
		return
	if _shield_timer > 0.0:
		return
	if randf() < data.dodge:
		return # esquivou
	_hp -= max(1, amount - data.defense)
	queue_redraw()
	if _hp <= 0:
		_go_down()

func _go_down() -> void:
	_down = true
	_down_timer = data.revive_time if data.revive_time > 0.0 else 8.0
	for e in _melee_targets:
		if is_instance_valid(e) and e.has_method("release"):
			e.release()
	_melee_targets.clear()
	queue_redraw()

func heal(amount: int) -> void:
	if data == null or not data.is_melee:
		return
	_hp = min(max_hp(), _hp + amount)
	queue_redraw()

func apply_shield(duration: float) -> void:
	_shield_timer = max(_shield_timer, duration)
	queue_redraw()

func is_down() -> bool:
	return _down


# --- Habilidade ativa ---
func _temp_mult() -> float:
	return _temp_buff_mult if _temp_buff_timer > 0.0 else 1.0

func has_ability() -> bool:
	return data != null and data.ability != null

func ability_cooldown_left() -> float:
	return max(0.0, _ability_cd)

func apply_temp_buff(mult: float, dur: float) -> void:
	var current := _temp_buff_mult if _temp_buff_timer > 0.0 else 1.0
	_temp_buff_mult = max(current, mult)
	_temp_buff_timer = max(_temp_buff_timer, dur)

func use_ability() -> bool:
	if not has_ability() or _ability_cd > 0.0:
		return false
	var ab: AbilityData = data.ability
	_ability_cd = ab.cooldown * (1.0 - data.cdr)
	match ab.kind:
		AbilityData.Kind.DAMAGE_AOE:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)), data.penetration)
		AbilityData.Kind.STUN_AOE:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)), data.penetration)
				if e.has_method("apply_stun"):
					e.apply_stun(ab.duration)
		AbilityData.Kind.BUFF_TOWER:
			for t in _towers_in(ab.radius):
				t.apply_temp_buff(ab.power, ab.duration)
		AbilityData.Kind.HEAL_BLOCKERS:
			for t in _melee_allies_in(ab.radius):
				t.heal(int(round(ab.power)))
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power * 0.4)), data.penetration)
		AbilityData.Kind.SHIELD_BLOCKERS:
			for t in _melee_allies_in(ab.radius):
				t.apply_shield(ab.duration)
		AbilityData.Kind.CHAIN:
			_chain_damage(ab)
		AbilityData.Kind.LINE:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)), 9999) # perfurante: ignora defesa
		AbilityData.Kind.SLOW_AOE:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)), data.penetration)
				if e.has_method("apply_slow"):
					e.apply_slow(0.45, ab.duration)
		AbilityData.Kind.KNOCKBACK:
			for e in _enemies_in(ab.radius):
				e.take_damage(int(round(ab.power)), data.penetration)
				if e.has_method("knockback"):
					e.knockback(70.0)
		AbilityData.Kind.DOT_AOE:
			for e in _enemies_in(ab.radius):
				if e.has_method("apply_dot"):
					e.apply_dot(ab.power, ab.duration)
		AbilityData.Kind.SUMMON:
			_summon_ally(ab)
	return true


func _chain_damage(ab: AbilityData) -> void:
	var hit := {}
	var from := global_position
	for i in 5: # até 5 saltos
		var best: Node2D = null
		var bd := ab.radius if i == 0 else 200.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or hit.has(e):
				continue
			var dd: float = from.distance_to(e.global_position)
			if dd <= bd:
				bd = dd
				best = e
		if best == null:
			break
		best.take_damage(int(round(ab.power)), data.penetration)
		hit[best] = true
		from = best.global_position


func _summon_ally(ab: AbilityData) -> void:
	var d := TowerData.new()
	d.is_melee = true
	d.max_hp = int(round(40 + ab.power * 5))
	d.defense = 3
	d.melee_damage = int(round(max(4, ab.power)))
	d.melee_attack_rate = 1.0
	d.block_capacity = 1
	d.engage_radius = 80.0
	d.body_color = Color(0.7, 0.75, 0.95)
	var ally := Tower.new()
	ally.force_building = false ## invocação é um aliado, não prédio
	ally.setup(d)
	get_parent().add_child(ally)
	ally.global_position = global_position + Vector2(randf_range(-30, 30), 30)
	var dur: float = ab.duration if ab.duration > 0.0 else 8.0
	get_tree().create_timer(dur).timeout.connect(func(): if is_instance_valid(ally): ally.queue_free())

func _enemies_in(r: float) -> Array:
	return _nodes_in_group_within("enemies", r)

func _towers_in(r: float) -> Array:
	return _nodes_in_group_within("towers", r)

func _melee_allies_in(r: float) -> Array:
	return _nodes_in_group_within("melee_allies", r)

func _nodes_in_group_within(group: String, r: float) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group(group):
		if is_instance_valid(n) and global_position.distance_to(n.global_position) <= r:
			out.append(n)
	return out


func _draw() -> void:
	if data == null:
		return
	var c: Color = data.body_color
	var dark := Color(c.r * 0.45, c.g * 0.45, c.b * 0.45)

	# Indicador de TIPO/alcance: anel largo (ranged, cor da classe) ou anel curto
	# vermelho (melee, raio de corpo-a-corpo). Brilha quando o herói está selecionado.
	var ring_a: float = 0.40 if selected else 0.22
	var ring_w: float = 3.0 if selected else 2.0
	if not data.is_melee and data.attack_range > 0.0:
		draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(c.r, c.g, c.b, ring_a), ring_w)
	elif data.is_melee:
		var er: float = data.engage_radius if data.engage_radius > 0.0 else 60.0
		draw_arc(Vector2.ZERO, er, 0.0, TAU, 48, Color(1.0, 0.42, 0.3, ring_a), ring_w)
	if data.aura_radius > 0.0:
		# Aura pulsante (respira com o idle).
		var pulse: float = 0.10 + 0.06 * (0.5 + 0.5 * sin(_idle * 1.4))
		draw_arc(Vector2.ZERO, data.aura_radius, 0.0, TAU, 64, Color(c.r, c.g, c.b, pulse), 2.0)

	# Deslocamento do corpo: respiração (bob) + movimento do golpe.
	var bob := Vector2(0, sin(_idle) * 1.5)
	var motion := Vector2.ZERO
	if data.is_melee:
		motion = _face * 6.0 * _atk     # avança ao golpear/empurrar
	else:
		motion = -_face * 4.0 * _atk    # recua ao atirar
	var off := bob + motion

	# Sombra elíptica no chão (maior para prédios).
	var sh_w := 30.0 if _is_building else 14.0
	var sh_y := 20.0 if _is_building else 15.0
	draw_set_transform(Vector2(0, sh_y), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, sh_w, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _down:
		c = Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, 0.7)
		dark = Color(dark.r, dark.g, dark.b, 0.7)

	# Arma/efeito ATRÁS do corpo (ex.: arco) e DEPOIS o corpo por cima.
	if not _down:
		_draw_weapon_back(off)
	if _sprite != null and _is_building:
		# Prédio: estático, ancorado pela base, maior.
		var bs := Vector2(78, 92)
		draw_texture_rect(_sprite, Rect2(Vector2(-bs.x * 0.5, -bs.y + 22), bs), false)
	elif _sprite != null:
		var sz := Vector2(52, 52)
		var dest := Rect2(off + (-sz * 0.5) + Vector2(0, -8), sz)
		var mod := Color(1, 1, 1, 0.7) if _down else Color.WHITE
		var lean := _face.x * 9.0 * _atk
		Anim.draw_swayed(self, _sprite, dest, _idle, 1.4, lean, 0.035, mod)
	else:
		_draw_doll_at(off, c, dark)
	if not _down:
		_draw_weapon_front(off)
		_draw_equipment(off)

	# Sobreposições.
	if not _is_building:
		_draw_hp_bar()
	if data.is_melee and _shield_timer > 0.0:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color(1.0, 0.95, 0.5), 2.0)
	for i in level:
		draw_rect(Rect2(Vector2(-18 + i * 8, -32), Vector2(6, 5)), Color(1.0, 0.9, 0.3))

	# Anel de seleção (unidade escolhida pelo jogador para mover/gerir).
	if selected:
		draw_arc(Vector2(0, 6), 24.0, 0.0, TAU, 28, Color(1.0, 0.95, 0.55, 0.9), 2.5)


## True = estilo escudeiro (tanque); False = espadachim. Sem atributos, usa a
## capacidade de bloqueio como pista (tanques seguram mais inimigos).
func _melee_uses_shield() -> bool:
	if data.attributes != null:
		return data.attributes.vitality >= data.attributes.strength
	return data.block_capacity >= 3


## Efeitos desenhados ATRÁS do corpo.
func _draw_weapon_back(off: Vector2) -> void:
	var ang := _face.angle()
	if data.is_melee:
		return
	match data.tower_class:
		TowerData.TowerClass.ARCHER:
			# Arco curvo do lado do alvo, com corda que estica ao atirar.
			var hand := off + _face * 8.0
			var perp := Vector2(-_face.y, _face.x)
			var p_top := hand + perp * 9.0
			var p_bot := hand - perp * 9.0
			var bend: float = 6.0 - 3.0 * _atk
			var mid := hand + _face * bend
			draw_polyline(PackedVector2Array([p_top, mid, p_bot]), Color(0.5, 0.32, 0.16), 2.2)
			draw_line(p_top, p_bot, Color(0.9, 0.9, 0.9, 0.8), 1.0) # corda
		TowerData.TowerClass.MAGE:
			# Cajado apontando para o alvo.
			draw_line(off, off + _face * 16.0, Color(0.5, 0.35, 0.2), 2.5)
	# guarda ang para uso futuro (silencia aviso)
	ang = ang


## Efeitos desenhados NA FRENTE do corpo.
func _draw_weapon_front(off: Vector2) -> void:
	match data.tower_class:
		TowerData.TowerClass.MAGE:
			if _atk > 0.0:
				# Orbe de conjuração brilhando na ponta do cajado.
				var tip := off + _face * 16.0
				var col := data.projectile_color
				draw_circle(tip, 7.0 * _atk, Color(col.r, col.g, col.b, 0.35 * _atk))
				draw_circle(tip, 4.0 * _atk, Color(1, 1, 1, 0.8 * _atk))
		TowerData.TowerClass.PRIEST:
			# Halo dourado sobre a cabeça.
			draw_arc(off + Vector2(0, -24), 7.0, PI, TAU, 12, Color(1.0, 0.9, 0.4, 0.9), 2.0)
		_:
			pass
	if data.is_melee:
		if _melee_uses_shield():
			_draw_shield(off)
		else:
			_draw_sword_slash(off)


## Itens equipados visíveis no boneco (elmo na cabeça, arma na mão do alvo, escudo
## no lado oposto). Usa os ícones em pixel dos itens (assets/items).
func _draw_equipment(off: Vector2) -> void:
	if data.equip_icons.is_empty():
		return
	var perp := Vector2(-_face.y, _face.x)
	var slots := EquipmentData.Slot
	_blit_item(off + _face * 6.0 + _atk * _face * 6.0 + Vector2(0, -2), 22.0, slots.WEAPON)
	_blit_item(off - _face * 9.0, 20.0, slots.SHIELD)
	_blit_item(off + Vector2(0, -26.0), 18.0, slots.HELMET)
	perp = perp # silencia aviso


func _blit_item(center: Vector2, sz: float, slot: int) -> void:
	if not data.equip_icons.has(slot):
		return
	var tex := Art.item(data.equip_icons[slot])
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(center - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false)


## Escudeiro: escudo do lado do alvo, que avança (block shove) no golpe.
func _draw_shield(off: Vector2) -> void:
	var center := off + _face * (10.0 + 4.0 * _atk)
	var perp := Vector2(-_face.y, _face.x)
	var pts := PackedVector2Array([
		center + perp * 7.0 + _face * 2.0,
		center - perp * 7.0 + _face * 2.0,
		center - perp * 5.0 + _face * 8.0,
		center + perp * 5.0 + _face * 8.0,
	])
	draw_colored_polygon(pts, Color(0.75, 0.78, 0.85))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.35, 0.37, 0.45), 1.5)
	draw_circle(center + _face * 5.0, 2.0, Color(0.95, 0.85, 0.3)) # brasão


## Espadachim: arco de espada varrendo a frente durante o golpe.
func _draw_sword_slash(off: Vector2) -> void:
	var base := _face.angle()
	# Espada em repouso (apontada para o alvo).
	draw_line(off + _face * 4.0, off + _face * 18.0, Color(0.85, 0.87, 0.95), 2.5)
	if _atk <= 0.0:
		return
	# Swoosh: arco curto que varre a frente conforme a animação (1→0).
	var sweep: float = lerp(0.9, -0.6, 1.0 - _atk)
	var r := 20.0
	var pts := PackedVector2Array()
	for i in 9:
		var a: float = base + sweep - 0.5 * (float(i) / 8.0)
		pts.append(off + Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, Color(1, 1, 1, 0.6 * _atk), 3.0)


## "Boneco" placeholder: tronco colorido (cor da classe) + cabeça + olhos.
func _draw_doll_at(off: Vector2, c: Color, dark: Color) -> void:
	draw_rect(Rect2(off + Vector2(-10, -5), Vector2(20, 21)), c)
	draw_rect(Rect2(off + Vector2(-10, -5), Vector2(20, 21)), dark, false, 2.0)
	draw_circle(off + Vector2(0, -12), 9.0, Color(0.98, 0.86, 0.72)) # cabeça
	draw_arc(off + Vector2(0, -12), 9.0, 0.0, TAU, 16, dark, 1.5)
	draw_circle(off + Vector2(-3.4, -13), 1.6, Color.BLACK)
	draw_circle(off + Vector2(3.4, -13), 1.6, Color.BLACK)


func _draw_hp_bar() -> void:
	var mh := max_hp()
	if mh <= 0:
		return
	if _hp >= mh and not _down:
		return # vida cheia: esconde a barra (evita poluição visual)
	var w := 34.0
	var pos := Vector2(-17, -26)
	draw_rect(Rect2(pos, Vector2(w, 4)), Color(0.1, 0.1, 0.1))
	var ratio := clampf(float(_hp) / float(mh), 0.0, 1.0)
	var col := Color(0.3, 0.8, 0.3) if not _down else Color(0.6, 0.3, 0.3)
	draw_rect(Rect2(pos, Vector2(w * ratio, 4)), col)
