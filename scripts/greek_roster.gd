class_name GreekRoster
extends RefCounted

## Catálogo dos 8 personagens do mundo grego (2 por classe). Cada um parte da
## factory da sua classe com pequenos ajustes de identidade (provisórios — o
## ajuste fino e as habilidades entram na Camada 6).
##
## unlock_stage: 0 = inicial (1 por classe); demais desbloqueiam ao concluir a
## fase indicada, dando ao jogador uma segunda opção por classe ao avançar.

static func all() -> Array:
	return [
		_artemis(), _hermes(),     # Arqueiros
		_hercules(), _ares(),      # Guerreiros
		_atena(), _apolo(),        # Sacerdotes
		_medusa(), _zeus(),        # Magos
	]


static func by_id(target_id: String) -> CharacterData:
	for c in all():
		if c.id == target_id:
			return c
	return null


# --- Arqueiros ---
static func _artemis() -> CharacterData:
	# Sniper: alcance altíssimo, cadência menor, dano maior.
	var d := TowerData.archer()
	d.attack_range = 270.0
	d.fire_rate = 1.3
	d.damage = 7
	return CharacterData.make("artemis", "Artemis", d, 0)


static func _hermes() -> CharacterData:
	# Metralhadora: cadência muito alta, dano menor.
	var d := TowerData.archer()
	d.attack_range = 175.0
	d.fire_rate = 4.0
	d.damage = 2
	return CharacterData.make("hermes", "Hermes", d, 1)


# --- Guerreiros ---
static func _hercules() -> CharacterData:
	# Tanque: bloqueadores com muita vida.
	var d := TowerData.warrior()
	d.blocker_hp = 60
	d.blocker_damage = 4
	return CharacterData.make("hercules", "Hercules", d, 0)


static func _ares() -> CharacterData:
	# Agressivo: mais dano, menos vida.
	var d := TowerData.warrior()
	d.blocker_hp = 30
	d.blocker_damage = 9
	return CharacterData.make("ares", "Ares", d, 2)


# --- Sacerdotes ---
static func _atena() -> CharacterData:
	# Buff forte de dano/cadência.
	var d := TowerData.priest()
	d.aura_damage_mult = 1.4
	d.aura_fire_rate_mult = 1.3
	d.aura_heal_per_sec = 3.0
	return CharacterData.make("atena", "Atena", d, 0)


static func _apolo() -> CharacterData:
	# Cura forte dos bloqueadores, buff menor.
	var d := TowerData.priest()
	d.aura_damage_mult = 1.15
	d.aura_fire_rate_mult = 1.1
	d.aura_heal_per_sec = 14.0
	return CharacterData.make("apolo", "Apolo", d, 3)


# --- Magos ---
static func _medusa() -> CharacterData:
	# AoE com mais lentidão futura (petrificação na Camada 6); raio de splash maior.
	var d := TowerData.mage()
	d.splash_radius = 90.0
	d.damage = 5
	return CharacterData.make("medusa", "Medusa", d, 0)


static func _zeus() -> CharacterData:
	# Raio: dano alto, alcance maior, splash menor (alvo concentrado).
	var d := TowerData.mage()
	d.attack_range = 200.0
	d.splash_radius = 55.0
	d.damage = 8
	d.fire_rate = 1.0
	return CharacterData.make("zeus", "Zeus", d, 4)
