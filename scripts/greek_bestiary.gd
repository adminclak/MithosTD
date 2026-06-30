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


# Básico equilibrado — preenche ondas. Baseline de tudo (ouro ~ HP/3).
static func _lacaio() -> EnemyData:
	var e := EnemyData.make("lacaio", "Lacaio", 16, 140.0, 5, 1, 3, 14.0, Color(0.85, 0.3, 0.3))
	e.element = Elements.E.TERRA
	return e


# Rápido e frágil — pressiona quem não tem bloqueio (prêmio por ser irritante).
static func _espectro() -> EnemyData:
	var e := EnemyData.make("espectro", "Espectro Veloz", 12, 245.0, 6, 1, 2, 12.0, Color(0.55, 0.7, 0.95))
	e.attack_rate = 1.4
	e.element = Elements.E.AR
	return e


# Lento e resistente — esponja de dano (defesa média: premia penetracao/AoE).
static func _esqueleto() -> EnemyData:
	var e := EnemyData.make("esqueleto", "Soldado Esqueleto", 56, 80.0, 15, 1, 4, 16.0, Color(0.8, 0.8, 0.72))
	e.defense = 4
	e.element = Elements.E.TREVAS
	return e


# Ao morrer, divide em 2 filhotes — premia AoE.
static func _hidra() -> EnemyData:
	var e := EnemyData.make("hidra", "Hidra Menor", 34, 118.0, 12, 1, 3, 17.0, Color(0.3, 0.7, 0.4))
	e.special = EnemyData.Special.SPLIT
	e.split_into = "hidra_filhote"
	e.split_count = 2
	e.element = Elements.E.AGUA
	return e


static func _hidra_filhote() -> EnemyData:
	var e := EnemyData.make("hidra_filhote", "Filhote de Hidra", 12, 150.0, 4, 1, 2, 10.0, Color(0.45, 0.85, 0.55))
	e.element = Elements.E.AGUA
	return e


# Elite: rápido E forte — exige bloqueio + foco.
static func _centauro() -> EnemyData:
	var e := EnemyData.make("centauro", "Centauro", 80, 178.0, 22, 2, 6, 18.0, Color(0.6, 0.4, 0.25))
	e.attack_rate = 1.2
	e.defense = 3
	e.element = Elements.E.TERRA
	return e


# Mini-boss tanque, dano alto de perto (defesa alta: premia penetracao/elemento).
static func _ciclope() -> EnemyData:
	var e := EnemyData.make("ciclope", "Ciclope", 175, 70.0, 40, 3, 11, 22.0, Color(0.45, 0.45, 0.5))
	e.defense = 7
	e.element = Elements.E.FOGO
	return e


# BOSS do mundo grego (fase 5): muita vida, investidas. ~6x o Ciclope, não 50x
# o básico (com hp_mult 2.0 da fase 5 fica ~1120, batível por um esquadrão focado).
static func _talos() -> EnemyData:
	var e := EnemyData.make("talos", "Talos, o Colosso", 560, 60.0, 160, 5, 16, 30.0, Color(0.75, 0.55, 0.25))
	e.defense = 12
	e.element = Elements.E.LUZ
	return e
