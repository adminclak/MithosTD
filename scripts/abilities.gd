class_name Abilities
extends RefCounted

## Catálogo de habilidades de assinatura por personagem (tema do mito + família
## de efeito). Os números base saem do tipo de efeito (_mk); o tema/nome é único
## por personagem. Se um id não tiver entrada aqui, cai na habilidade do arquétipo.

const K := AbilityData.Kind


# Números padrão por família de efeito (balanceáveis aqui de uma vez).
static func _mk(id: String, name: String, kind: int) -> AbilityData:
	match kind:
		K.DAMAGE_AOE: return AbilityData.make(id, name, kind, 30.0, 175.0, 26.0, 0.0)
		K.LINE:       return AbilityData.make(id, name, kind, 28.0, 240.0, 34.0, 0.0)
		K.CHAIN:      return AbilityData.make(id, name, kind, 30.0, 220.0, 22.0, 0.0)
		K.STUN_AOE:   return AbilityData.make(id, name, kind, 36.0, 180.0, 12.0, 2.5)
		K.SLOW_AOE:   return AbilityData.make(id, name, kind, 26.0, 190.0, 8.0, 4.0)
		K.KNOCKBACK:  return AbilityData.make(id, name, kind, 24.0, 165.0, 12.0, 0.0)
		K.DOT_AOE:    return AbilityData.make(id, name, kind, 28.0, 175.0, 14.0, 4.0)
		K.BUFF_TOWER: return AbilityData.make(id, name, kind, 30.0, 205.0, 1.6, 7.0)
		K.HEAL_BLOCKERS: return AbilityData.make(id, name, kind, 26.0, 205.0, 45.0, 0.0)
		K.SHIELD_BLOCKERS: return AbilityData.make(id, name, kind, 34.0, 215.0, 0.0, 5.0)
		K.SUMMON:     return AbilityData.make(id, name, kind, 32.0, 0.0, 14.0, 9.0)
	return AbilityData.make(id, name, K.DAMAGE_AOE, 30.0, 175.0, 24.0, 0.0)


static func for_character(cid: String) -> AbilityData:
	match cid:
		# --- Grega ---
		"artemis": return _mk("ab_artemis", "Chuva de Flechas", K.LINE)
		"hermes": return _mk("ab_hermes", "Velocidade Divina", K.BUFF_TOWER)
		"hercules": return _mk("ab_hercules", "Forca Indomavel", K.SHIELD_BLOCKERS)
		"ares": return _mk("ab_ares", "Furia de Guerra", K.DAMAGE_AOE)
		"atena": return _mk("ab_atena", "Egide de Atena", K.BUFF_TOWER)
		"apolo": return _mk("ab_apolo", "Luz Solar", K.HEAL_BLOCKERS)
		"medusa": return _mk("ab_medusa", "Olhar Petrificante", K.STUN_AOE)
		"zeus": return _mk("ab_zeus", "Tempestade do Olimpo", K.CHAIN)
		# --- Nordica ---
		"heimdall": return _mk("ab_heimdall", "Vigia de Bifrost", K.LINE)
		"ullr": return _mk("ab_ullr", "Frio do Inverno", K.SLOW_AOE)
		"thor": return _mk("ab_thor", "Mjolnir", K.CHAIN)
		"tyr": return _mk("ab_tyr", "Sacrificio de Tyr", K.SHIELD_BLOCKERS)
		"freya": return _mk("ab_freya", "Bencao de Freya", K.HEAL_BLOCKERS)
		"frigg": return _mk("ab_frigg", "Profecia de Frigg", K.BUFF_TOWER)
		"odin": return _mk("ab_odin", "Gungnir", K.LINE)
		"loki": return _mk("ab_loki", "Veneno de Jormungandr", K.DOT_AOE)
		# --- Japonesa ---
		"tsukuyomi": return _mk("ab_tsukuyomi", "Lamina da Lua", K.LINE)
		"hachiman": return _mk("ab_hachiman", "Arco de Hachiman", K.BUFF_TOWER)
		"susanoo": return _mk("ab_susanoo", "Kusanagi", K.DAMAGE_AOE)
		"benkei": return _mk("ab_benkei", "Guarda da Ponte", K.SHIELD_BLOCKERS)
		"amaterasu": return _mk("ab_amaterasu", "Luz de Amaterasu", K.BUFF_TOWER)
		"kannon": return _mk("ab_kannon", "Misericordia", K.HEAL_BLOCKERS)
		"raijin": return _mk("ab_raijin", "Tambores do Trovao", K.CHAIN)
		"fujin": return _mk("ab_fujin", "Rajada de Vento", K.KNOCKBACK)
		# --- Brasileira ---
		"curupira": return _mk("ab_curupira", "Pes Virados", K.SLOW_AOE)
		"anhanga": return _mk("ab_anhanga", "Cacador Espectral", K.LINE)
		"mapinguari": return _mk("ab_mapinguari", "Couraca de Pedra", K.SHIELD_BLOCKERS)
		"cuca": return _mk("ab_cuca", "Garras da Cuca", K.DAMAGE_AOE)
		"iara": return _mk("ab_iara", "Canto da Iara", K.STUN_AOE)
		"boto": return _mk("ab_boto", "Encanto do Boto", K.BUFF_TOWER)
		"saci": return _mk("ab_saci", "Redemoinho", K.KNOCKBACK)
		"boitata": return _mk("ab_boitata", "Fogo da Boitata", K.DOT_AOE)
		# --- Egipcia ---
		"horus": return _mk("ab_horus", "Olho de Horus", K.LINE)
		"neith": return _mk("ab_neith", "Tear da Guerra", K.BUFF_TOWER)
		"anubis": return _mk("ab_anubis", "Guardiao dos Mortos", K.SHIELD_BLOCKERS)
		"set": return _mk("ab_set", "Tempestade de Set", K.DAMAGE_AOE)
		"isis": return _mk("ab_isis", "Magia de Isis", K.HEAL_BLOCKERS)
		"thoth": return _mk("ab_thoth", "Sabedoria de Thoth", K.BUFF_TOWER)
		"ra": return _mk("ab_ra", "Chama Solar", K.DOT_AOE)
		"sekhmet": return _mk("ab_sekhmet", "Furia da Leoa", K.DAMAGE_AOE)
		# --- Chinesa ---
		"houyi": return _mk("ab_houyi", "Flecha que Abate o Sol", K.LINE)
		"nezha": return _mk("ab_nezha", "Rodas de Fogo", K.DOT_AOE)
		"sunwukong": return _mk("ab_sunwukong", "Bastao Dourado", K.DAMAGE_AOE)
		"guanyu": return _mk("ab_guanyu", "Lealdade Eterna", K.SHIELD_BLOCKERS)
		"nuwa": return _mk("ab_nuwa", "Reparo do Ceu", K.BUFF_TOWER)
		"guanyin": return _mk("ab_guanyin", "Compaixao", K.HEAL_BLOCKERS)
		"longwang": return _mk("ab_longwang", "Furia do Dragao", K.SLOW_AOE)
		"erlang": return _mk("ab_erlang", "Terceiro Olho", K.CHAIN)
		# --- Asteca ---
		"mixcoatl": return _mk("ab_mixcoatl", "Caca Estelar", K.LINE)
		"camazotz": return _mk("ab_camazotz", "Morcego Sangrento", K.DOT_AOE)
		"huitzilo": return _mk("ab_huitzilo", "Serpente de Fogo", K.DAMAGE_AOE)
		"mictlan": return _mk("ab_mictlan", "Legiao dos Mortos", K.SUMMON)
		"xochi": return _mk("ab_xochi", "Flor Sagrada", K.HEAL_BLOCKERS)
		"tezca": return _mk("ab_tezca", "Espelho Fumegante", K.BUFF_TOWER)
		"quetzal": return _mk("ab_quetzal", "Serpente Emplumada", K.CHAIN)
		"tlaloc": return _mk("ab_tlaloc", "Chuva de Tlaloc", K.SLOW_AOE)
	return null
