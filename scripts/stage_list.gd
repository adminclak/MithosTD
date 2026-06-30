class_name StageList
extends RefCounted

## As 5 fases do mundo grego (seção 6 do design). Dificuldade e nº de slots
## crescentes; concluir uma fase desbloqueia um novo personagem.

static func all() -> Array:
	# `slots` = TETO de heróis posicionáveis por fase (menor que o esquadrão de
	# propósito: o jogador escolhe quais levar pra cada fase). O campeão móvel não
	# ocupa slot, então o total em campo = slots + 1.
	return [
		_stage(1, "Campos de Elis", 4, 5, 1.2, 1.2, 50, "elis"),
		_stage(2, "Bosque de Nemeia", 4, 6, 1.45, 1.3, 62, "nemeia"),
		_stage(3, "Pantano da Hidra", 5, 7, 1.8, 1.5, 78, "pantano"),
		_stage(4, "Desfiladeiro dos Centauros", 5, 8, 2.1, 1.7, 98, "desfiladeiro"),
		_stage(5, "Encosta do Olimpo", 6, 8, 2.5, 1.9, 122, "olimpo"),
	]


static func get_stage(index: int) -> StageData:
	for s in all():
		if s.index == index:
			return s
	return null


static func count() -> int:
	return all().size()


static func _stage(idx: int, name: String, slots: int, waves: int, \
		hp_mult: float, count_mult: float, xp: int, theme: String = "Grega") -> StageData:
	var s := StageData.new()
	s.index = idx
	s.display_name = name
	s.slots = slots
	s.waves = waves
	s.enemy_hp_mult = hp_mult
	s.enemy_count_mult = count_mult
	s.xp_reward = xp
	s.theme = theme
	return s
