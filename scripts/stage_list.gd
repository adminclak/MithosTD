class_name StageList
extends RefCounted

## As 5 fases do mundo grego (seção 6 do design). Dificuldade e nº de slots
## crescentes; concluir uma fase desbloqueia um novo personagem.

static func all() -> Array:
	return [
		_stage(1, "Campos de Elis", 5, 5, 1.0, 1.0, 50, "Grega"),
		_stage(2, "Bosque de Nemeia", 6, 6, 1.15, 1.1, 62, "Grega"),
		_stage(3, "Pantano da Hidra", 6, 7, 1.3, 1.2, 78, "Grega"),
		_stage(4, "Desfiladeiro dos Centauros", 7, 8, 1.6, 1.3, 98, "Grega"),
		_stage(5, "Encosta do Olimpo", 8, 8, 2.1, 1.45, 122, "Grega"),
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
