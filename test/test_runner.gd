extends SceneTree
## Test runner próprio (sem dependências externas).
## Roda com:  godot --headless --path . -s res://test/test_runner.gd
## Sai com código 0 se tudo passar, 1 se algo falhar (bom pra CI).

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("=== Testes Mithos TD ===")
	_test_game_state()
	print("\n=== RESULTADO: %d passou, %d falhou ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", msg)
	else:
		_failed += 1
		print("  [FAIL] ", msg)

func _test_game_state() -> void:
	print("\nGameState (vida / ouro / fim de jogo):")
	var GS = load("res://scripts/game_state.gd")

	# Estado inicial
	var gs = GS.new()
	gs.reset_run(20, 150)
	_check(gs.base_hp == 20, "reset_run define base_hp = 20")
	_check(gs.gold == 150, "reset_run define gold = 150")
	_check(gs.is_over() == false, "run comeca sem game over")

	# Economia
	gs.add_gold(50)
	_check(gs.gold == 200, "add_gold soma corretamente")
	_check(gs.try_spend(100) == true, "try_spend com saldo retorna true")
	_check(gs.gold == 100, "try_spend desconta o ouro")
	_check(gs.try_spend(9999) == false, "try_spend sem saldo retorna false")
	_check(gs.gold == 100, "try_spend sem saldo nao mexe no ouro")

	# Derrota ao zerar a vida
	var loss := {"called": false, "victory": null}
	gs.game_over.connect(func(v): loss["called"] = true; loss["victory"] = v)
	gs.take_base_damage(5)
	_check(gs.base_hp == 15, "take_base_damage reduz a vida")
	gs.take_base_damage(999)
	_check(gs.base_hp == 0, "vida nao fica negativa (clamp em 0)")
	_check(loss["called"] == true, "game_over emitido ao zerar a vida")
	_check(loss["victory"] == false, "derrota => victory = false")
	gs.free()

	# Vitória
	var gs2 = GS.new()
	gs2.reset_run(20, 0)
	var win := {"victory": null}
	gs2.game_over.connect(func(v): win["victory"] = v)
	gs2.win()
	_check(win["victory"] == true, "win() => game_over com victory = true")
	gs2.free()
