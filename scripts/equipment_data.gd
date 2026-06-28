class_name EquipmentData
extends Resource

## Um equipamento. 2 slots por personagem: Arma (ofensivo) e Relíquia (stat
## secundário). Raridade define a magnitude (stat fixo, sem nível de item no MVP).
## value é uma fração (0.20 = +20%).

enum Slot { WEAPON, RELIC }
enum Rarity { COMMON, RARE, EPIC }
enum Stat { DAMAGE, RANGE, FIRE_RATE, BLOCKER_HP, AURA_POWER }

@export var id: String = ""
@export var display_name: String = ""
@export var slot: Slot = Slot.WEAPON
@export var rarity: Rarity = Rarity.COMMON
@export var stat: Stat = Stat.DAMAGE
@export var value: float = 0.1


static func make(p_id: String, p_name: String, p_slot: Slot, p_rarity: Rarity, \
		p_stat: Stat, p_value: float) -> EquipmentData:
	var e := EquipmentData.new()
	e.id = p_id
	e.display_name = p_name
	e.slot = p_slot
	e.rarity = p_rarity
	e.stat = p_stat
	e.value = p_value
	return e


## Aplica o bônus deste equipamento a um TowerData (cópia da partida).
func apply_to(d: TowerData) -> void:
	var f := 1.0 + value
	match stat:
		Stat.DAMAGE:
			d.damage = int(round(d.damage * f))
			d.blocker_damage = int(round(d.blocker_damage * f))
		Stat.RANGE:
			d.attack_range *= f
		Stat.FIRE_RATE:
			d.fire_rate *= f
		Stat.BLOCKER_HP:
			d.blocker_hp = int(round(d.blocker_hp * f))
		Stat.AURA_POWER:
			d.aura_heal_per_sec *= f
			if d.aura_damage_mult > 1.0:
				d.aura_damage_mult = 1.0 + (d.aura_damage_mult - 1.0) * f
				d.aura_fire_rate_mult = 1.0 + (d.aura_fire_rate_mult - 1.0) * f


static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON: return "Comum"
		Rarity.RARE: return "Raro"
		Rarity.EPIC: return "Epico"
	return "?"
