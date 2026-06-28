class_name EquipSets
extends RefCounted

## Conjuntos de equipamento (set bonus). Usar 2 peças do mesmo set dá um bônus
## menor; 4 peças dá um bônus forte (somado ao de 2). Os membros são itens
## lendários temáticos. Aplicado ao TowerData na montagem da partida.

const T := EquipmentData.Stat

const SETS := {
	"olimpo": {
		"name": "Trajes do Olimpo",
		"members": ["raio_zeus", "egide_atena", "sandalias_hermes", "coroa_louros"],
		"two": [[T.DAMAGE, 0.12]],
		"four": [[T.DAMAGE, 0.22], [T.CRIT, 0.10]],
	},
	"asgard": {
		"name": "Heranca de Asgard",
		"members": ["mjolnir", "olho_odin", "megingjord", "botas_vidar"],
		"two": [[T.MAX_HP, 0.12]],
		"four": [[T.DAMAGE, 0.18], [T.DEFENSE, 0.20]],
	},
	"egito": {
		"name": "Tesouros do Nilo",
		"members": ["olho_ra", "khopesh_real", "ankh_vida", "coroa_pschent"],
		"two": [[T.FIRE_RATE, 0.12]],
		"four": [[T.AURA_POWER, 0.25], [T.LIFESTEAL, 0.10]],
	},
}


static func set_of(item_id: String) -> String:
	for sid in SETS:
		if item_id in SETS[sid]["members"]:
			return sid
	return ""


static func name_of(sid: String) -> String:
	return SETS[sid]["name"] if SETS.has(sid) else "?"


## Conta peças por set e aplica os bônus (2 e 4) ao TowerData.
## `items` = Array de EquipmentData equipados. Devolve textos dos bônus ativos.
static func apply(d: TowerData, items: Array) -> Array:
	var counts := {}
	for it in items:
		if it != null and it.set_id != "":
			counts[it.set_id] = counts.get(it.set_id, 0) + 1
	var active: Array = []
	for sid in counts:
		var n: int = counts[sid]
		var s: Dictionary = SETS.get(sid, {})
		if s.is_empty():
			continue
		if n >= 2:
			for m in s["two"]:
				EquipmentData.apply_stat(d, m[0], m[1])
			active.append("%s (2)" % s["name"])
		if n >= 4:
			for m in s["four"]:
				EquipmentData.apply_stat(d, m[0], m[1])
			active.append("%s (4)" % s["name"])
	return active
