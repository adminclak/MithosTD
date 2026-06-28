class_name EquipmentList
extends RefCounted

## Catálogo de equipamentos do MVP grego. Vendidos na loja e dropados em fases.

static func all() -> Array:
	return [
		# Armas (+dano)
		EquipmentData.make("espada_bronze", "Espada de Bronze", \
			EquipmentData.Slot.WEAPON, EquipmentData.Rarity.COMMON, EquipmentData.Stat.DAMAGE, 0.10),
		EquipmentData.make("lanca_hoplita", "Lanca Hoplita", \
			EquipmentData.Slot.WEAPON, EquipmentData.Rarity.RARE, EquipmentData.Stat.DAMAGE, 0.22),
		EquipmentData.make("gladio_olimpico", "Gladio Olimpico", \
			EquipmentData.Slot.WEAPON, EquipmentData.Rarity.EPIC, EquipmentData.Stat.DAMAGE, 0.38),
		# Relíquias (stat secundário)
		EquipmentData.make("olho_aguia", "Olho de Aguia", \
			EquipmentData.Slot.RELIC, EquipmentData.Rarity.COMMON, EquipmentData.Stat.RANGE, 0.14),
		EquipmentData.make("sandalias_aladas", "Sandalias Aladas", \
			EquipmentData.Slot.RELIC, EquipmentData.Rarity.RARE, EquipmentData.Stat.FIRE_RATE, 0.20),
		EquipmentData.make("manto_couro", "Manto de Couro", \
			EquipmentData.Slot.RELIC, EquipmentData.Rarity.COMMON, EquipmentData.Stat.BLOCKER_HP, 0.18),
		EquipmentData.make("coroa_loureiro", "Coroa de Loureiro", \
			EquipmentData.Slot.RELIC, EquipmentData.Rarity.EPIC, EquipmentData.Stat.AURA_POWER, 0.30),
	]


static func by_id(target_id: String) -> EquipmentData:
	for e in all():
		if e.id == target_id:
			return e
	return null


static func price(rarity: int) -> int:
	match rarity:
		EquipmentData.Rarity.COMMON: return 120
		EquipmentData.Rarity.RARE: return 280
		EquipmentData.Rarity.EPIC: return 650
	return 999999


## Item aleatório para drop, com raridade ponderada pela fase (fases altas dão
## itens melhores). Retorna o id do item.
static func random_drop_id(stage_index: int) -> String:
	var items := all()
	var pool: Array = []
	for e in items:
		var weight := 1
		match e.rarity:
			EquipmentData.Rarity.COMMON:
				weight = 6
			EquipmentData.Rarity.RARE:
				weight = 2 + stage_index
			EquipmentData.Rarity.EPIC:
				weight = max(0, stage_index - 2)
		for i in weight:
			pool.append(e.id)
	if pool.is_empty():
		return items[0].id
	return pool[randi() % pool.size()]
