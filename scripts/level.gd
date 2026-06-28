class_name Level
extends Node2D

const WAYPOINTS: Array = [
	Vector2(-40, 160),
	Vector2(360, 160),
	Vector2(360, 420),
	Vector2(760, 420),
	Vector2(760, 180),
	Vector2(1040, 180),
	Vector2(1040, 560),
	Vector2(1240, 560),
]

const TOWER_SLOTS: Array = [
	Vector2(200, 300),
	Vector2(560, 300),
	Vector2(560, 560),
	Vector2(900, 320),
	Vector2(900, 440),
]

func _ready() -> void:
	var path := Line2D.new()
	path.points = PackedVector2Array(WAYPOINTS)
	path.width = 44
	path.default_color = Color(0.78, 0.70, 0.52)
	add_child(path)
	queue_redraw()

func get_waypoints() -> Array:
	return WAYPOINTS.duplicate()

func get_tower_slots() -> Array:
	return TOWER_SLOTS.duplicate()

func _draw() -> void:
	var base_pos: Vector2 = WAYPOINTS[-1]
	draw_rect(Rect2(base_pos - Vector2(28, 28), Vector2(56, 56)), Color(0.2, 0.7, 0.3))
	draw_circle(base_pos, 12, Color(1, 1, 1))

	for slot in TOWER_SLOTS:
		draw_arc(slot, 22, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
