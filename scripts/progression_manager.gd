extends Node
## Autoload: estado meta persistente entre partidas — níveis/XP dos personagens,
## desbloqueios e fase mais alta liberada. Save/load local em user:// (JSON).
##
## Acesse pelo nó /root/Progression (em scripts testáveis headless) ou pelo
## global Progression (no jogo). Ver a pegadinha de autoload no modo -s.

const SAVE_PATH := "user://mithos_save.json"
## Equipe de 6 heróis, todos posicionáveis e móveis em campo (ver pilar de design).
const SQUAD_MAX := 6
const PERM_LEVEL_STEP := 0.04

# Teto de nível por estrela (⭐/⭐⭐/⭐⭐⭐).
const LEVEL_CAP := {1: 10, 2: 20, 3: 30}

signal progress_changed

const GACHA_COST := 100 ## Ambrosia por giro
## Heróis conquistados pela campanha: concluir cada fase libera 1 grego (começa com
## 3 iniciais, ver Roster.STARTERS). Zeus é o capstone na última fase.
const STAGE_UNLOCKS := {1: "atena", 2: "ares", 3: "hermes", 4: "apolo", 5: "zeus"}

var highest_stage_unlocked: int = 1 ## maior fase liberada para jogar
var meta_essence: int = 0           ## recurso secundário (loja)
var meta_gold: int = 0              ## ouro meta (loja), ganho ao concluir fases
var ambrosia: int = 0              ## moeda do gacha, ganha jogando
var characters: Dictionary = {}     ## id -> { unlocked, level, xp, stars }
var fragments: Dictionary = {}      ## id -> quantidade de fragmentos (evoluem estrelas)
var inventory: Array = []           ## ids de equipamentos possuídos (sem repetição)
var equipped: Dictionary = {}       ## char_id -> { slot_index: item_id }
var blessings: Dictionary = {}      ## Bênçãos do Olimpo: id -> nível (gasta Essência)
var stage_stars: Dictionary = {}    ## estrelas por fase: str(index) -> melhor (0..3)
var stage_max_diff: Dictionary = {} ## maior dificuldade VENCIDA por fase: str(index) -> tier (-1 = nenhuma)

# Até 3 equipes salvas. teams[i] = lista de ids; team_ults[i] = id do Poder Supremo.
var teams: Array = [[], [], []]
var team_ults: Array = ["", "", ""]
var team_champions: Array = ["", "", ""] ## id do CAMPEÃO (1 por partida) por equipe
var active_team: int = 0

# Quests / contadores.
var stats: Dictionary = {"wins": 0, "gacha": 0, "evolves": 0}
var daily: Dictionary = {"wins": 0, "gacha": 0}
var quests_claimed: Array = []
var last_daily: String = ""


func _ready() -> void:
	load_game()
	_check_daily_reset()
	ensure_starting_team()


## Jogador novo não pode entrar numa fase com a equipe vazia (ficaria sem campeão
## e só com torres genéricas). Se TODAS as equipes estiverem vazias, monta a
## Equipe 1 com os heróis desbloqueados (até SQUAD_MAX) e define ult/campeão.
func ensure_starting_team() -> void:
	_ensure_defaults()
	for t in teams:
		if not t.is_empty():
			return ## jogador já tem equipe montada — não mexe
	var ids := unlocked_ids()
	if ids.is_empty():
		return
	var t0: Array = []
	for id in ids:
		if t0.size() >= SQUAD_MAX:
			break
		t0.append(id)
	teams[0] = t0
	team_ults[0] = t0[0]
	team_champions[0] = t0[0]
	active_team = 0
	save_game()


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
	# Cada fase concluída desbloqueia um personagem de campanha.
	if STAGE_UNLOCKS.has(index):
		var rid: String = STAGE_UNLOCKS[index]
		if characters.has(rid) and not characters[rid]["unlocked"]:
			characters[rid]["unlocked"] = true
			newly.append(rid)
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
		var slots := {}
		for s in range(EquipmentData.SLOT_NAMES.size()):
			slots[str(s)] = ""
		equipped[char_id] = slots
	else:
		for s in range(EquipmentData.SLOT_NAMES.size()):
			if not equipped[char_id].has(str(s)):
				equipped[char_id][str(s)] = ""


# --- Equipes (até 3) ---
func current_squad() -> Array:
	return teams[active_team].duplicate()


func current_ult() -> String:
	return team_ults[active_team]


func current_champion() -> String:
	var c: String = team_champions[active_team]
	if c == "" and not teams[active_team].is_empty():
		c = teams[active_team][0]
	return c


func set_team_champion(index: int, id: String) -> void:
	if teams[index].has(id):
		team_champions[index] = id
		save_game()


func set_active_team(index: int) -> void:
	active_team = clampi(index, 0, teams.size() - 1)
	save_game()


## Adiciona/remove um herói da equipe (clicar p/ entrar/sair). Respeita SQUAD_MAX.
func toggle_in_team(index: int, id: String) -> void:
	var t: Array = teams[index]
	if t.has(id):
		t.erase(id)
		if team_ults[index] == id:
			team_ults[index] = t[0] if not t.is_empty() else ""
		if team_champions[index] == id:
			team_champions[index] = t[0] if not t.is_empty() else ""
	elif is_unlocked(id) and t.size() < SQUAD_MAX:
		t.append(id)
		if team_ults[index] == "":
			team_ults[index] = id
	teams[index] = t
	save_game()


func set_team_ult(index: int, id: String) -> void:
	if teams[index].has(id):
		team_ults[index] = id
		save_game()


## Compat: define a equipe ativa inteira de uma vez (heróis válidos) + ult.
func set_squad(ids: Array, ult: String) -> void:
	var clean: Array = []
	for id in ids:
		if is_unlocked(id) and not clean.has(id) and clean.size() < SQUAD_MAX:
			clean.append(id)
	teams[active_team] = clean
	team_ults[active_team] = ult if clean.has(ult) else (clean[0] if not clean.is_empty() else "")
	save_game()


func owns_item(item_id: String) -> bool:
	return inventory.has(item_id)


func add_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
	emit_signal("progress_changed")


func _item_owner(item_id: String) -> String:
	for cid in equipped.keys():
		for v in equipped[cid].values():
			if v == item_id:
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
	_ensure_equip(char_id)
	var out: Array = []
	for s in range(EquipmentData.SLOT_NAMES.size()):
		var item_id: String = equipped[char_id].get(str(s), "")
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
	equipped[char_id][str(slot)] = item_id
	emit_signal("progress_changed")
	return true


func unequip(char_id: String, slot: int) -> void:
	_ensure_equip(char_id)
	equipped[char_id][str(slot)] = ""
	emit_signal("progress_changed")


func buy_item(item_id: String) -> bool:
	var item := EquipmentList.by_id(item_id)
	if item == null or owns_item(item_id):
		return false
	if not spend_meta_gold(EquipmentList.price(item.rarity)):
		return false
	add_item(item_id)
	return true


# --- Evolução de estrela (gasta FRAGMENTOS do personagem + ouro) ---
func evolve_cost(char_id: String) -> Dictionary:
	match stars_of(char_id):
		1: return {"frag": 10, "gold": 300}
		2: return {"frag": 25, "gold": 800}
	return {} # já no máximo


func can_evolve(char_id: String) -> bool:
	var cost := evolve_cost(char_id)
	if cost.is_empty():
		return false
	return fragments_of(char_id) >= cost["frag"] and meta_gold >= cost["gold"]


func evolve(char_id: String) -> bool:
	if not can_evolve(char_id):
		return false
	var cost := evolve_cost(char_id)
	fragments[char_id] = fragments_of(char_id) - cost["frag"]
	meta_gold -= cost["gold"]
	characters[char_id]["stars"] += 1
	stats["evolves"] = int(stats.get("evolves", 0)) + 1
	emit_signal("progress_changed")
	return true


# --- Quests ---
func record_win() -> void:
	stats["wins"] = int(stats.get("wins", 0)) + 1
	daily["wins"] = int(daily.get("wins", 0)) + 1
	emit_signal("progress_changed")


func metric_value(metric: String) -> int:
	match metric:
		"stage": return highest_stage_unlocked
		"wins": return int(stats.get("wins", 0))
		"gacha": return int(stats.get("gacha", 0))
		"evolves": return int(stats.get("evolves", 0))
		"daily_wins": return int(daily.get("wins", 0))
		"daily_gacha": return int(daily.get("gacha", 0))
	return 0


func quest_progress(q: Dictionary) -> int:
	return min(metric_value(q["metric"]), q["target"])


func quest_complete(q: Dictionary) -> bool:
	return metric_value(q["metric"]) >= q["target"]


func quest_claimed(q: Dictionary) -> bool:
	return quests_claimed.has(q["id"])


func quest_claimable(q: Dictionary) -> bool:
	return quest_complete(q) and not quest_claimed(q)


func claim_quest(qid: String) -> bool:
	var q := Quests.by_id(qid)
	if q.is_empty() or not quest_claimable(q):
		return false
	add_ambrosia(int(q["ambrosia"]))
	quests_claimed.append(qid)
	emit_signal("progress_changed")
	return true


func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	if today == last_daily:
		return
	last_daily = today
	daily = {"wins": 0, "gacha": 0}
	var keep: Array = []
	for qid in quests_claimed:
		var q := Quests.by_id(qid)
		if not q.is_empty() and not q.get("daily", false):
			keep.append(qid)
	quests_claimed = keep


# --- Moedas e fragmentos ---
func add_ambrosia(amount: int) -> void:
	ambrosia += amount
	emit_signal("progress_changed")

func spend_ambrosia(amount: int) -> bool:
	if ambrosia < amount:
		return false
	ambrosia -= amount
	emit_signal("progress_changed")
	return true

func fragments_of(char_id: String) -> int:
	return int(fragments.get(char_id, 0))

func add_fragments(char_id: String, amount: int) -> void:
	fragments[char_id] = fragments_of(char_id) + amount
	emit_signal("progress_changed")

func unlock_character(char_id: String) -> void:
	_ensure_defaults()
	if characters.has(char_id):
		characters[char_id]["unlocked"] = true
	emit_signal("progress_changed")


# --- Gacha (gasta Ambrosia; novo = desbloqueia, repetido = fragmentos) ---
func gacha_roll() -> Dictionary:
	_ensure_defaults()
	var result := {"ok": false}
	if not spend_ambrosia(GACHA_COST):
		return result
	stats["gacha"] = int(stats.get("gacha", 0)) + 1
	daily["gacha"] = int(daily.get("gacha", 0)) + 1
	var rarity := _roll_rarity()
	var pool: Array = Roster.ids_by_rarity(rarity)
	if pool.is_empty():
		pool = Roster.ids_by_rarity(Roster.Rarity.RARE)
	var id: String = pool[randi() % pool.size()]
	result["ok"] = true
	result["id"] = id
	result["rarity"] = rarity
	if not is_unlocked(id):
		unlock_character(id)
		result["is_new"] = true
		result["fragments"] = 0
	else:
		var f := _frag_amount(rarity)
		add_fragments(id, f)
		result["is_new"] = false
		result["fragments"] = f
	return result

func _roll_rarity() -> int:
	var r := randf()
	if r < 0.03:
		return Roster.Rarity.LEGENDARY
	if r < 0.15:
		return Roster.Rarity.EPIC
	if r < 0.50:
		return Roster.Rarity.RARE
	return Roster.Rarity.COMMON

func _frag_amount(rarity: int) -> int:
	match rarity:
		Roster.Rarity.LEGENDARY: return 20
		Roster.Rarity.EPIC: return 12
		Roster.Rarity.RARE: return 8
	return 5


# --- Loja: comprar personagem direto com Ambrosia ---
func character_price(char_id: String) -> int:
	match Roster.rarity_of(char_id):
		Roster.Rarity.LEGENDARY: return 1500
		Roster.Rarity.EPIC: return 800
		Roster.Rarity.RARE: return 400
	return 200

func buy_character(char_id: String) -> bool:
	if is_unlocked(char_id):
		return false
	if not spend_ambrosia(character_price(char_id)):
		return false
	unlock_character(char_id)
	return true


# --- Bênçãos do Olimpo (melhorias permanentes, gastam Essência) ---
func blessing_level(id: String) -> int:
	return int(blessings.get(id, 0))


## Custo da PRÓXIMA compra (-1 = já no máximo).
func blessing_cost(id: String) -> int:
	var lv := blessing_level(id)
	if lv >= Blessings.MAX_LEVEL:
		return -1
	return Blessings.cost(lv)


func can_buy_blessing(id: String) -> bool:
	var c := blessing_cost(id)
	return c >= 0 and meta_essence >= c


func buy_blessing(id: String) -> bool:
	if not can_buy_blessing(id):
		return false
	meta_essence -= blessing_cost(id)
	blessings[id] = blessing_level(id) + 1
	emit_signal("progress_changed")
	return true


## Valor acumulado da bênção (nível × per do catálogo).
func blessing_value(id: String) -> int:
	var b := Blessings.by_id(id)
	if b.is_empty():
		return 0
	return int(b["per"]) * blessing_level(id)


# Getters de efeito usados pelo orquestrador da partida (game_screen / main).
func bless_base_hp_bonus() -> int:
	return blessing_value("vida_base")

func bless_start_gold_bonus() -> int:
	return blessing_value("ouro_inicial")

func bless_damage_mult() -> float:
	return 1.0 + blessing_value("dano") / 100.0

func bless_wave_bonus_mult() -> float:
	return 1.0 + blessing_value("ouro_onda") / 100.0

func bless_ult_charge_mult() -> float:
	return maxf(0.4, 1.0 - blessing_value("ult") / 100.0)


# --- Estrelas por fase (endgame: 0..3 conforme vidas restantes) ---
const STARS_PER_STAGE := 3


func stars_for_stage(index: int) -> int:
	return int(stage_stars.get(str(index), 0))


func total_stars() -> int:
	var sum := 0
	for v in stage_stars.values():
		sum += int(v)
	return sum


func max_total_stars() -> int:
	return StageList.count() * STARS_PER_STAGE


## Registra as estrelas de uma fase (guarda só o MELHOR resultado já obtido).
## Retorna { best, improved, gained } para a tela de resultado.
func record_stars(index: int, stars: int) -> Dictionary:
	var prev := stars_for_stage(index)
	var best := maxi(prev, clampi(stars, 0, STARS_PER_STAGE))
	var improved := best > prev
	if improved:
		stage_stars[str(index)] = best
		emit_signal("progress_changed")
	return {"best": best, "improved": improved, "gained": maxi(0, best - prev)}


# --- Dificuldades por fase (Normal/Heroico/Lendário) ---
## Maior dificuldade já vencida nesta fase (-1 = nenhuma ainda).
func cleared_diff(index: int) -> int:
	return int(stage_max_diff.get(str(index), -1))


## Uma dificuldade está liberada se for o Normal ou se a anterior já foi vencida.
func diff_unlocked(index: int, diff: int) -> bool:
	if diff <= 0:
		return true
	return cleared_diff(index) >= diff - 1


## Maior dificuldade liberada para escolher nesta fase (0 = só Normal).
func max_diff_unlocked(index: int) -> int:
	var d := 0
	for i in range(1, Difficulty.count()):
		if diff_unlocked(index, i):
			d = i
		else:
			break
	return d


## Registra a vitória numa dificuldade (guarda só a mais alta). Retorna true se
## destravou uma dificuldade nova (subiu o recorde).
func record_stage_diff(index: int, diff: int) -> bool:
	var prev := cleared_diff(index)
	if diff > prev:
		stage_max_diff[str(index)] = diff
		emit_signal("progress_changed")
		return true
	return false


# --- Recompensas de fim de fase ---
func grant_rewards(stage_index: int, victory: bool, diff: int = 0) -> Dictionary:
	_ensure_defaults()
	var mult := Difficulty.reward_mult(diff)
	var r := {"gold": 0, "essence": 0, "ambrosia": 0, "item_id": ""}
	if victory:
		r["gold"] = int(round((30 + stage_index * 15) * mult))
		r["essence"] = int(round((2 + stage_index) * mult))
		r["ambrosia"] = int(round((25 + stage_index * 10) * mult))
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
		r["ambrosia"] = 8
	meta_gold += r["gold"]
	meta_essence += r["essence"]
	ambrosia += r["ambrosia"]
	emit_signal("progress_changed")
	return r


# --- Defaults / persistência ---
func _ensure_defaults() -> void:
	for c in Roster.all():
		if not characters.has(c.id):
			characters[c.id] = {
				"unlocked": Roster.is_starter(c.id),
				"level": 1,
				"xp": 0,
				"stars": 1,
			}


func reset() -> void:
	characters = {}
	highest_stage_unlocked = 1
	meta_essence = 0
	meta_gold = 0
	ambrosia = 0
	fragments = {}
	inventory = []
	equipped = {}
	blessings = {}
	stage_stars = {}
	stage_max_diff = {}
	teams = [[], [], []]
	team_ults = ["", "", ""]
	team_champions = ["", "", ""]
	active_team = 0
	stats = {"wins": 0, "gacha": 0, "evolves": 0}
	daily = {"wins": 0, "gacha": 0}
	quests_claimed = []
	last_daily = Time.get_date_string_from_system()
	_ensure_defaults()
	emit_signal("progress_changed")


func save_game() -> void:
	save_to(SAVE_PATH)


func load_game() -> void:
	load_from(SAVE_PATH)


func save_to(path: String) -> void:
	_ensure_defaults()
	var payload := {
		"version": 2,
		"highest_stage_unlocked": highest_stage_unlocked,
		"meta_essence": meta_essence,
		"meta_gold": meta_gold,
		"ambrosia": ambrosia,
		"characters": characters,
		"fragments": fragments,
		"inventory": inventory,
		"equipped": equipped,
		"blessings": blessings,
		"stage_stars": stage_stars,
		"stage_max_diff": stage_max_diff,
		"teams": teams,
		"team_ults": team_ults,
		"team_champions": team_champions,
		"active_team": active_team,
		"stats": stats,
		"daily": daily,
		"quests_claimed": quests_claimed,
		"last_daily": last_daily,
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
	ambrosia = int(data.get("ambrosia", 0))
	fragments = {}
	var saved_frags: Dictionary = data.get("fragments", {})
	for fid in saved_frags.keys():
		fragments[fid] = int(saved_frags[fid])
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
	blessings = {}
	var saved_bless: Dictionary = data.get("blessings", {})
	for bid in saved_bless.keys():
		blessings[bid] = int(saved_bless[bid])
	stage_stars = {}
	var saved_stars: Dictionary = data.get("stage_stars", {})
	for sid in saved_stars.keys():
		stage_stars[str(sid)] = int(saved_stars[sid])
	stage_max_diff = {}
	var saved_diff: Dictionary = data.get("stage_max_diff", {})
	for sid in saved_diff.keys():
		stage_max_diff[str(sid)] = int(saved_diff[sid])
	equipped = {}
	var saved_eq: Dictionary = data.get("equipped", {})
	for cid in saved_eq.keys():
		var e: Dictionary = saved_eq[cid]
		var slots := {}
		for s in range(EquipmentData.SLOT_NAMES.size()):
			slots[str(s)] = str(e.get(str(s), ""))
		equipped[cid] = slots
	teams = [[], [], []]
	team_ults = ["", "", ""]
	var saved_teams: Array = data.get("teams", [])
	for i in range(min(3, saved_teams.size())):
		var t: Array = []
		for sid in saved_teams[i]:
			t.append(str(sid))
		teams[i] = t
	var saved_ults: Array = data.get("team_ults", [])
	for i in range(min(3, saved_ults.size())):
		team_ults[i] = str(saved_ults[i])
	team_champions = ["", "", ""]
	var saved_champs: Array = data.get("team_champions", [])
	for i in range(min(3, saved_champs.size())):
		team_champions[i] = str(saved_champs[i])
	# Migração de saves antigos (campo squad/squad_ult unico).
	if saved_teams.is_empty() and data.has("squad"):
		for sid in data.get("squad", []):
			teams[0].append(str(sid))
		team_ults[0] = str(data.get("squad_ult", ""))
	active_team = clampi(int(data.get("active_team", 0)), 0, 2)
	var sv_stats: Dictionary = data.get("stats", {})
	stats = {"wins": int(sv_stats.get("wins", 0)), "gacha": int(sv_stats.get("gacha", 0)), "evolves": int(sv_stats.get("evolves", 0))}
	var sv_daily: Dictionary = data.get("daily", {})
	daily = {"wins": int(sv_daily.get("wins", 0)), "gacha": int(sv_daily.get("gacha", 0))}
	quests_claimed = []
	for qid in data.get("quests_claimed", []):
		quests_claimed.append(str(qid))
	last_daily = str(data.get("last_daily", ""))
	_ensure_defaults() # garante personagens novos que não estavam no save
