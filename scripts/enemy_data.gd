class_name EnemyData
extends Resource

## Dados (data-driven) de um inimigo. O Enemy aplica via apply_data(). Comportamentos
## especiais (ex.: Hidra que se divide ao morrer) ficam no campo `special`.

enum Special { NONE, SPLIT }

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 12
@export var speed: float = 140.0
@export var gold_reward: int = 5
@export var base_damage: int = 1   ## dano à base ao escapar
@export var attack_damage: int = 3 ## dano corpo-a-corpo nos personagens melee
@export var attack_rate: float = 1.0
@export var defense: int = 0 ## reduz o dano recebido (furado por penetracao)
@export var radius: float = 14.0
@export var color: Color = Color(0.85, 0.3, 0.3)
@export var element: int = -1 ## tipo do inimigo (Elements.E); -1 = neutro

@export var special: Special = Special.NONE
@export var split_into: String = "" ## id do inimigo gerado ao dividir
@export var split_count: int = 2


static func make(p_id: String, p_name: String, hp: int, spd: float, gold: int, \
		base_dmg: int, atk: int, p_radius: float, p_color: Color) -> EnemyData:
	var e := EnemyData.new()
	e.id = p_id
	e.display_name = p_name
	e.max_hp = hp
	e.speed = spd
	e.gold_reward = gold
	e.base_damage = base_dmg
	e.attack_damage = atk
	e.radius = p_radius
	e.color = p_color
	return e
