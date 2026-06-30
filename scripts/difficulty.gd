class_name Difficulty
extends RefCounted

## Dificuldades de fase (endgame estilo Kingdom Rush). Cada tier multiplica a vida
## e a quantidade de inimigos (sobre os mults da própria fase) e as recompensas.
## Heroico libera ao vencer a fase no Normal; Lendário ao vencer no Heroico.
## Classe SEM cena (consts puros) para poder ser lida nos testes em modo -s.

const TIERS := [
	{"id": "normal", "name": "Normal", "hp": 1.0, "count": 1.0, "reward": 1.0,
		"color": Color(0.65, 0.85, 0.6)},
	{"id": "heroico", "name": "Heroico", "hp": 1.4, "count": 1.15, "reward": 1.6,
		"color": Color(1.0, 0.7, 0.3)},
	{"id": "lendario", "name": "Lendario", "hp": 1.9, "count": 1.3, "reward": 2.4,
		"color": Color(1.0, 0.4, 0.45)},
]


static func count() -> int:
	return TIERS.size()


static func tier(i: int) -> Dictionary:
	return TIERS[clampi(i, 0, TIERS.size() - 1)]


static func name_of(i: int) -> String:
	return String(tier(i)["name"])


static func color_of(i: int) -> Color:
	return tier(i)["color"]


static func hp_mult(i: int) -> float:
	return float(tier(i)["hp"])


static func count_mult(i: int) -> float:
	return float(tier(i)["count"])


static func reward_mult(i: int) -> float:
	return float(tier(i)["reward"])
