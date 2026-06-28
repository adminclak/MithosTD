class_name AttributeStats
extends RefCounted

## Converte um AttributeSet + classe num TowerData (stats de combate). É a ponte
## entre o sistema de atributos (Ragnarok-like) e o motor de torres existente.
## Ajustar as fórmulas aqui rebalanceia o jogo inteiro de forma centralizada.

const ARCHER_COLOR := Color(0.30, 0.55, 0.95)
const MAGE_COLOR := Color(0.62, 0.32, 0.85)
const WARRIOR_COLOR := Color(0.88, 0.28, 0.28)
const PRIEST_COLOR := Color(0.96, 0.86, 0.22)


static func build(tower_class: int, a: AttributeSet) -> TowerData:
	var d := TowerData.new()
	d.tower_class = tower_class
	match tower_class:
		TowerData.TowerClass.ARCHER:
			d.cost = 100
			d.body_color = ARCHER_COLOR
			d.projectile_color = Color(1.0, 1.0, 0.5)
			d.damage = int(round(2 + a.strength * 0.45 + a.dexterity * 0.15))
			d.fire_rate = 0.6 + a.agility * 0.035 + a.dexterity * 0.012
			d.attack_range = 150.0 + a.dexterity * 1.5
		TowerData.TowerClass.MAGE:
			d.cost = 150
			d.body_color = MAGE_COLOR
			d.projectile_color = Color(0.78, 0.48, 1.0)
			d.damage = int(round(3 + a.intelligence * 0.6 + a.strength * 0.1))
			d.fire_rate = 0.45 + a.agility * 0.02 + a.dexterity * 0.006
			d.attack_range = 135.0 + a.dexterity * 1.1
			d.splash_radius = 52.0 + a.intelligence * 0.28
		TowerData.TowerClass.WARRIOR:
			d.cost = 120
			d.body_color = WARRIOR_COLOR
			d.blocker_count = 2
			d.blocker_hp = int(round(16 + a.vitality * 1.5 + a.strength * 0.4))
			d.blocker_damage = int(round(2 + a.strength * 0.5 + a.dexterity * 0.1))
			d.blocker_attack_rate = 0.8 + a.agility * 0.02
			d.blocker_move_speed = 100.0 + a.agility * 1.2
			d.blocker_engage_radius = 50.0
			d.blocker_respawn_time = 4.0
		TowerData.TowerClass.PRIEST:
			d.cost = 130
			d.body_color = PRIEST_COLOR
			d.aura_radius = 135.0 + a.dexterity * 0.9
			d.aura_damage_mult = 1.10 + a.intelligence * 0.006
			d.aura_fire_rate_mult = 1.06 + a.intelligence * 0.004
			d.aura_slow_mult = clampf(0.88 - a.intelligence * 0.003, 0.40, 0.95)
			d.aura_heal_per_sec = 1.5 + a.intelligence * 0.22

	# Crítico (todas as classes): LUK domina, DEX ajuda.
	d.crit_chance = clampf((a.luck * 0.4 + a.dexterity * 0.15) / 100.0, 0.0, 0.6)
	d.crit_mult = 1.5 + a.luck * 0.012
	return d
