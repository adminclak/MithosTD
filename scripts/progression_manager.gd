extends Node
## Autoload: estado meta persistente entre partidas — níveis/XP dos personagens,
## desbloqueios e fase mais alta liberada. Save/load local em user:// (JSON).
##
## Acesse pelo nó /root/Progression (em scripts testáveis headless) ou pelo
## global Progression (no jogo). Ver a pegadinha de autoload no modo -s.

const SAVE_PATH := "user://mithos_save.json"
const SQUAD_MAX := 6
const PERM_LEVEL_STEP := 0.04

# Teto de nível por estrela (⭐/⭐⭐/⭐⭐⭐).
const LEVEL_CAP := {1: 10, 2: 20, 3: 30}

signal progress_changed

var highest_stage_unlocked: int = 1 ## maior fase liberada para jogar
var meta_essence: int = 0           ## recurso de evolução (gasto na Camada 5)
var characters: Dictionary = {}     ## id -> { unlocked, level, xp, stars }


func _ready() -> void:
	load_game()


# --- Consultas ---
func get_char(id: String) -> Dictionary:
	_ensure_defaults()
	return characters.get(id, {})


func is_unlocked(id: String) -> bool:
	return get_char(id).get("unlocked", false)


func unlocked_ids() -> Array:
	_ensure_defaults()
	var ids: Array = []
	for c in GreekRoster.all():
		if characters[c.id]["unlocked"]:
			ids.append(c.id)
	return ids


func level_of(id: String) -> int:
	return get_char(id).get("level", 1)


func stars_of(id: String) -> int:
	return get_char(id).get("stars", 1)


func level_cap(id: String) -> int:
	return LEVEL_CAP.get(stars_of(id), 10)


## XP necessário para subir do nível atual para o próximo (curva suave).
func xp_to_next(level: int) -> int:
	return 40 + (level - 1) * 30


# --- Mutações ---
func add_essence(amount: int) -> void:
	meta_essence += amount
	emit_signal("progress_changed")


## Concede XP a todos os personagens da lista (esquadrão levado). Retorna um
## resumo { id: { gained, levels_gained, new_level } } para a tela de resultado.
func grant_squad_xp(ids: Array, amount: int) -> Dictionary:
	_ensure_defaults()
	var summary: Dictionary = {}
	for id in ids:
		if not characters.has(id):
			continue
		var before: int = characters[id]["level"]
		_add_xp(id, amount)
		summary[id] = {
			"gained": amount,
			"levels_gained": characters[id]["level"] - before,
			"new_level": characters[id]["level"],
		}
	emit_signal("progress_changed")
	return summary


func _add_xp(id: String, amount: int) -> void:
	var c: Dictionary = characters[id]
	var cap: int = level_cap(id)
	c["xp"] += amount
	while c["level"] < cap and c["xp"] >= xp_to_next(c["level"]):
		c["xp"] -= xp_to_next(c["level"])
		c["level"] += 1
	if c["level"] >= cap:
		c["xp"] = 0 # no teto, não acumula até evoluir a estrela


## Marca a fase como concluída: libera a próxima fase e desbloqueia os
## personagens daquela fase. Retorna a lista de ids recém-desbloqueados.
func mark_stage_cleared(index: int) -> Array:
	_ensure_defaults()
	if index + 1 > highest_stage_unlocked and index < StageList.count():
		highest_stage_unlocked = index + 1
	var newly: Array = []
	for c in GreekRoster.all():
		if c.unlock_stage == index and not characters[c.id]["unlocked"]:
			characters[c.id]["unlocked"] = true
			newly.append(c.id)
	emit_signal("progress_changed")
	return newly


# --- Defaults / persistência ---
func _ensure_defaults() -> void:
	for c in GreekRoster.all():
		if not characters.has(c.id):
			characters[c.id] = {
				"unlocked": c.unlock_stage == 0,
				"level": 1,
				"xp": 0,
				"stars": 1,
			}


func reset() -> void:
	characters = {}
	highest_stage_unlocked = 1
	meta_essence = 0
	_ensure_defaults()
	emit_signal("progress_changed")


func save_game() -> void:
	save_to(SAVE_PATH)


func load_game() -> void:
	load_from(SAVE_PATH)


func save_to(path: String) -> void:
	_ensure_defaults()
	var payload := {
		"version": 1,
		"highest_stage_unlocked": highest_stage_unlocked,
		"meta_essence": meta_essence,
		"characters": characters,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func load_from(path: String) -> void:
	if not FileAccess.file_exists(path):
		_ensure_defaults()
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ensure_defaults()
		return
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		_ensure_defaults()
		return
	highest_stage_unlocked = int(data.get("highest_stage_unlocked", 1))
	meta_essence = int(data.get("meta_essence", 0))
	characters = {}
	var saved: Dictionary = data.get("characters", {})
	for id in saved.keys():
		var e: Dictionary = saved[id]
		characters[id] = {
			"unlocked": bool(e.get("unlocked", false)),
			"level": int(e.get("level", 1)),
			"xp": int(e.get("xp", 0)),
			"stars": int(e.get("stars", 1)),
		}
	_ensure_defaults() # garante personagens novos que não estavam no save
