class_name Quests
extends RefCounted

## Catálogo de quests: marcos de campanha (uma vez) + diárias (renovam por dia).
## metric é lido do Progression (metric_value). Recompensa em Ambrosia.

static func all() -> Array:
	return [
		# Campanha (permanentes)
		{"id": "q_stage1", "desc": "Conclua a Fase 1", "metric": "stage", "target": 2, "daily": false, "ambrosia": 50},
		{"id": "q_stage3", "desc": "Conclua a Fase 3", "metric": "stage", "target": 4, "daily": false, "ambrosia": 100},
		{"id": "q_gacha1", "desc": "Use o Altar (gacha) 1 vez", "metric": "gacha", "target": 1, "daily": false, "ambrosia": 30},
		{"id": "q_evolve1", "desc": "Evolua 1 heroi", "metric": "evolves", "target": 1, "daily": false, "ambrosia": 80},
		{"id": "q_wins5", "desc": "Venca 5 partidas", "metric": "wins", "target": 5, "daily": false, "ambrosia": 120},
		# Diárias (renovam a cada dia)
		{"id": "d_win2", "desc": "Venca 2 partidas hoje", "metric": "daily_wins", "target": 2, "daily": true, "ambrosia": 40},
		{"id": "d_gacha1", "desc": "Use o Altar hoje", "metric": "daily_gacha", "target": 1, "daily": true, "ambrosia": 20},
	]


static func by_id(qid: String) -> Dictionary:
	for q in all():
		if q["id"] == qid:
			return q
	return {}
