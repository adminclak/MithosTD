class_name TowerSlot
extends Node2D

## Slot onde uma torre pode ser invocada. Apenas estado + marcador visual;
## o clique é capturado pelo BuildManager (por proximidade do mouse).

var tower: Tower = null
var highlighted: bool = false


func is_empty() -> bool:
	return tower == null or not is_instance_valid(tower)


func set_highlighted(on: bool) -> void:
	highlighted = on
	queue_redraw()


func _draw() -> void:
	var col := Color(1, 1, 1, 0.35)
	if highlighted:
		col = Color(1.0, 0.95, 0.5, 0.85)
	# Marcador do slot (anel). Cheio/aberto conforme ocupado.
	if is_empty():
		draw_arc(Vector2.ZERO, 22, 0.0, TAU, 32, col, 2.0)
	else:
		draw_arc(Vector2.ZERO, 24, 0.0, TAU, 32, col, 1.0)
