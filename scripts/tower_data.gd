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

## Ataque (Arqueiro / Mago)
@export var attack_range: float = 190.0
@export var damage: int = 4
@export var fire_rate: float = 1.8 ## tiros por segundo
@export var projectile_color: Color = Color(1, 1, 0.4)
@export var splash_radius: float = 0.0 ## > 0 = dano em área (Mago)

## Guerreiro (unidades bloqueadoras)
@export var blocker_count: int = 0
@export var blocker_hp: int = 0
@export var blocker_damage: int = 0
@export var blocker_attack_rate: float = 1.0
@export var blocker_respawn_time: float = 4.0
@export var blocker_engage_radius: float = 50.0

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
	d.blocker_count = 2
	d.blocker_hp = 40
	d.blocker_damage = 5
	d.blocker_attack_rate = 1.2
	d.blocker_respawn_time = 4.0
	d.blocker_engage_radius = 50.0
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
