class_name Blessings
extends RefCounted

## Catálogo das "Bênçãos do Olimpo": melhorias PERMANENTES da conta, compradas com
## Essência (a moeda que antes não tinha uso). Cada bênção tem até MAX_LEVEL níveis;
## o efeito é (nível × per). `pct=true` = bônus percentual; senão é valor direto.
## Os efeitos são aplicados no orquestrador da partida (game_screen / main), nunca
## dentro do combate testável — ver Progression.bless_*.

const MAX_LEVEL := 5

# id, nome, descrição-base, valor por nível (per), percentual?, cor.
static func all() -> Array:
	return [
		{"id": "vida_base", "name": "Muralha de Atena", "desc": "vida da base",
			"per": 3, "pct": false, "color": Color(0.55, 0.8, 1.0)},
		{"id": "ouro_inicial", "name": "Riqueza de Hermes", "desc": "ouro inicial na partida",
			"per": 30, "pct": false, "color": Color(1.0, 0.84, 0.35)},
		{"id": "dano", "name": "Furia de Ares", "desc": "dano de todas as torres e do campeao",
			"per": 4, "pct": true, "color": Color(1.0, 0.45, 0.4)},
		{"id": "ouro_onda", "name": "Dadiva de Apolo", "desc": "ouro de bonus por onda",
			"per": 15, "pct": true, "color": Color(1.0, 0.78, 0.5)},
		{"id": "ult", "name": "Trovao de Zeus", "desc": "recarga do Poder Supremo",
			"per": 6, "pct": true, "color": Color(0.7, 0.7, 1.0)},
	]


static func by_id(id: String) -> Dictionary:
	for b in all():
		if b["id"] == id:
			return b
	return {}


## Custo em Essência para subir do nível atual (`level`) para o próximo.
static func cost(level: int) -> int:
	return 5 + level * 5  # 5, 10, 15, 20, 25 (total 75 p/ maximizar uma bênção)


## Texto do efeito acumulado num dado nível (ex.: "+12% dano..." ou "+90 ouro...").
static func effect_text(b: Dictionary, level: int) -> String:
	var v: int = int(b["per"]) * level
	if b.get("pct", false):
		return "+%d%% %s" % [v, b["desc"]]
	return "+%d %s" % [v, b["desc"]]
