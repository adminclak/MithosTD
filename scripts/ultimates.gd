class_name Ultimates
extends RefCounted

## Catálogo de Poderes Supremos. Cada personagem tem um ult temático: os
## icônicos têm assinatura própria (OVERRIDES); os demais herdam um estilo pela
## classe. `for_character(cid)` sempre devolve um UltimateData válido.

const S := UltimateData.Style

# id do personagem -> [style, nome, cor]
static func _overrides() -> Dictionary:
	return {
		"zeus":      [S.LIGHTNING, "Ira do Olimpo", Color(0.8, 0.9, 1.0)],
		"poseidon":  [S.FLOOD, "Maremoto", Color(0.3, 0.7, 1.0)],
		"hades":     [S.VOID, "Portao do Submundo", Color(0.6, 0.2, 0.8)],
		"ares":      [S.QUAKE, "Massacre de Guerra", Color(0.9, 0.3, 0.2)],
		"artemis":   [S.METEOR, "Chuva da Cacadora", Color(0.7, 1.0, 0.7)],
		"hercules":  [S.QUAKE, "Golpe Titanico", Color(1.0, 0.7, 0.3)],
		"atena":     [S.DIVINE, "Egide Sagrada", Color(1.0, 0.95, 0.5)],
		"medusa":    [S.BLIZZARD, "Olhar Petrificante", Color(0.6, 0.85, 0.7)],
		"odin":      [S.VOID, "Lanca Gungnir", Color(0.5, 0.5, 0.7)],
		"thor":      [S.LIGHTNING, "Trovao de Mjolnir", Color(0.7, 0.85, 1.0)],
		"loki":      [S.VOID, "Engano Sombrio", Color(0.4, 0.8, 0.4)],
		"freya":     [S.DIVINE, "Bencao de Folkvangr", Color(1.0, 0.8, 0.6)],
		"ra":        [S.INFERNO, "Sol Abrasador", Color(1.0, 0.6, 0.1)],
		"anubis":    [S.VOID, "Juizo dos Mortos", Color(0.5, 0.3, 0.7)],
		"horus":     [S.DIVINE, "Olho de Horus", Color(1.0, 0.9, 0.4)],
		"iara":      [S.FLOOD, "Canto das Aguas", Color(0.3, 0.8, 0.9)],
		"longwang":  [S.FLOOD, "Furia do Dragao", Color(0.2, 0.7, 0.9)],
		"huitzilo":  [S.INFERNO, "Sol Guerreiro", Color(1.0, 0.55, 0.2)],
		"benkei":    [S.QUAKE, "Investida do Templo", Color(0.9, 0.6, 0.3)],
		"amaterasu": [S.DIVINE, "Luz do Amanhecer", Color(1.0, 0.95, 0.7)],
		"susanoo":   [S.LIGHTNING, "Tempestade Divina", Color(0.7, 0.8, 1.0)],
	}


static func for_character(cid: String) -> UltimateData:
	var ch := Roster.by_id(cid)
	var name := ch.display_name if ch != null else "Heroi"
	var ov := _overrides()
	if ov.has(cid):
		var e: Array = ov[cid]
		return UltimateData.make("ult_" + cid, e[1], e[0], 70.0, e[2])
	# Fallback por classe.
	var cls := ch.tower_class if ch != null else TowerData.TowerClass.ARCHER
	match cls:
		TowerData.TowerClass.ARCHER:
			return UltimateData.make("ult_" + cid, "Chuva de Flechas de " + name, S.METEOR, 62.0, Color(0.9, 1.0, 0.6))
		TowerData.TowerClass.MAGE:
			return UltimateData.make("ult_" + cid, "Cataclismo de " + name, S.INFERNO, 68.0, Color(1.0, 0.6, 0.2))
		TowerData.TowerClass.WARRIOR:
			return UltimateData.make("ult_" + cid, "Furia de " + name, S.QUAKE, 68.0, Color(1.0, 0.7, 0.3))
		TowerData.TowerClass.PRIEST:
			return UltimateData.make("ult_" + cid, "Bencao de " + name, S.DIVINE, 52.0, Color(1.0, 0.95, 0.6))
	return UltimateData.make("ult_" + cid, "Poder de " + name, S.METEOR, 62.0, Color(1, 0.8, 0.3))
