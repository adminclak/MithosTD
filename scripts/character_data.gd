class_name CharacterData
extends Resource

## Um personagem do roster. Identidade (id, nome, mitologia, classe) + atributos
## (base no nível 1 e crescimento por nível) + habilidade. Os stats de combate
## são derivados dos atributos via AttributeStats no nível em que entra em campo.

@export var id: String = ""
@export var display_name: String = ""
@export var mythology: String = ""
@export var tower_class: TowerData.TowerClass = TowerData.TowerClass.ARCHER
@export var is_melee: bool = false
@export var base_attr: AttributeSet = null
@export var growth_attr: AttributeSet = null
@export var ability: AbilityData = null
@export var unlock_stage: int = 0 ## 0 = já desbloqueado


static func from_archetype(p_id: String, p_name: String, p_myth: String, \
		archetype: int, unlock: int = 0) -> CharacterData:
	var c := CharacterData.new()
	c.id = p_id
	c.display_name = p_name
	c.mythology = p_myth
	c.tower_class = Archetypes.tower_class_of(archetype)
	c.is_melee = Archetypes.is_melee(archetype)
	c.base_attr = Archetypes.base_attr(archetype)
	c.growth_attr = Archetypes.growth_attr(archetype)
	c.ability = Archetypes.ability(archetype)
	c.unlock_stage = unlock
	return c


func attributes_at(level: int) -> AttributeSet:
	return base_attr.plus_scaled(growth_attr, max(0, level - 1))


func tower_data_for_level(level: int, stars: int = 1) -> TowerData:
	var d := AttributeStats.build(tower_class, attributes_at(level), is_melee, stars)
	d.char_id = id
	d.display_name = display_name
	d.ability = ability
	return d


func base_data() -> TowerData:
	return tower_data_for_level(1)
