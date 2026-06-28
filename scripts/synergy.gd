class_name Synergy
extends RefCounted

## Sinergias de equipe: bônus por compor o esquadrão. Tipos: mitologia (3+ iguais),
## classe (3+ iguais ou 1 de cada), elemento (3+ iguais) e duplas/trios icônicos.
## `active(ids)` lista as sinergias ligadas; `apply()` soma os bônus a todos.

const T := EquipmentData.Stat
const CLASS_NAMES := ["Arqueiros", "Magos", "Guerreiros", "Sacerdotes"]

# Combinações de assinatura: ids necessários -> nome + bônus.
const COMBOS := [
	{"ids": ["zeus", "poseidon", "hades"], "name": "Os Tres Tronos", "mods": [[T.DAMAGE, 0.20], [T.CRIT, 0.10]]},
	{"ids": ["ares", "atena"], "name": "Guerra e Estrategia", "mods": [[T.DAMAGE, 0.12], [T.DEFENSE, 0.12]]},
	{"ids": ["artemis", "apolo"], "name": "Gemeos de Leto", "mods": [[T.RANGE, 0.15], [T.FIRE_RATE, 0.10]]},
	{"ids": ["thor", "odin", "loki"], "name": "Trio de Asgard", "mods": [[T.DAMAGE, 0.18]]},
	{"ids": ["ra", "anubis", "horus"], "name": "Panteao do Nilo", "mods": [[T.DAMAGE, 0.15], [T.AURA_POWER, 0.15]]},
]


## Lista as sinergias ativas: [{name, mods:[[stat,val]...]}].
static func active(squad_ids: Array) -> Array:
	var myth := {}
	var cls := {}
	var elem := {}
	for id in squad_ids:
		var ch := Roster.by_id(id)
		if ch == null:
			continue
		myth[ch.mythology] = myth.get(ch.mythology, 0) + 1
		cls[ch.tower_class] = cls.get(ch.tower_class, 0) + 1
		var e := Elements.of_character(id)
		elem[e] = elem.get(e, 0) + 1

	var out: Array = []
	for m in myth:
		if myth[m] >= 3:
			out.append({"name": "Alianca %s (%d)" % [m, myth[m]], "mods": [[T.DAMAGE, 0.10]]})
	for c in cls:
		if cls[c] >= 3:
			out.append({"name": "Tropa de %s" % CLASS_NAMES[c], "mods": [[T.FIRE_RATE, 0.12]]})
	if cls.size() >= 4:
		out.append({"name": "Equipe Equilibrada", "mods": [[T.DAMAGE, 0.08], [T.MAX_HP, 0.08]]})
	for e in elem:
		if elem[e] >= 3:
			out.append({"name": "Furia de %s (%d)" % [Elements.name_of(e), elem[e]], "mods": [[T.DAMAGE, 0.15]]})
	for combo in COMBOS:
		var ok := true
		for need in combo["ids"]:
			if not squad_ids.has(need):
				ok = false
				break
		if ok:
			out.append({"name": combo["name"], "mods": combo["mods"]})
	return out


## Aplica os bônus de todas as sinergias ativas a cada TowerData do esquadrão.
static func apply(squad_ids: Array, squad_datas: Array) -> Array:
	var syn := active(squad_ids)
	for s in syn:
		for d in squad_datas:
			for m in s["mods"]:
				EquipmentData.apply_stat(d, m[0], m[1])
	return syn
