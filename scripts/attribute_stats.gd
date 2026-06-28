class_name AttributeStats
extends RefCounted

## Converte AttributeSet (6 primários) -> TowerData (muitos secundários). É o
## ponto ÚNICO de balanceamento: mexer aqui rebalanceia o jogo todo.
## Builds suportados: Tanque (VIT/STR), Ofensivo (STR/INT + penetracao/lifesteal),
## Velocidade (AGI: vel. ataque/esquiva) e Arcano/Suporte (INT + CDR/aura).

const ARCHER_COLOR := Color(0.30, 0.55, 0.95)
const MAGE_COLOR := Color(0.62, 0.32, 0.85)
const WARRIOR_COLOR := Color(0.88, 0.28, 0.28)
const PRIEST_COLOR := Color(0.96, 0.86, 0.22)


static func build(tower_class: int, a: AttributeSet, melee: bool = false, stars: int = 1) -> TowerData:
	var d := TowerData.new()
	d.tower_class = tower_class
	d.is_melee = melee
	d.body_color = _color_of(tower_class)
	d.attributes = a

	# --- Secundários comuns (todas as builds) ---
	d.crit_chance = clampf((a.luck * 0.4 + a.dexterity * 0.15) / 100.0, 0.0, 0.6)
	d.crit_mult = 1.5 + a.luck * 0.012
	d.penetration = int(a.strength * 0.15 + a.dexterity * 0.10)
	d.cdr = clampf((a.dexterity * 0.2 + a.intelligence * 0.1) / 100.0, 0.0, 0.5)
	d.proj_speed = 380.0 + a.agility * 4.0

	match tower_class:
		TowerData.TowerClass.ARCHER:
			d.cost = 100
			d.projectile_color = Color(1.0, 1.0, 0.5)
			d.damage = int(round(2 + a.strength * 0.45 + a.dexterity * 0.15))
			d.fire_rate = 0.6 + a.agility * 0.035 + a.dexterity * 0.012
			d.attack_range = 150.0 + a.dexterity * 1.5
		TowerData.TowerClass.MAGE:
			d.cost = 150
			d.projectile_color = Color(0.78, 0.48, 1.0)
			d.damage = int(round(3 + a.intelligence * 0.6 + a.strength * 0.1))
			d.fire_rate = 0.45 + a.agility * 0.02 + a.dexterity * 0.006
			d.attack_range = 135.0 + a.dexterity * 1.1
			d.splash_radius = 52.0 + a.intelligence * 0.28
		TowerData.TowerClass.WARRIOR:
			d.cost = 120
		TowerData.TowerClass.PRIEST:
			d.cost = 130

	# --- Aura (Sacerdote): vale em melee e ranged ---
	if tower_class == TowerData.TowerClass.PRIEST:
		d.aura_radius = 135.0 + a.dexterity * 0.9
		d.aura_damage_mult = 1.10 + a.intelligence * 0.006
		d.aura_fire_rate_mult = 1.06 + a.intelligence * 0.004
		d.aura_slow_mult = clampf(0.88 - a.intelligence * 0.003, 0.40, 0.95)
		d.aura_heal_per_sec = 1.5 + a.intelligence * 0.22

	# --- Combate corpo-a-corpo (tanque) ---
	if melee:
		d.max_hp = int(round(50 + a.vitality * 4.0 + a.strength * 1.5))
		d.defense = int(round(a.vitality * 0.5 + a.strength * 0.15))
		d.dodge = clampf(a.agility * 0.3 / 100.0, 0.0, 0.6)
		d.regen = a.vitality * 0.12
		d.lifesteal = clampf(a.luck * 0.3 / 100.0, 0.0, 0.5)
		d.block_capacity = 1 + int(a.strength / 22.0) + int(a.vitality / 26.0) + max(0, stars - 1)
		d.melee_damage = int(round(3 + a.strength * 0.55 + a.intelligence * 0.2))
		d.melee_attack_rate = 0.8 + a.agility * 0.02
		d.engage_radius = 84.0

	return d


static func _color_of(tower_class: int) -> Color:
	match tower_class:
		TowerData.TowerClass.ARCHER: return ARCHER_COLOR
		TowerData.TowerClass.MAGE: return MAGE_COLOR
		TowerData.TowerClass.WARRIOR: return WARRIOR_COLOR
		TowerData.TowerClass.PRIEST: return PRIEST_COLOR
	return Color.WHITE
