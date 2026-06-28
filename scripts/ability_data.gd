class_name AbilityData
extends Resource

## Habilidade ativa de assinatura de um personagem. Acionada pelo jogador por um
## botão no HUD, com cooldown e sem custo de mana (simplicidade mobile).
## O efeito é parametrizado por `kind` — alguns personagens compartilham o mesmo
## tipo com números diferentes; o ajuste fino fica na Camada 6.

enum Kind {
	DAMAGE_AOE,      ## dano instantâneo em área ao redor da torre
	STUN_AOE,        ## paralisa/petrifica/congela (e fere leve) inimigos em área
	BUFF_TOWER,      ## buff temporário de dano/cadência nas torres da área
	HEAL_BLOCKERS,   ## cura aliados melee em área e fere inimigos
	SHIELD_BLOCKERS, ## deixa os aliados melee da área invulneráveis por um tempo
	CHAIN,           ## raio em cadeia: salta entre vários inimigos
	LINE,            ## tiro perfurante: dano alto que ignora defesa em área
	SLOW_AOE,        ## lentidão temporária nos inimigos em área
	KNOCKBACK,       ## empurra os inimigos para trás (e fere leve)
	DOT_AOE,         ## veneno/queimadura/sangramento: dano ao longo do tempo
	SUMMON,          ## invoca um aliado melee temporário
}

@export var id: String = ""
@export var display_name: String = ""
@export var kind: Kind = Kind.DAMAGE_AOE
@export var cooldown: float = 30.0
@export var radius: float = 150.0
@export var power: float = 0.0    ## dano, cura ou multiplicador conforme o kind
@export var duration: float = 0.0 ## duração de stun/buff/escudo (s)


static func make(p_id: String, p_name: String, p_kind: Kind, cd: float, \
		p_radius: float, p_power: float, p_duration: float) -> AbilityData:
	var a := AbilityData.new()
	a.id = p_id
	a.display_name = p_name
	a.kind = p_kind
	a.cooldown = cd
	a.radius = p_radius
	a.power = p_power
	a.duration = p_duration
	return a
