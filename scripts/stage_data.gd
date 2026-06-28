class_name StageData
extends Resource

## Uma fase do mundo grego. A geometria (rota/posições exatas) é reaproveitada
## do Level no MVP; a Camada 6 desenha rotas próprias por fase. Aqui ficam os
## parâmetros de dificuldade, recompensa e desbloqueios.

@export var index: int = 1
@export var display_name: String = ""
@export var slots: int = 5
@export var waves: int = 5
@export var enemy_hp_mult: float = 1.0
@export var enemy_count_mult: float = 1.0
@export var xp_reward: int = 50

## Personagens desbloqueados ao concluir esta fase (derivado do roster por
## unlock_stage == index — fonte única de verdade do desbloqueio).
func unlock_ids() -> Array:
	var ids: Array = []
	for c in GreekRoster.all():
		if c.unlock_stage == index:
			ids.append(c.id)
	return ids
