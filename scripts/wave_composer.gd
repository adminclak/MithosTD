class_name WaveComposer
extends RefCounted

## Define a composição de cada onda por fase (quais inimigos e quantos), dando
## a cada fase do mundo grego o seu foco (seção 6 do design). Retorna uma lista
## de grupos { id, count }, spawnados em ordem (o boss vem por último).

static func compose(stage_index: int, wave_index: int, total_waves: int) -> Array:
	var w := wave_index
	match stage_index:
		1: # Campos de Elis — tutorial: só lacaios.
			return [{"id": "lacaio", "count": 4 + w}]
		2: # Bosque de Nemeia — espectros velozes (ensina o bloqueio).
			return [{"id": "lacaio", "count": 3 + w}, {"id": "espectro", "count": 1 + w}]
		3: # Pantano da Hidra — hidras que se dividem (premia AoE).
			return [{"id": "lacaio", "count": 2 + w}, {"id": "hidra", "count": 1 + int(w / 2.0)}]
		4: # Desfiladeiro dos Centauros — mistura pesada.
			var g4 := [{"id": "lacaio", "count": 2 + w}, {"id": "esqueleto", "count": 1 + int(w / 2.0)}]
			if w >= 3:
				g4.append({"id": "centauro", "count": 1 + int((w - 2) / 2.0)})
			return g4
		5: # Encosta do Olimpo — boss Talos na onda final.
			if w >= total_waves:
				return [{"id": "lacaio", "count": 6}, {"id": "ciclope", "count": 2}, {"id": "talos", "count": 1}]
			var g5 := [{"id": "lacaio", "count": 3 + w}, {"id": "esqueleto", "count": 1 + int(w / 2.0)}]
			if w >= 4:
				g5.append({"id": "ciclope", "count": 1})
			return g5
	return [{"id": "lacaio", "count": 4 + w}]
