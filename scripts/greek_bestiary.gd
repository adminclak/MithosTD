class_name GreekBestiary
extends RefCounted

## Os 7 inimigos do mundo grego (seção 6 do design). Todos terrestres no MVP.

static func all() -> Array:
	return [
		_lacaio(), _espectro(), _esqueleto(), _hidra(), _hidra_filhote(),
		_centauro(), _ciclope(), _talos(),
	]


static func by_id(target_id: String) -> EnemyData:
	for e in all():
		if e.id == target_id:
			return e
	return null


# Básico equilibrado — preenche ondas.
static func _lacaio() -> EnemyData:
	return EnemyData.make("lacaio", "Lacaio", 12, 140.0, 5, 1, 3, 14.0, Color(0.85, 0.3, 0.3))


# Rápido e frágil — pressiona quem não tem bloqueio.
static func _espectro() -> EnemyData:
	var e := EnemyData.make("espectro", "Espectro Veloz", 8, 245.0, 6, 1, 2, 12.0, Color(0.55, 0.7, 0.95))
	e.attack_rate = 1.4
	return e


# Lento e resistente — esponja de dano (alta defesa: premia penetracao).
static func _esqueleto() -> EnemyData:
	var e := EnemyData.make("esqueleto", "Soldado Esqueleto", 46, 80.0, 11, 1, 4, 16.0, Color(0.8, 0.8, 0.72))
	e.defense = 5
	return e


# Ao morrer, divide em 2 filhotes — premia AoE.
static func _hidra() -> EnemyData:
	var e := EnemyData.make("hidra", "Hidra Menor", 24, 118.0, 12, 1, 3, 17.0, Color(0.3, 0.7, 0.4))
	e.special = EnemyData.Special.SPLIT
	e.split_into = "hidra_filhote"
	e.split_count = 2
	return e


static func _hidra_filhote() -> EnemyData:
	return EnemyData.make("hidra_filhote", "Filhote de Hidra", 8, 150.0, 3, 1, 2, 10.0, Color(0.45, 0.85, 0.55))


# Elite: rápido E forte — exige bloqueio + foco.
static func _centauro() -> EnemyData:
	var e := EnemyData.make("centauro", "Centauro", 64, 178.0, 20, 2, 6, 18.0, Color(0.6, 0.4, 0.25))
	e.attack_rate = 1.2
	e.defense = 3
	return e


# Elite: rapido E forte (sobrescreve para dar defesa).
# (centauro definido acima; aqui so reforço de defesa via _centauro)

# Mini-boss tanque, dano alto de perto.
static func _ciclope() -> EnemyData:
	var e := EnemyData.make("ciclope", "Ciclope", 150, 70.0, 30, 3, 11, 22.0, Color(0.45, 0.45, 0.5))
	e.defense = 8
	return e


# BOSS do mundo grego (fase 5): muita vida, investidas.
static func _talos() -> EnemyData:
	var e := EnemyData.make("talos", "Talos, o Colosso", 650, 60.0, 120, 5, 16, 30.0, Color(0.75, 0.55, 0.25))
	e.defense = 14
	return e
