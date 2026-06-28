class_name UltimateData
extends Resource

## Poder Supremo (ult) de um personagem. Escolhe-se 1 por partida (do esquadrão).
## O `style` define a animação grande e o efeito aplicado a todos os inimigos em
## tela (ver UltimateEffect). Pensado para ser dramático e raro (carrega ao longo
## da partida).

enum Style { METEOR, LIGHTNING, FLOOD, DIVINE, BLIZZARD, INFERNO, QUAKE, VOID }

@export var id: String = ""
@export var display_name: String = "Poder Supremo"
@export var style: int = Style.METEOR
@export var power: float = 120.0
@export var color: Color = Color(1, 0.8, 0.3)


static func make(p_id: String, p_name: String, p_style: int, p_power: float, p_color: Color) -> UltimateData:
	var u := UltimateData.new()
	u.id = p_id
	u.display_name = p_name
	u.style = p_style
	u.power = p_power
	u.color = p_color
	return u
