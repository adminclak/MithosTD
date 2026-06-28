extends Node
## Autoload (singleton) com o estado global de uma partida (run).
## Camada 1: vida da base, ouro e progresso de ondas.

signal base_hp_changed(hp: int)
signal gold_changed(gold: int)
signal wave_changed(current: int, total: int)
signal game_over(victory: bool)

var base_hp: int = 20
var gold: int = 0
var _is_over: bool = false

func reset_run(start_hp: int, start_gold: int) -> void:
	base_hp = start_hp
	gold = start_gold
	_is_over = false
	base_hp_changed.emit(base_hp)
	gold_changed.emit(gold)

func take_base_damage(dmg: int) -> void:
	if _is_over:
		return
	base_hp = max(0, base_hp - dmg)
	base_hp_changed.emit(base_hp)
	if base_hp <= 0:
		_end_game(false)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func try_spend(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func set_wave(current: int, total: int) -> void:
	wave_changed.emit(current, total)

func win() -> void:
	_end_game(true)

func is_over() -> bool:
	return _is_over

func _end_game(victory: bool) -> void:
	if _is_over:
		return
	_is_over = true
	game_over.emit(victory)
