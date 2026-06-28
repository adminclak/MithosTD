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
var meta_essence: int = 0           ## recurso de evolução (estrelas)
var meta_gold: int = 0              ## ouro meta (loja), ganho ao concluir fases
var characters: Dictionary = {}     ## id -> { unlocked, level, xp, stars }
var inventory: Array = []           ## ids de equipamentos possuídos (sem repetição)
var equipped: Dictionary = {}       ## char_id -> { weapon: id, relic: id }


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
	for c in Roster.all():
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
	for c in Roster.all():
		if c.unlock_stage == index and not characters[c.id]["unlocked"]:
			characters[c.id]["unlocked"] = true
			newly.append(c.id)
	emit_signal("progress_changed")
	return newly


# --- Recursos meta (loja) ---
func add_meta_gold(amount: int) -> void:
	meta_gold += amount
	emit_signal("progress_changed")


func spend_meta_gold(amount: int) -> bool:
	if meta_gold < amount:
		return false
	meta_gold -= amount
	emit_signal("progress_changed")
	return true


# --- Equipamentos ---
func _ensure_equip(char_id: String) -> void:
	if not equipped.has(char_id):
		equipped[char_id] = {"weapon": "", "relic": ""}


func owns_item(item_id: String) -> bool:
	return inventory.has(item_id)


func add_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
	emit_signal("progress_changed")


func _item_owner(item_id: String) -> String:
	for cid in equipped.keys():
		var e: Dictionary = equipped[cid]
		if e.get("weapon", "") == item_id or e.get("relic", "") == item_id:
			return cid
	return ""


func is_item_available(item_id: String) -> bool:
	return owns_item(item_id) and _item_owner(item_id) == ""


func available_items() -> Array:
	var out: Array = []
	for id in inventory:
		if _item_owner(id) == "":
			out.append(id)
	return out


func equipped_ids(char_id: String) -> Dictionary:
	_ensure_equip(char_id)
	return equipped[char_id].duplicate()


func equipped_data(char_id: String) -> Array:
	var out: Array = []
	var ids := equipped_ids(char_id)
	for key in ["weapon", "relic"]:
		var item_id: String = ids.get(key, "")
		if item_id != "":
			var item := EquipmentList.by_id(item_id)
			if item != null:
				out.append(item)
	return out


func equip(char_id: String, slot: int, item_id: String) -> bool:
	var item := EquipmentList.by_id(item_id)
	if item == null or item.slot != slot or not owns_item(item_id):
		return false
	var owner := _item_owner(item_id)
	if owner != "" and owner != char_id:
		return false # equipado em outro personagem
	_ensure_equip(char_id)
	var key := "weapon" if slot == EquipmentData.Slot.WEAPON else "relic"
	equipped[char_id][key] = item_id
	emit_signal("progress_changed")
	return true


func unequip(char_id: String, slot: int) -> void:
	_ensure_equip(char_id)
	var key := "weapon" if slot == EquipmentData.Slot.WEAPON else "relic"
	equipped[char_id][key] = ""
	emit_signal("progress_changed")


func buy_item(item_id: String) -> bool:
	var item := EquipmentList.by_id(item_id)
	if item == null or owns_item(item_id):
		return false
	if not spend_meta_gold(EquipmentList.price(item.rarity)):
		return false
	add_item(item_id)
	return true


# --- Evolução de estrela ---
func evolve_cost(char_id: String) -> Dictionary:
	match stars_of(char_id):
		1: return {"essence": 10, "gold": 300}
		2: return {"essence": 25, "gold": 800}
	return {} # já no máximo


func can_evolve(char_id: String) -> bool:
	var cost := evolve_cost(char_id)
	if cost.is_empty():
		return false
	return meta_essence >= cost["essence"] and meta_gold >= cost["gold"]


func evolve(char_id: String) -> bool:
	if not can_evolve(char_id):
		return false
	var cost := evolve_cost(char_id)
	meta_essence -= cost["essence"]
	meta_gold -= cost["gold"]
	characters[char_id]["stars"] += 1
	emit_signal("progress_changed")
	return true


# --- Recompensas de fim de fase ---
func grant_rewards(stage_index: int, victory: bool) -> Dictionary:
	_ensure_defaults()
	var r := {"gold": 0, "essence": 0, "item_id": ""}
	if victory:
		r["gold"] = 30 + stage_index * 15
		r["essence"] = 2 + stage_index
		if randf() < 0.6:
			var id := EquipmentList.random_drop_id(stage_index)
			if owns_item(id):
				r["essence"] += 3 # duplicado vira essência
			else:
				add_item(id)
				r["item_id"] = id
	else:
		r["gold"] = 10
		r["essence"] = 1
	meta_gold += r["gold"]
	meta_essence += r["essence"]
	emit_signal("progress_changed")
	return r


# --- Defaults / persistência ---
func _ensure_defaults() -> void:
	for c in Roster.all():
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
	meta_gold = 0
	inventory = []
	equipped = {}
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
		"meta_gold": meta_gold,
		"characters": characters,
		"inventory": inventory,
		"equipped": equipped,
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
	meta_gold = int(data.get("meta_gold", 0))
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
	inventory = []
	for it in data.get("inventory", []):
		inventory.append(str(it))
	equipped = {}
	var saved_eq: Dictionary = data.get("equipped", {})
	for cid in saved_eq.keys():
		var e: Dictionary = saved_eq[cid]
		equipped[cid] = {"weapon": str(e.get("weapon", "")), "relic": str(e.get("relic", ""))}
	_ensure_defaults() # garante personagens novos que não estavam no save
