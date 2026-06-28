class_name EquipmentData
extends Resource

## Um equipamento. 8 slots estilo Tibia (elmo, peito, pernas, botas, arma, escudo,
## amuleto, anel). Cada item tem 1+ modificadores (stat + valor). A raridade define
## a magnitude/preço. `icon` vazio = usa o ícone genérico do slot; senão usa um
## ícone único (lendários). value: fração (0.20=+20%) p/ stats multiplicativos;
## adição direta p/ crit/esquiva/cdr/lifesteal; contagem p/ penetração/bloqueio.

enum Slot { HELMET, ARMOR, LEGS, BOOTS, WEAPON, SHIELD, AMULET, RING }
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum Stat {
	DAMAGE, RANGE, FIRE_RATE, MAX_HP, DEFENSE, CRIT, PENETRATION,
	DODGE, LIFESTEAL, REGEN, AURA_POWER, CDR, BLOCK,
}

const SLOT_NAMES := ["Elmo", "Peito", "Pernas", "Botas", "Arma", "Escudo", "Amuleto", "Anel"]
const SLOT_KEYS := ["helmet", "armor", "legs", "boots", "weapon", "shield", "amulet", "ring"]
const STAT_NAMES := ["Dano", "Alcance", "Vel. Ataque", "Vida", "Defesa", "Crítico",
	"Penetração", "Esquiva", "Roubo de Vida", "Regeneração", "Poder de Aura",
	"Red. Recarga", "Bloqueio"]

@export var id: String = ""
@export var display_name: String = ""
@export var slot: int = Slot.WEAPON
@export var rarity: int = Rarity.COMMON
@export var stats: PackedInt32Array = PackedInt32Array()  ## quais Stat
@export var values: PackedFloat32Array = PackedFloat32Array() ## valor de cada um
@export var icon: String = "" ## id de ícone único (lendários); "" = genérico do slot
@export var set_id: String = "" ## conjunto a que pertence (p/ bônus de 2/4 peças)


static func make(p_id: String, p_name: String, p_slot: int, p_rarity: int, \
		p_stat: int, p_value: float) -> EquipmentData:
	return mk(p_id, p_name, p_slot, p_rarity, [p_stat], [p_value])


## Versão multi-stat (lendários costumam ter 2-3 efeitos).
static func mk(p_id: String, p_name: String, p_slot: int, p_rarity: int, \
		p_stats: Array, p_values: Array, p_icon: String = "") -> EquipmentData:
	var e := EquipmentData.new()
	e.id = p_id
	e.display_name = p_name
	e.slot = p_slot
	e.rarity = p_rarity
	e.stats = PackedInt32Array(p_stats)
	e.values = PackedFloat32Array(p_values)
	e.icon = p_icon
	return e


## Aplica todos os modificadores deste item a um TowerData (cópia da partida).
func apply_to(d: TowerData) -> void:
	for i in stats.size():
		_apply_one(d, stats[i], values[i])


func _apply_one(d: TowerData, stat: int, value: float) -> void:
	apply_stat(d, stat, value)


## Aplica UM modificador a um TowerData (estático: reutilizado por sets/sinergias).
static func apply_stat(d: TowerData, stat: int, value: float) -> void:
	var f := 1.0 + value
	match stat:
		Stat.DAMAGE:
			d.damage = int(round(d.damage * f))
			d.melee_damage = int(round(d.melee_damage * f))
		Stat.RANGE:
			d.attack_range *= f
		Stat.FIRE_RATE:
			d.fire_rate *= f
			d.melee_attack_rate *= f
		Stat.MAX_HP:
			d.max_hp = int(round(d.max_hp * f))
		Stat.DEFENSE:
			d.defense = int(round(d.defense * f)) + int(round(value * 6.0))
		Stat.CRIT:
			d.crit_chance = clampf(d.crit_chance + value, 0.0, 0.85)
		Stat.PENETRATION:
			d.penetration += int(round(value))
		Stat.DODGE:
			d.dodge = clampf(d.dodge + value, 0.0, 0.7)
		Stat.LIFESTEAL:
			d.lifesteal = clampf(d.lifesteal + value, 0.0, 0.6)
		Stat.REGEN:
			d.regen += value
		Stat.AURA_POWER:
			d.aura_heal_per_sec *= f
			if d.aura_damage_mult > 1.0:
				d.aura_damage_mult = 1.0 + (d.aura_damage_mult - 1.0) * f
				d.aura_fire_rate_mult = 1.0 + (d.aura_fire_rate_mult - 1.0) * f
		Stat.CDR:
			d.cdr = clampf(d.cdr + value, 0.0, 0.6)
		Stat.BLOCK:
			d.block_capacity += int(round(value))


## Resumo legível dos efeitos (p/ tooltips/loja).
func effects_text() -> String:
	var parts: Array = []
	for i in stats.size():
		var s: int = stats[i]
		var v: float = values[i]
		var txt: String = STAT_NAMES[s]
		match s:
			Stat.PENETRATION, Stat.BLOCK:
				parts.append("+%d %s" % [int(round(v)), txt])
			Stat.CRIT, Stat.DODGE, Stat.LIFESTEAL, Stat.CDR:
				parts.append("+%d%% %s" % [int(round(v * 100.0)), txt])
			Stat.REGEN:
				parts.append("+%.1f %s" % [v, txt])
			_:
				parts.append("+%d%% %s" % [int(round(v * 100.0)), txt])
	return ", ".join(parts)


## Id de ícone: o único (lendário) se houver; senão o genérico do slot.
func icon_id() -> String:
	return icon if icon != "" else "slot_" + SLOT_KEYS[slot]


static func slot_name(s: int) -> String:
	return SLOT_NAMES[s] if s >= 0 and s < SLOT_NAMES.size() else "?"


static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON: return "Comum"
		Rarity.RARE: return "Raro"
		Rarity.EPIC: return "Epico"
		Rarity.LEGENDARY: return "Lendario"
	return "?"


static func rarity_color(r: int) -> Color:
	match r:
		Rarity.COMMON: return Color(0.80, 0.80, 0.82)
		Rarity.RARE: return Color(0.35, 0.65, 1.0)
		Rarity.EPIC: return Color(0.75, 0.40, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.72, 0.22)
	return Color.WHITE
