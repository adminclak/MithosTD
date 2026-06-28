class_name UltimateEffect
extends Node2D

## Animação grande (tela cheia) do Poder Supremo + aplicação do efeito a todos os
## inimigos em tela no momento do impacto. Autodestrói ao terminar. Puro código.

const ARENA := Rect2(0, 0, 1280, 720)
const CENTER := Vector2(640, 360)

var _ult: UltimateData
var _t: float = 0.0
var _dur: float = 1.8
var _impact_at: float = 0.55
var _applied: bool = false
var _center: Vector2 = CENTER


func play(ult: UltimateData, center: Vector2 = CENTER) -> void:
	_ult = ult
	_center = center
	z_index = 200
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not _applied and _t >= _impact_at:
		_applied = true
		_apply()
	queue_redraw()
	if _t >= _dur:
		queue_free()


# --- Efeito de jogo ---
func _apply() -> void:
	if _ult == null:
		return
	var p: int = int(round(_ult.power))
	var enemies := get_tree().get_nodes_in_group("enemies")
	match _ult.style:
		UltimateData.Style.METEOR:
			for e in enemies:
				_hurt(e, p, 9999)
		UltimateData.Style.LIGHTNING:
			for e in enemies:
				_hurt(e, p, 9999)
				if e.has_method("apply_stun"): e.apply_stun(1.2)
		UltimateData.Style.FLOOD:
			for e in enemies:
				_hurt(e, int(p * 0.8), 0)
				if e.has_method("knockback"): e.knockback(90.0)
				if e.has_method("apply_slow"): e.apply_slow(0.5, 4.0)
		UltimateData.Style.DIVINE:
			for t in get_tree().get_nodes_in_group("towers"):
				if t.has_method("heal"): t.heal(999999)
				if t.has_method("apply_temp_buff"): t.apply_temp_buff(1.6, 8.0)
				if t.has_method("apply_shield"): t.apply_shield(5.0)
			for e in enemies:
				_hurt(e, int(p * 0.5), 0)
		UltimateData.Style.BLIZZARD:
			for e in enemies:
				_hurt(e, int(p * 0.7), 9999)
				if e.has_method("apply_stun"): e.apply_stun(1.6)
				if e.has_method("apply_slow"): e.apply_slow(0.4, 5.0)
		UltimateData.Style.INFERNO:
			for e in enemies:
				_hurt(e, int(p * 0.5), 0)
				if e.has_method("apply_dot"): e.apply_dot(p * 0.35, 4.0)
		UltimateData.Style.QUAKE:
			for e in enemies:
				_hurt(e, p, 9999)
				if e.has_method("apply_stun"): e.apply_stun(1.0)
				if e.has_method("knockback"): e.knockback(70.0)
		UltimateData.Style.VOID:
			for e in enemies:
				_hurt(e, int(p * 1.2), 9999)
				if e.has_method("apply_slow"): e.apply_slow(0.35, 5.0)


func _hurt(e: Node, amount: int, pen: int) -> void:
	if is_instance_valid(e) and e.has_method("take_damage"):
		e.take_damage(amount, pen)


# --- Animação ---
func _draw() -> void:
	if _ult == null:
		return
	var t: float = clampf(_t / _dur, 0.0, 1.0)
	var env: float = sin(PI * t) # 0 -> 1 -> 0
	var col: Color = _ult.color
	match _ult.style:
		UltimateData.Style.METEOR:
			_draw_meteor(t, col)
		UltimateData.Style.LIGHTNING:
			_draw_lightning(t, env, col)
		UltimateData.Style.FLOOD:
			_draw_flood(t, col)
		UltimateData.Style.DIVINE:
			_draw_divine(t, env, col)
		UltimateData.Style.BLIZZARD:
			_draw_blizzard(t, env, col)
		UltimateData.Style.INFERNO:
			_draw_inferno(t, env, col)
		UltimateData.Style.QUAKE:
			_draw_quake(t, env, col)
		UltimateData.Style.VOID:
			_draw_void(t, env, col)


func _hash(i: int) -> float:
	return fmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)


func _draw_meteor(t: float, col: Color) -> void:
	for i in 8:
		var x: float = _center.x + (_hash(i) - 0.5) * 460.0
		var ty: float = _center.y + (_hash(i + 50) - 0.5) * 220.0
		var prog: float = clampf(t * 1.6 - _hash(i) * 0.3, 0.0, 1.0)
		var y: float = lerp(-60.0, ty, prog)
		if prog < 1.0:
			draw_line(Vector2(x - 30, y - 60), Vector2(x, y), Color(col.r, col.g, col.b, 0.7), 4.0)
			draw_circle(Vector2(x, y), 9.0, Color(1.0, 0.8, 0.4))
		else:
			var er: float = (t - 0.6) * 120.0
			draw_circle(Vector2(x, ty), er, Color(col.r, col.g, col.b, max(0.0, 0.5 - t * 0.4)))
			draw_arc(Vector2(x, ty), er, 0.0, TAU, 20, Color(1, 0.9, 0.6, max(0.0, 0.8 - t)), 3.0)


func _draw_lightning(t: float, env: float, col: Color) -> void:
	draw_rect(ARENA, Color(1, 1, 1, env * 0.4)) # flash
	if sin(_t * 50.0) > 0.0:
		for i in 6:
			var x: float = 100.0 + _hash(i) * 1080.0
			var pts := PackedVector2Array([Vector2(x, 0)])
			var y: float = 0.0
			while y < 540.0:
				y += 60.0
				x += (_hash(int(y) + i) - 0.5) * 70.0
				pts.append(Vector2(x, y))
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.95), 3.0)


func _draw_flood(t: float, col: Color) -> void:
	var front: float = lerp(-120.0, 1400.0, t)
	var band := PackedVector2Array()
	for i in 21:
		var y: float = float(i) / 20.0 * 720.0
		var wob: float = sin(y * 0.05 + _t * 6.0) * 30.0
		band.append(Vector2(front + wob, y))
	for i in range(20, -1, -1):
		var y: float = float(i) / 20.0 * 720.0
		band.append(Vector2(front - 260.0 + sin(y * 0.04 + _t * 5.0) * 20.0, y))
	draw_colored_polygon(band, Color(col.r, col.g, col.b, 0.45))
	draw_polyline(band, Color(0.85, 0.95, 1.0, 0.7), 3.0)


func _draw_divine(t: float, env: float, col: Color) -> void:
	draw_rect(ARENA, Color(col.r, col.g, col.b, env * 0.28))
	for i in 16:
		var ang: float = TAU * float(i) / 16.0
		var dir := Vector2(cos(ang), sin(ang))
		var r: float = 60.0 + t * 700.0
		draw_line(_center + dir * 40.0, _center + dir * r, Color(1.0, 0.95, 0.6, env * 0.5), 6.0)
	draw_circle(_center,30.0 + env * 60.0, Color(1, 1, 0.85, env * 0.6))
	for i in 18: # faíscas subindo
		var x: float = _hash(i) * 1280.0
		var y: float = 720.0 - fmod(_t * 240.0 + _hash(i + 9) * 720.0, 720.0)
		draw_circle(Vector2(x, y), 3.0, Color(1, 0.95, 0.7, env))


func _draw_blizzard(t: float, env: float, col: Color) -> void:
	draw_rect(ARENA, Color(col.r, col.g, col.b, env * 0.30))
	for i in 80:
		var x: float = fmod(_hash(i) * 1280.0 + _t * 60.0 * (0.5 + _hash(i + 3)), 1280.0)
		var y: float = fmod(_hash(i + 7) * 720.0 + _t * 260.0 * (0.6 + _hash(i)), 720.0)
		draw_circle(Vector2(x, y), 2.0 + _hash(i + 1) * 2.0, Color(1, 1, 1, env * 0.9))


func _draw_inferno(t: float, env: float, col: Color) -> void:
	draw_rect(ARENA, Color(col.r, col.g * 0.5, 0.0, env * 0.22))
	for i in 40:
		var x: float = _hash(i) * 1280.0
		var base_y: float = 200.0 + _hash(i + 5) * 460.0
		var h: float = (40.0 + _hash(i + 2) * 60.0) * env
		var sway: float = sin(_t * 8.0 + i) * 8.0
		var flame := PackedVector2Array([
			Vector2(x - 10, base_y), Vector2(x + sway, base_y - h), Vector2(x + 10, base_y)])
		draw_colored_polygon(flame, Color(1.0, 0.5 + _hash(i) * 0.3, 0.1, env * 0.8))


func _draw_quake(t: float, env: float, col: Color) -> void:
	draw_rect(ARENA, Color(0.4, 0.25, 0.1, env * 0.15))
	for k in 3:
		var r: float = (t * 900.0) - k * 120.0
		if r > 0.0:
			draw_arc(_center,r, 0.0, TAU, 48, Color(col.r, col.g, col.b, max(0.0, env - k * 0.2)), 6.0)


func _draw_void(t: float, env: float, col: Color) -> void:
	draw_rect(ARENA, Color(0.1, 0.0, 0.15, env * 0.4))
	for k in 4:
		var r: float = lerp(700.0, 20.0, t) + k * 60.0 # anéis colapsando
		draw_arc(_center,r, 0.0, TAU, 40, Color(col.r, col.g, col.b, env * 0.8), 5.0)
	draw_circle(_center,env * 50.0, Color(0.7, 0.3, 0.9, env * 0.6))
