class_name Balance
extends RefCounted

## Ponto ÚNICO dos números de economia/ritmo de uma partida, SEM dependências de
## cena/autoload (compila no modo `-s` dos testes). Quem orquestra a partida
## (game_screen, wave_manager) e os testes leem daqui — mexer aqui rebalanceia a
## economia toda. Os pesos de COMBATE ficam em AttributeStats/GreekBestiary/StageList.

const START_HP := 20      ## vida da base no início (estilo KR: ~20 corações)
const START_GOLD := 320   ## ouro inicial — compra ~3 torres baratas
const WAVE_BONUS := 25     ## ouro por concluir uma onda
const EARLY_BONUS := 15    ## ouro extra por antecipar a próxima onda
