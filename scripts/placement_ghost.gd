class_name PlacementGhost
extends Node2D

## Pré-visualização do personagem sendo posicionado: segue o mouse, mostra o
## alcance/área e fica verde (pode) ou vermelho (não pode). z_index alto p/ ficar
## por cima das torres já em campo.

var data: TowerData = null
var valid: bool = true
var _sprite: Texture2D = null

func _ready() -> void:
	z_index = 100
	visible = false

func show_for(d: TowerData) -> void:
	data = d
	_sprite = Art.hero(d.char_id) if d != null else null
	visible = true
	queue_redraw()

func clear() -> void:
	data = null
	visible = false
	queue_redraw()

func _draw() -> void:
	if data == null:
		return
	var ok := Color(0.35, 0.9, 0.45)
	var bad := Color(0.95, 0.35, 0.35)
	var c := ok if valid else bad
	# Raio de atuação: alcance (ranged) ou engajamento (melee).
	var r: float = data.engage_radius if data.is_melee else data.attack_range
	if r > 0.0:
		draw_circle(Vector2.ZERO, r, Color(c.r, c.g, c.b, 0.10))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c.r, c.g, c.b, 0.5), 2.0)
	# Corpo (sprite translúcido, se houver; senão um marcador).
	if _sprite != null:
		var sz := Vector2(48, 48)
		draw_texture_rect(_sprite, Rect2(-sz * 0.5 + Vector2(0, -6), sz), false, Color(1, 1, 1, 0.6))
	else:
		draw_circle(Vector2.ZERO, 16.0, Color(data.body_color.r, data.body_color.g, data.body_color.b, 0.55))
	# Anel de status (verde/vermelho) ao redor do corpo.
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 28, c, 2.5)
