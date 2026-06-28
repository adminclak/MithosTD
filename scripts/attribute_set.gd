class_name AttributeSet
extends Resource

## Atributos primários estilo Ragnarok. Deles derivam todos os stats de combate
## (ver AttributeStats). 'str' é palavra reservada em GDScript, por isso os nomes
## completos.

@export var strength: int = 10     ## STR — dano físico (Arqueiro/Guerreiro)
@export var agility: int = 10      ## AGI — velocidade de ataque e de movimento
@export var vitality: int = 10     ## VIT — vida dos bloqueadores
@export var intelligence: int = 10 ## INT — dano mágico, potência de aura/cura
@export var dexterity: int = 10    ## DEX — alcance, parte da cadência, precisão
@export var luck: int = 10         ## LUK — crítico e ouro extra


static func make(s: int, a: int, v: int, i: int, d: int, l: int) -> AttributeSet:
	var x := AttributeSet.new()
	x.strength = s
	x.agility = a
	x.vitality = v
	x.intelligence = i
	x.dexterity = d
	x.luck = l
	return x


## base + growth * times (atributos no nível = base + crescimento por nível).
func plus_scaled(growth: AttributeSet, times: int) -> AttributeSet:
	return AttributeSet.make(
		strength + growth.strength * times,
		agility + growth.agility * times,
		vitality + growth.vitality * times,
		intelligence + growth.intelligence * times,
		dexterity + growth.dexterity * times,
		luck + growth.luck * times)


func total() -> int:
	return strength + agility + vitality + intelligence + dexterity + luck
