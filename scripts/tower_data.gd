class_name TowerData
extends Resource

## Dados (data-driven) de uma torre. Define a classe e todos os stats que o
## comportamento da Tower usa. As factories estáticas no fim criam as 4 classes
## do MVP com os números iniciais da seção 9 do design.

enum TowerClass { ARCHER, MAGE, WARRIOR, PRIEST }

@export var tower_class: TowerClass = TowerClass.ARCHER
@export var display_name: String = "Arqueiro"
@export var cost: int = 100
@export var body_color: Color = Color(0.3, 0.5, 0.9)
@export var char_id: String = "" ## id do personagem (vazio = torre genérica); garante unicidade em campo
@export var element: int = -1 ## tipo de dano (Elements.E); -1 = neutro
@export var ability: AbilityData = null ## habilidade ativa de assinatura (null = torre genérica)
@export var equip_icons: Dictionary = {} ## slot(int) -> icon_id; itens vestidos no boneco
@export var attributes: AttributeSet = null ## atributos primários no nível atual (p/ exibir na HUD)

## Ataque (Arqueiro / Mago)
@export var attack_range: float = 190.0
@export var damage: int = 4
@export var fire_rate: float = 1.8 ## tiros por segundo
@export var projectile_color: Color = Color(1, 1, 0.4)
@export var splash_radius: float = 0.0 ## > 0 = dano em área (Mago)

## Stats secundários derivados dos atributos (ver AttributeStats).
@export var crit_chance: float = 0.0
@export var crit_mult: float = 1.5
@export var penetration: int = 0     ## fura a defesa do inimigo
@export var cdr: float = 0.0         ## redução de cooldown de habilidade (0..0.5)
@export var proj_speed: float = 460.0

## Combate corpo-a-corpo (is_melee = true): o próprio personagem tanka na rota.
@export var is_melee: bool = false
@export var max_hp: int = 0          ## vida do personagem melee
@export var defense: int = 0         ## reduz o dano recebido (flat)
@export var dodge: float = 0.0       ## chance de esquivar (0..0.6)
@export var regen: float = 0.0       ## vida regenerada por segundo
@export var lifesteal: float = 0.0   ## fração do dano causado que vira cura (0..0.5)
@export var block_capacity: int = 1  ## quantos inimigos segura ao mesmo tempo
@export var melee_damage: int = 0    ## dano do ataque corpo-a-corpo
@export var melee_attack_rate: float = 1.0
@export var engage_radius: float = 80.0 ## raio em que trava inimigos
@export var revive_time: float = 5.0 ## tempo caído antes de voltar com vida cheia

## Sacerdote (aura de suporte)
@export var aura_radius: float = 0.0
@export var aura_damage_mult: float = 1.0   ## multiplica o dano das torres na aura
@export var aura_fire_rate_mult: float = 1.0 ## multiplica a cadência das torres na aura
@export var aura_slow_mult: float = 1.0      ## multiplica a velocidade dos inimigos na aura (<1 = lentidão)
@export var aura_heal_per_sec: float = 0.0   ## cura por segundo nos bloqueadores na aura


static func archer() -> TowerData:
	var d := TowerData.new()
	d.tower_class = TowerClass.ARCHER
	d.display_name = "Arqueiro"
	d.cost = 100
	d.body_color = Color(0.3, 0.5, 0.9)
	d.attack_range = 200.0
	d.damage = 4
	d.fire_rate = 2.0
	d.projectile_color = Color(1.0, 1.0, 0.45)
	return d


static func mage() -> TowerData:
	var d := TowerData.new()
	d.tower_class = TowerClass.MAGE
	d.display_name = "Mago"
	d.cost = 150
	d.body_color = Color(0.6, 0.3, 0.8)
	d.attack_range = 165.0
	d.damage = 6
	d.fire_rate = 0.9
	d.projectile_color = Color(0.75, 0.45, 1.0)
	d.splash_radius = 72.0
	return d


static func warrior() -> TowerData:
	var d := TowerData.new()
	d.tower_class = TowerClass.WARRIOR
	d.display_name = "Guerreiro"
	d.cost = 120
	d.body_color = Color(0.85, 0.25, 0.25)
	d.is_melee = true
	d.max_hp = 120
	d.defense = 6
	d.melee_damage = 8
	d.melee_attack_rate = 1.2
	d.block_capacity = 3
	d.regen = 4.0
	return d


static func priest() -> TowerData:
	var d := TowerData.new()
	d.tower_class = TowerClass.PRIEST
	d.display_name = "Sacerdote"
	d.cost = 130
	d.body_color = Color(0.95, 0.85, 0.2)
	d.aura_radius = 170.0
	d.aura_damage_mult = 1.3
	d.aura_fire_rate_mult = 1.25
	d.aura_slow_mult = 0.65
	d.aura_heal_per_sec = 6.0
	return d


## As 4 classes em ordem de custo crescente — usada pelo menu de invocação.
static func all_classes() -> Array:
	return [archer(), warrior(), priest(), mage()]

