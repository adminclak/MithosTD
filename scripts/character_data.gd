class_name CharacterData
extends Resource

## Um personagem do roster (deus/ser). Carrega a identidade (id, nome, classe)
## e um TowerData base já configurado. O nível permanente escala os stats base
## na hora de entrar em campo via tower_data_for_level().
##
## As variações por personagem aqui são provisórias (dão identidade); o ajuste
## fino mecânico (sniper, metralhadora, raio em cadeia, petrificação) entra na
## Camada 6 junto com habilidades.

const PERM_LEVEL_STEP := 0.04 ## +4% nos stats principais por nível permanente

@export var id: String = ""
@export var display_name: String = ""
@export var tower_class: TowerData.TowerClass = TowerData.TowerClass.ARCHER
@export var unlock_stage: int = 0 ## fase cuja conclusão desbloqueia (0 = inicial)

var _base: TowerData = null


static func make(p_id: String, p_name: String, base: TowerData, unlock: int) -> CharacterData:
	var c := CharacterData.new()
	c.id = p_id
	c.display_name = p_name
	c.tower_class = base.tower_class
	c._base = base
	c.unlock_stage = unlock
	base.display_name = p_name
	return c


func base_data() -> TowerData:
	return _base


## Cópia do TowerData base com os stats principais escalados pelo nível permanente.
func tower_data_for_level(perm_level: int) -> TowerData:
	var mult := 1.0 + (perm_level - 1) * PERM_LEVEL_STEP
	var d: TowerData = _base.duplicate(true)
	d.char_id = id
	d.display_name = display_name
	d.damage = int(round(_base.damage * mult))
	d.blocker_hp = int(round(_base.blocker_hp * mult))
	d.blocker_damage = int(round(_base.blocker_damage * mult))
	d.aura_heal_per_sec = _base.aura_heal_per_sec * mult
	# Sacerdote: o buff fica um pouco mais forte com o nível permanente.
	if _base.aura_damage_mult > 1.0:
		d.aura_damage_mult = 1.0 + (_base.aura_damage_mult - 1.0) * mult
		d.aura_fire_rate_mult = 1.0 + (_base.aura_fire_rate_mult - 1.0) * mult
	return d
