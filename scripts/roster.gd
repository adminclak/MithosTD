class_name Roster
extends RefCounted

## Roster completo de personagens (todas as mitologias). Cada entrada é
## [id, nome, mitologia, arquétipo]. Os stats vêm do arquétipo (ver Archetypes).
## Todos começam desbloqueados (unlock_stage 0) — decisão da madrugada para dar
## "livre escolha"; o gating de desbloqueio fica para um balanceamento futuro
## (ver NOTAS_DA_MADRUGADA.md).

const MYTHOLOGIES := ["Grega", "Nordica", "Japonesa", "Brasileira", "Egipcia", "Chinesa", "Asteca"]

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

## Personagens iniciais: 1 por mitologia (variando classes). O resto é conquistado.
const STARTERS := ["artemis", "odin", "benkei", "iara", "horus", "longwang", "huitzilo"]


static func is_starter(id: String) -> bool:
	return STARTERS.has(id)


static func rarity_of(id: String) -> int:
	var legendary := ["zeus", "odin", "ra", "thor", "amaterasu", "sunwukong", "quetzal", "susanoo"]
	var epic := ["hercules", "ares", "medusa", "atena", "loki", "freya", "raijin", "set",
		"sekhmet", "houyi", "guanyu", "nuwa", "huitzilo", "tlaloc", "anubis", "hachiman"]
	var common := ["hermes", "ullr", "saci", "boto", "neith", "nezha", "camazotz",
		"mixcoatl", "cuca", "kannon", "frigg", "tezca"]
	if legendary.has(id):
		return Rarity.LEGENDARY
	if epic.has(id):
		return Rarity.EPIC
	if common.has(id):
		return Rarity.COMMON
	return Rarity.RARE


static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON: return "Comum"
		Rarity.RARE: return "Raro"
		Rarity.EPIC: return "Epico"
		Rarity.LEGENDARY: return "Lendario"
	return "?"


static func ids_by_rarity(r: int) -> Array:
	var out: Array = []
	for d in defs():
		if rarity_of(d[0]) == r:
			out.append(d[0])
	return out


# [id, nome, mitologia, arquétipo]. Função (não const) porque referencia enums
# de outra classe, que não são expressões constantes em GDScript.
static func defs() -> Array:
	var K := Archetypes.Kind
	return [
		# --- Grega ---
		["artemis", "Artemis", "Grega", K.ARCHER_SNIPER],
		["hermes", "Hermes", "Grega", K.ARCHER_RAPID],
		["hercules", "Hercules", "Grega", K.WARRIOR_TANK],
		["ares", "Ares", "Grega", K.WARRIOR_DPS],
		["atena", "Atena", "Grega", K.PRIEST_BUFF],
		["apolo", "Apolo", "Grega", K.PRIEST_HEAL],
		["medusa", "Medusa", "Grega", K.MAGE_AOE],
		["zeus", "Zeus", "Grega", K.MAGE_BURST],
		# --- Nordica ---
		["heimdall", "Heimdall", "Nordica", K.ARCHER_SNIPER],
		["ullr", "Ullr", "Nordica", K.ARCHER_RAPID],
		["thor", "Thor", "Nordica", K.WARRIOR_DPS],
		["tyr", "Tyr", "Nordica", K.WARRIOR_TANK],
		["freya", "Freya", "Nordica", K.PRIEST_HEAL],
		["frigg", "Frigg", "Nordica", K.PRIEST_BUFF],
		["odin", "Odin", "Nordica", K.MAGE_BURST],
		["loki", "Loki", "Nordica", K.MAGE_AOE],
		# --- Japonesa ---
		["tsukuyomi", "Tsukuyomi", "Japonesa", K.ARCHER_SNIPER],
		["hachiman", "Hachiman", "Japonesa", K.ARCHER_RAPID],
		["susanoo", "Susanoo", "Japonesa", K.WARRIOR_DPS],
		["benkei", "Benkei", "Japonesa", K.WARRIOR_TANK],
		["amaterasu", "Amaterasu", "Japonesa", K.PRIEST_BUFF],
		["kannon", "Kannon", "Japonesa", K.PRIEST_HEAL],
		["raijin", "Raijin", "Japonesa", K.MAGE_BURST],
		["fujin", "Fujin", "Japonesa", K.MAGE_AOE],
		# --- Brasileira ---
		["curupira", "Curupira", "Brasileira", K.ARCHER_RAPID],
		["anhanga", "Anhanga", "Brasileira", K.ARCHER_SNIPER],
		["mapinguari", "Mapinguari", "Brasileira", K.WARRIOR_TANK],
		["cuca", "Cuca", "Brasileira", K.WARRIOR_DPS],
		["iara", "Iara", "Brasileira", K.PRIEST_HEAL],
		["boto", "Boto", "Brasileira", K.PRIEST_BUFF],
		["saci", "Saci", "Brasileira", K.MAGE_AOE],
		["boitata", "Boitata", "Brasileira", K.MAGE_BURST],
		# --- Egipcia ---
		["horus", "Horus", "Egipcia", K.ARCHER_SNIPER],
		["neith", "Neith", "Egipcia", K.ARCHER_RAPID],
		["anubis", "Anubis", "Egipcia", K.WARRIOR_TANK],
		["set", "Set", "Egipcia", K.WARRIOR_DPS],
		["isis", "Isis", "Egipcia", K.PRIEST_HEAL],
		["thoth", "Thoth", "Egipcia", K.PRIEST_BUFF],
		["ra", "Ra", "Egipcia", K.MAGE_BURST],
		["sekhmet", "Sekhmet", "Egipcia", K.MAGE_AOE],
		# --- Chinesa ---
		["houyi", "Hou Yi", "Chinesa", K.ARCHER_SNIPER],
		["nezha", "Nezha", "Chinesa", K.ARCHER_RAPID],
		["sunwukong", "Sun Wukong", "Chinesa", K.WARRIOR_DPS],
		["guanyu", "Guan Yu", "Chinesa", K.WARRIOR_TANK],
		["nuwa", "Nuwa", "Chinesa", K.PRIEST_BUFF],
		["guanyin", "Guanyin", "Chinesa", K.PRIEST_HEAL],
		["longwang", "Long Wang", "Chinesa", K.MAGE_AOE],
		["erlang", "Erlang", "Chinesa", K.MAGE_BURST],
		# --- Asteca ---
		["mixcoatl", "Mixcoatl", "Asteca", K.ARCHER_SNIPER],
		["camazotz", "Camazotz", "Asteca", K.ARCHER_RAPID],
		["huitzilo", "Huitzilopochtli", "Asteca", K.WARRIOR_DPS],
		["mictlan", "Mictlantecuhtli", "Asteca", K.WARRIOR_TANK],
		["xochi", "Xochiquetzal", "Asteca", K.PRIEST_HEAL],
		["tezca", "Tezcatlipoca", "Asteca", K.PRIEST_BUFF],
		["quetzal", "Quetzalcoatl", "Asteca", K.MAGE_BURST],
		["tlaloc", "Tlaloc", "Asteca", K.MAGE_AOE],
	]


static func all() -> Array:
	var out: Array = []
	for d in defs():
		out.append(CharacterData.from_archetype(d[0], d[1], d[2], d[3], 0))
	return out


static func by_id(target_id: String) -> CharacterData:
	for d in defs():
		if d[0] == target_id:
			return CharacterData.from_archetype(d[0], d[1], d[2], d[3], 0)
	return null


static func ids_by_mythology(myth: String) -> Array:
	var out: Array = []
	for d in defs():
		if d[2] == myth:
			out.append(d[0])
	return out


static func count() -> int:
	return defs().size()
