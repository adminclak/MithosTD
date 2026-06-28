class_name EquipmentList
extends RefCounted

## Catálogo de equipamentos: dezenas de itens básicos (estilo Tibia, por material e
## slot) + lendários mitológicos (gorro do Saci, Mjölnir, Olho de Odin, Égide de
## Atena, Escudo de Perseu...). Total na casa das centenas. Cache p/ não remontar.

const S := EquipmentData.Slot
const R := EquipmentData.Rarity
const T := EquipmentData.Stat

static var _cache: Array = []


static func all() -> Array:
	if _cache.is_empty():
		_cache = _basics() + _legendaries()
	return _cache


static func count() -> int:
	return all().size()


static func by_id(target_id: String) -> EquipmentData:
	for e in all():
		if e.id == target_id:
			return e
	return null


# ---------------------------------------------------------------- básicos
# Materiais (sufixo id, nome, raridade, bônus base). Quanto melhor o material,
# maior o bônus e a raridade.
const MATS := [
	["couro", "de Couro", R.COMMON, 0.10],
	["bronze", "de Bronze", R.COMMON, 0.13],
	["osso", "de Osso", R.COMMON, 0.12],
	["ferro", "de Ferro", R.RARE, 0.18],
	["aco", "de Aco", R.RARE, 0.23],
	["viking", "Viking", R.RARE, 0.21],
	["ouro", "de Ouro", R.RARE, 0.20],
	["prata", "de Prata", R.EPIC, 0.30],
	["cobalto", "de Cobalto", R.EPIC, 0.36],
	["obsidiana", "de Obsidiana", R.EPIC, 0.38],
	["dragao", "de Dragao", R.EPIC, 0.41],
	["mithril", "de Mithril", R.EPIC, 0.44],
]

# Slots defensivos: base id, nome, stat principal.
const DEF_SLOTS := [
	[S.HELMET, "capacete", "Capacete", T.MAX_HP],
	[S.ARMOR, "armadura", "Armadura", T.MAX_HP],
	[S.LEGS, "calca", "Calca", T.DEFENSE],
	[S.BOOTS, "botas", "Botas", T.DODGE],
	[S.SHIELD, "escudo", "Escudo", T.DEFENSE],
]

# Armas básicas: id, nome, raridade base, dano base.
const WEAPONS := [
	["adaga", "Adaga", R.COMMON, 0.10],
	["espada_curta", "Espada Curta", R.COMMON, 0.14],
	["espada_longa", "Espada Longa", R.RARE, 0.20],
	["machado", "Machado de Batalha", R.RARE, 0.22],
	["maca", "Maca", R.RARE, 0.19],
	["lanca", "Lanca", R.RARE, 0.21],
	["arco_curto", "Arco Curto", R.COMMON, 0.13],
	["arco_longo", "Arco Longo", R.RARE, 0.20],
	["cajado", "Cajado Arcano", R.RARE, 0.20],
	["foice", "Foice de Guerra", R.EPIC, 0.27],
	["montante", "Montante", R.EPIC, 0.31],
	["alabarda", "Alabarda", R.EPIC, 0.28],
	["rapieira", "Rapieira", R.RARE, 0.18],
	["clava", "Clava", R.COMMON, 0.12],
	["cimitarra", "Cimitarra", R.RARE, 0.21],
	["tridente", "Tridente", R.RARE, 0.22],
	["martelo_guerra", "Martelo de Guerra", R.RARE, 0.23],
	["chicote", "Chicote", R.RARE, 0.17],
]

# Amuletos e anéis: id, nome, raridade, stat, valor.
const TRINKETS := [
	[S.AMULET, "amuleto_vista", "Amuleto da Vista", R.COMMON, T.RANGE, 0.12],
	[S.AMULET, "amuleto_foco", "Amuleto de Foco", R.COMMON, T.CRIT, 0.05],
	[S.AMULET, "amuleto_celere", "Amuleto Celere", R.RARE, T.FIRE_RATE, 0.16],
	[S.AMULET, "amuleto_vigor", "Amuleto de Vigor", R.RARE, T.MAX_HP, 0.20],
	[S.AMULET, "amuleto_vital", "Amuleto Vital", R.RARE, T.REGEN, 2.5],
	[S.AMULET, "amuleto_fluxo", "Amuleto de Fluxo", R.RARE, T.CDR, 0.10],
	[S.AMULET, "amuleto_sangrento", "Amuleto Sangrento", R.RARE, T.LIFESTEAL, 0.10],
	[S.AMULET, "amuleto_abencoado", "Amuleto Abencoado", R.EPIC, T.AURA_POWER, 0.26],
	[S.RING, "anel_cobre", "Anel de Cobre", R.COMMON, T.CRIT, 0.04],
	[S.RING, "anel_prata", "Anel de Prata", R.RARE, T.CRIT, 0.07],
	[S.RING, "anel_ouro", "Anel de Ouro", R.EPIC, T.CRIT, 0.11],
	[S.RING, "anel_furia", "Anel da Furia", R.RARE, T.DAMAGE, 0.12],
	[S.RING, "anel_perfurante", "Anel Perfurante", R.RARE, T.PENETRATION, 3.0],
	[S.RING, "anel_guarda", "Anel da Guarda", R.RARE, T.DEFENSE, 0.16],
	[S.RING, "anel_brisa", "Anel da Brisa", R.RARE, T.FIRE_RATE, 0.12],
	[S.RING, "anel_titan", "Anel do Tita", R.EPIC, T.MAX_HP, 0.22],
	[S.AMULET, "amuleto_perfuro", "Amuleto Perfurante", R.RARE, T.PENETRATION, 4.0],
	[S.AMULET, "amuleto_guarda", "Amuleto da Guarda", R.RARE, T.DEFENSE, 0.18],
	[S.AMULET, "amuleto_furia", "Amuleto da Furia", R.EPIC, T.DAMAGE, 0.20],
	[S.AMULET, "amuleto_muralha", "Amuleto Muralha", R.EPIC, T.BLOCK, 1.0],
	[S.RING, "anel_vampiro", "Anel Vampirico", R.EPIC, T.LIFESTEAL, 0.10],
	[S.RING, "anel_regen", "Anel Regenerativo", R.RARE, T.REGEN, 2.0],
	[S.RING, "anel_fluxo", "Anel de Fluxo", R.EPIC, T.CDR, 0.12],
	[S.RING, "anel_vista", "Anel da Vista", R.COMMON, T.RANGE, 0.10],
]


static func _basics() -> Array:
	var out: Array = []
	# Slots defensivos × materiais.
	for ds in DEF_SLOTS:
		for m in MATS:
			var rar: int = int(m[2])
			var val: float = float(m[3])
			# Botas (esquiva) usam valor menor; vida/defesa usam o cheio.
			if ds[3] == T.DODGE:
				val = val * 0.6
			out.append(EquipmentData.make(
				"%s_%s" % [ds[1], m[0]], "%s %s" % [ds[2], m[1]], ds[0], rar, ds[3], val))
	# Armas × (base / ferro / aço) — variações de material.
	var wmats := [["", "", 0.0, 0], ["_ferro", " de Ferro", 0.05, 0],
		["_aco", " de Aco", 0.11, 1], ["_prata", " de Prata", 0.16, 1]]
	for w in WEAPONS:
		for wm in wmats:
			var rar: int = min(R.EPIC, int(w[2]) + int(wm[3]))
			out.append(EquipmentData.make(
				"%s%s" % [w[0], wm[0]], "%s%s" % [w[1], wm[1]], S.WEAPON, rar,
				T.DAMAGE, float(w[3]) + float(wm[2])))
	# Amuletos e anéis.
	for tr in TRINKETS:
		out.append(EquipmentData.make(tr[1], tr[2], tr[0], tr[3], tr[4], float(tr[5])))
	return out


# ---------------------------------------------------------------- lendários
static func _legendaries() -> Array:
	# mk(id, nome, slot, LEGENDARY, [stats], [valores], icon=id)
	return [
		# --- Grega ---
		EquipmentData.mk("raio_zeus", "Raio de Zeus", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.CRIT], [0.45, 0.12], "raio_zeus"),
		EquipmentData.mk("tridente_poseidon", "Tridente de Poseidon", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.RANGE], [0.38, 0.20], "tridente_poseidon"),
		EquipmentData.mk("arco_artemis", "Arco de Artemis", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.FIRE_RATE], [0.32, 0.25], "arco_artemis"),
		EquipmentData.mk("harpe_perseu", "Harpe de Perseu", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.PENETRATION], [0.34, 5.0], "harpe_perseu"),
		EquipmentData.mk("egide_atena", "Egide de Atena", S.SHIELD, R.LEGENDARY, [T.DEFENSE, T.MAX_HP], [0.40, 0.30], "egide_atena"),
		EquipmentData.mk("escudo_perseu", "Escudo Espelhado de Perseu", S.SHIELD, R.LEGENDARY, [T.DEFENSE, T.DODGE], [0.30, 0.18], "escudo_perseu"),
		EquipmentData.mk("elmo_hades", "Elmo de Hades", S.HELMET, R.LEGENDARY, [T.DODGE, T.CRIT], [0.20, 0.10], "elmo_hades"),
		EquipmentData.mk("sandalias_hermes", "Sandalias Aladas de Hermes", S.BOOTS, R.LEGENDARY, [T.FIRE_RATE, T.RANGE], [0.25, 0.15], "sandalias_hermes"),
		EquipmentData.mk("pele_leao_nemeia", "Pele do Leao de Nemeia", S.ARMOR, R.LEGENDARY, [T.MAX_HP, T.DEFENSE], [0.40, 0.30], "pele_leao_nemeia"),
		EquipmentData.mk("lira_apolo", "Lira de Apolo", S.AMULET, R.LEGENDARY, [T.AURA_POWER, T.CDR], [0.35, 0.15], "lira_apolo"),
		EquipmentData.mk("velocino_ouro", "Velocino de Ouro", S.AMULET, R.LEGENDARY, [T.MAX_HP, T.REGEN], [0.25, 5.0], "velocino_ouro"),
		EquipmentData.mk("coroa_louros", "Coroa de Louros", S.HELMET, R.LEGENDARY, [T.AURA_POWER, T.MAX_HP], [0.30, 0.18], "coroa_louros"),
		# --- Nordica ---
		EquipmentData.mk("mjolnir", "Mjolnir", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.CRIT], [0.42, 0.14], "mjolnir"),
		EquipmentData.mk("gungnir", "Gungnir", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.PENETRATION], [0.36, 6.0], "gungnir"),
		EquipmentData.mk("olho_odin", "Olho de Odin", S.AMULET, R.LEGENDARY, [T.RANGE, T.CRIT], [0.22, 0.12], "olho_odin"),
		EquipmentData.mk("draupnir", "Draupnir", S.RING, R.LEGENDARY, [T.DAMAGE, T.FIRE_RATE], [0.18, 0.15], "draupnir"),
		EquipmentData.mk("brisingamen", "Brisingamen", S.AMULET, R.LEGENDARY, [T.AURA_POWER, T.LIFESTEAL], [0.28, 0.12], "brisingamen"),
		EquipmentData.mk("megingjord", "Megingjord", S.LEGS, R.LEGENDARY, [T.DAMAGE, T.MAX_HP], [0.25, 0.25], "megingjord"),
		EquipmentData.mk("escudo_valquiria", "Escudo da Valquiria", S.SHIELD, R.LEGENDARY, [T.DEFENSE, T.REGEN], [0.32, 4.0], "escudo_valquiria"),
		EquipmentData.mk("botas_vidar", "Botas de Vidar", S.BOOTS, R.LEGENDARY, [T.DEFENSE, T.DODGE], [0.22, 0.15], "botas_vidar"),
		# --- Egipcia ---
		EquipmentData.mk("olho_horus", "Olho de Horus", S.AMULET, R.LEGENDARY, [T.RANGE, T.CRIT], [0.25, 0.12], "olho_horus"),
		EquipmentData.mk("olho_ra", "Olho de Ra", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.RANGE], [0.40, 0.18], "olho_ra"),
		EquipmentData.mk("khopesh_real", "Khopesh Real", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.LIFESTEAL], [0.34, 0.12], "khopesh_real"),
		EquipmentData.mk("cetro_uas", "Cetro Uas", S.WEAPON, R.LEGENDARY, [T.AURA_POWER, T.CDR], [0.30, 0.15], "cetro_uas"),
		EquipmentData.mk("ankh_vida", "Ankh da Vida", S.AMULET, R.LEGENDARY, [T.REGEN, T.MAX_HP], [6.0, 0.20], "ankh_vida"),
		EquipmentData.mk("coroa_pschent", "Coroa Pschent", S.HELMET, R.LEGENDARY, [T.AURA_POWER, T.DEFENSE], [0.28, 0.20], "coroa_pschent"),
		EquipmentData.mk("escudo_anubis", "Escudo de Anubis", S.SHIELD, R.LEGENDARY, [T.DEFENSE, T.PENETRATION], [0.30, 4.0], "escudo_anubis"),
		# --- Chinesa ---
		EquipmentData.mk("ruyi_jingu", "Bastao Ruyi Jingu", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.BLOCK], [0.40, 1.0], "ruyi_jingu"),
		EquipmentData.mk("perola_dragao", "Perola do Dragao", S.AMULET, R.LEGENDARY, [T.AURA_POWER, T.CDR], [0.30, 0.16], "perola_dragao"),
		EquipmentData.mk("arco_houyi", "Arco de Hou Yi", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.RANGE], [0.36, 0.22], "arco_houyi"),
		EquipmentData.mk("rodas_nezha", "Rodas de Vento e Fogo", S.BOOTS, R.LEGENDARY, [T.FIRE_RATE, T.DODGE], [0.24, 0.14], "rodas_nezha"),
		EquipmentData.mk("armadura_guanyu", "Armadura de Guan Yu", S.ARMOR, R.LEGENDARY, [T.DEFENSE, T.MAX_HP], [0.34, 0.30], "armadura_guanyu"),
		# --- Japonesa ---
		EquipmentData.mk("kusanagi", "Kusanagi-no-Tsurugi", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.CRIT], [0.40, 0.12], "kusanagi"),
		EquipmentData.mk("espelho_yata", "Espelho Yata", S.SHIELD, R.LEGENDARY, [T.DEFENSE, T.AURA_POWER], [0.28, 0.22], "espelho_yata"),
		EquipmentData.mk("joia_yasakani", "Joia Yasakani", S.AMULET, R.LEGENDARY, [T.AURA_POWER, T.REGEN], [0.26, 4.0], "joia_yasakani"),
		EquipmentData.mk("oyoroi", "Armadura O-yoroi", S.ARMOR, R.LEGENDARY, [T.DEFENSE, T.MAX_HP], [0.36, 0.28], "oyoroi"),
		EquipmentData.mk("kabuto_oni", "Kabuto Demoniaco", S.HELMET, R.LEGENDARY, [T.DEFENSE, T.CRIT], [0.24, 0.10], "kabuto_oni"),
		# --- Brasileira ---
		EquipmentData.mk("gorro_saci", "Gorro do Saci", S.HELMET, R.LEGENDARY, [T.FIRE_RATE, T.DODGE], [0.22, 0.16], "gorro_saci"),
		EquipmentData.mk("pes_virados", "Pes Virados do Curupira", S.BOOTS, R.LEGENDARY, [T.DODGE, T.FIRE_RATE], [0.20, 0.18], "pes_virados"),
		EquipmentData.mk("olhos_boitata", "Olhos do Boitata", S.AMULET, R.LEGENDARY, [T.DAMAGE, T.CRIT], [0.24, 0.12], "olhos_boitata"),
		EquipmentData.mk("couraca_mapinguari", "Couraca do Mapinguari", S.ARMOR, R.LEGENDARY, [T.MAX_HP, T.DEFENSE], [0.42, 0.26], "couraca_mapinguari"),
		EquipmentData.mk("muiraquita", "Muiraquita", S.AMULET, R.LEGENDARY, [T.REGEN, T.LIFESTEAL], [5.0, 0.10], "muiraquita"),
		# --- Asteca ---
		EquipmentData.mk("macuahuitl", "Macuahuitl", S.WEAPON, R.LEGENDARY, [T.DAMAGE, T.PENETRATION], [0.38, 5.0], "macuahuitl"),
		EquipmentData.mk("chimalli_quetzal", "Chimalli de Quetzalcoatl", S.SHIELD, R.LEGENDARY, [T.DEFENSE, T.AURA_POWER], [0.30, 0.20], "chimalli_quetzal"),
		EquipmentData.mk("espelho_fumegante", "Espelho Fumegante", S.AMULET, R.LEGENDARY, [T.CRIT, T.CDR], [0.12, 0.14], "espelho_fumegante"),
		EquipmentData.mk("penacho_moctezuma", "Penacho de Moctezuma", S.HELMET, R.LEGENDARY, [T.AURA_POWER, T.RANGE], [0.26, 0.16], "penacho_moctezuma"),
		EquipmentData.mk("coracao_obsidiana", "Coracao de Obsidiana", S.AMULET, R.LEGENDARY, [T.LIFESTEAL, T.DAMAGE], [0.14, 0.20], "coracao_obsidiana"),
	]


# ---------------------------------------------------------------- economia
static func price(rarity: int) -> int:
	match rarity:
		R.COMMON: return 120
		R.RARE: return 300
		R.EPIC: return 700
		R.LEGENDARY: return 1800
	return 999999


## Item aleatório para drop, com raridade ponderada pela fase.
static func random_drop_id(stage_index: int) -> String:
	var items := all()
	var pool: Array = []
	for e in items:
		var weight := 1
		match e.rarity:
			R.COMMON: weight = 8
			R.RARE: weight = 3 + stage_index
			R.EPIC: weight = max(0, stage_index - 1)
			R.LEGENDARY: weight = max(0, stage_index - 3)
		for i in weight:
			pool.append(e.id)
	if pool.is_empty():
		return items[0].id
	return pool[randi() % pool.size()]
