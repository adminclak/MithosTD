class_name ClassBadge
extends Control

## Emblema visual da classe do herói (Arqueiro/Mago/Guerreiro/Sacerdote): círculo
## na cor da classe + símbolo branco desenhado em código. Usado como nó nas telas
## (HBox/cards) e no campo via ClassBadge.paint() em qualquer CanvasItem.

var klass: int = 0


func _init(k: int = 0, sz: float = 26.0) -> void:
	klass = k
	custom_minimum_size = Vector2(sz, sz)


func _draw() -> void:
	paint(self, klass, size * 0.5, minf(size.x, size.y))


static func color_of(k: int) -> Color:
	match k:
		TowerData.TowerClass.ARCHER: return Color(0.32, 0.58, 0.97)
		TowerData.TowerClass.MAGE: return Color(0.66, 0.36, 0.90)
		TowerData.TowerClass.WARRIOR: return Color(0.90, 0.30, 0.30)
		TowerData.TowerClass.PRIEST: return Color(0.97, 0.84, 0.28)
	return Color.WHITE


static func name_of(k: int) -> String:
	match k:
		TowerData.TowerClass.ARCHER: return "Arqueiro"
		TowerData.TowerClass.MAGE: return "Mago"
		TowerData.TowerClass.WARRIOR: return "Guerreiro"
		TowerData.TowerClass.PRIEST: return "Sacerdote"
	return "?"


## Desenha o emblema (disco da cor da classe + símbolo) centrado em `c`, diâmetro ~`d`.
static func paint(ci: CanvasItem, k: int, c: Vector2, d: float) -> void:
	var r := d * 0.5
	ci.draw_circle(c, r, Color(0.08, 0.06, 0.04, 0.92))
	ci.draw_circle(c, r - maxf(1.0, r * 0.12), color_of(k))
	var w := Color(1, 1, 1, 0.97)
	match k:
		TowerData.TowerClass.WARRIOR: _sword(ci, c, r, w)
		TowerData.TowerClass.ARCHER: _bow(ci, c, r, w)
		TowerData.TowerClass.MAGE: _spark(ci, c, r, w)
		TowerData.TowerClass.PRIEST: _cross(ci, c, r, w)


static func _sword(ci: CanvasItem, c: Vector2, r: float, w: Color) -> void:
	var th := maxf(1.6, r * 0.18)
	ci.draw_line(c + Vector2(0, -r * 0.62), c + Vector2(0, r * 0.30), w, th)        # lâmina
	ci.draw_line(c + Vector2(-r * 0.42, r * 0.18), c + Vector2(r * 0.42, r * 0.18), w, th) # guarda
	ci.draw_line(c + Vector2(0, r * 0.30), c + Vector2(0, r * 0.55), w, th)         # cabo


static func _cross(ci: CanvasItem, c: Vector2, r: float, w: Color) -> void:
	var th := maxf(1.8, r * 0.22)
	ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.55), w, th)
	ci.draw_line(c + Vector2(-r * 0.42, -r * 0.06), c + Vector2(r * 0.42, -r * 0.06), w, th)


static func _spark(ci: CanvasItem, c: Vector2, r: float, w: Color) -> void:
	var th := maxf(1.4, r * 0.16)
	ci.draw_line(c + Vector2(0, -r * 0.62), c + Vector2(0, r * 0.62), w, th)
	ci.draw_line(c + Vector2(-r * 0.62, 0), c + Vector2(r * 0.62, 0), w, th)
	ci.draw_line(c + Vector2(-r * 0.42, -r * 0.42), c + Vector2(r * 0.42, r * 0.42), w, th * 0.7)
	ci.draw_line(c + Vector2(-r * 0.42, r * 0.42), c + Vector2(r * 0.42, -r * 0.42), w, th * 0.7)


static func _bow(ci: CanvasItem, c: Vector2, r: float, w: Color) -> void:
	var th := maxf(1.5, r * 0.16)
	# Arco (curva à esquerda) + flecha horizontal com ponta.
	ci.draw_arc(c + Vector2(r * 0.35, 0), r * 0.72, deg_to_rad(118), deg_to_rad(242), 14, w, th)
	ci.draw_line(c + Vector2(-r * 0.5, 0), c + Vector2(r * 0.6, 0), w, th)
	ci.draw_line(c + Vector2(r * 0.6, 0), c + Vector2(r * 0.28, -r * 0.22), w, th)
	ci.draw_line(c + Vector2(r * 0.6, 0), c + Vector2(r * 0.28, r * 0.22), w, th)
