class_name Archetypes
extends RefCounted

## Arquétipos = presets de classe + atributos base + crescimento por nível +
## habilidade. Permitem criar dezenas de personagens balanceados de forma
## compacta (cada personagem só escolhe um arquétipo). Ajuste fino de cada
## personagem fica para depois (ver NOTAS_DA_MADRUGADA.md).

enum Kind {
	ARCHER_SNIPER, ARCHER_RAPID,
	MAGE_AOE, MAGE_BURST,
	WARRIOR_TANK, WARRIOR_DPS,
	PRIEST_BUFF, PRIEST_HEAL,
}


static func tower_class_of(kind: int) -> int:
	match kind:
		Kind.ARCHER_SNIPER, Kind.ARCHER_RAPID:
			return TowerData.TowerClass.ARCHER
		Kind.MAGE_AOE, Kind.MAGE_BURST:
			return TowerData.TowerClass.MAGE
		Kind.WARRIOR_TANK, Kind.WARRIOR_DPS:
			return TowerData.TowerClass.WARRIOR
		Kind.PRIEST_BUFF, Kind.PRIEST_HEAL:
			return TowerData.TowerClass.PRIEST
	return TowerData.TowerClass.ARCHER


# AttributeSet base (nível 1): STR, AGI, VIT, INT, DEX, LUK.
static func base_attr(kind: int) -> AttributeSet:
	match kind:
		Kind.ARCHER_SNIPER: return AttributeSet.make(22, 12, 12, 8, 30, 14)
		Kind.ARCHER_RAPID:  return AttributeSet.make(12, 32, 12, 8, 22, 16)
		Kind.MAGE_AOE:      return AttributeSet.make(8, 14, 12, 30, 18, 12)
		Kind.MAGE_BURST:    return AttributeSet.make(8, 10, 10, 36, 16, 14)
		Kind.WARRIOR_TANK:  return AttributeSet.make(18, 12, 34, 6, 12, 10)
		Kind.WARRIOR_DPS:   return AttributeSet.make(30, 18, 18, 6, 14, 12)
		Kind.PRIEST_BUFF:   return AttributeSet.make(8, 14, 16, 30, 20, 12)
		Kind.PRIEST_HEAL:   return AttributeSet.make(8, 12, 22, 28, 16, 12)
	return AttributeSet.make(15, 15, 15, 15, 15, 15)


# Crescimento por nível.
static func growth_attr(kind: int) -> AttributeSet:
	match kind:
		Kind.ARCHER_SNIPER: return AttributeSet.make(2, 1, 1, 1, 2, 1)
		Kind.ARCHER_RAPID:  return AttributeSet.make(1, 2, 1, 1, 2, 1)
		Kind.MAGE_AOE:      return AttributeSet.make(1, 1, 1, 2, 1, 1)
		Kind.MAGE_BURST:    return AttributeSet.make(1, 1, 1, 3, 1, 1)
		Kind.WARRIOR_TANK:  return AttributeSet.make(1, 1, 3, 1, 1, 1)
		Kind.WARRIOR_DPS:   return AttributeSet.make(3, 1, 1, 1, 1, 1)
		Kind.PRIEST_BUFF:   return AttributeSet.make(1, 1, 1, 2, 2, 1)
		Kind.PRIEST_HEAL:   return AttributeSet.make(1, 1, 2, 2, 1, 1)
	return AttributeSet.make(1, 1, 1, 1, 1, 1)


static func ability(kind: int) -> AbilityData:
	match kind:
		Kind.ARCHER_SNIPER:
			return AbilityData.make("ab_sniper", "Tiro Perfurante", AbilityData.Kind.DAMAGE_AOE, 28.0, 230.0, 28.0, 0.0)
		Kind.ARCHER_RAPID:
			return AbilityData.make("ab_rapid", "Frenesi de Flechas", AbilityData.Kind.BUFF_TOWER, 24.0, 30.0, 2.0, 5.0)
		Kind.MAGE_AOE:
			return AbilityData.make("ab_petrify", "Explosao Petrificante", AbilityData.Kind.STUN_AOE, 36.0, 185.0, 12.0, 2.5)
		Kind.MAGE_BURST:
			return AbilityData.make("ab_meteor", "Meteoro Arcano", AbilityData.Kind.DAMAGE_AOE, 32.0, 205.0, 40.0, 0.0)
		Kind.WARRIOR_TANK:
			return AbilityData.make("ab_wall", "Muralha Inquebravel", AbilityData.Kind.SHIELD_BLOCKERS, 34.0, 220.0, 0.0, 5.0)
		Kind.WARRIOR_DPS:
			return AbilityData.make("ab_charge", "Investida Furiosa", AbilityData.Kind.DAMAGE_AOE, 30.0, 165.0, 24.0, 0.0)
		Kind.PRIEST_BUFF:
			return AbilityData.make("ab_bless", "Bencao de Guerra", AbilityData.Kind.BUFF_TOWER, 32.0, 210.0, 1.7, 8.0)
		Kind.PRIEST_HEAL:
			return AbilityData.make("ab_heal", "Luz Restauradora", AbilityData.Kind.HEAL_BLOCKERS, 28.0, 210.0, 40.0, 0.0)
	return AbilityData.make("ab_none", "Habilidade", AbilityData.Kind.DAMAGE_AOE, 30.0, 180.0, 20.0, 0.0)
