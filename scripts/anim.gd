class_name Anim
extends RefCounted

## Animação de corpo por código (sem recortar o sprite manualmente): desenha a
## textura em FATIAS horizontais e move cada fatia conforme a AÇÃO, dando a leitura
## de andar, atacar, defender e aguardar — não só "pular". Vira o sprite na direção
## do movimento. Usado por inimigos, campeão e unidades melee.

enum { IDLE, WALK, ATTACK, DEFEND }


## Desenha o sprite com a animação da ação atual.
## face_x < 0 = virado para a esquerda. phase = tempo contínuo (ciclos de andar/
## respirar). atk = 0..1 progresso de um golpe (one-shot).
static func draw_action(ci: CanvasItem, tex: Texture2D, dest: Rect2, face_x: float,
		state: int, phase: float, atk: float = 0.0, mod: Color = Color.WHITE,
		strips: int = 16) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var flip := face_x < 0.0
	var cx := dest.position.x + dest.size.x * 0.5
	var w := dest.size.x

	# Parâmetros por estado.
	var bob := 0.0       # deslocamento vertical do corpo
	var crouch := 1.0    # fator de altura (defender agacha)
	var sway := 0.0      # amplitude do balanço lateral (topo)
	var sway_f := 1.0    # frequência do balanço
	var lunge := 0.0     # avanço (ataque) na direção do rosto
	var legs := 0.0      # passada das pernas (fatias de baixo)
	match state:
		IDLE:
			sway = 1.0; sway_f = 1.2
			bob = sin(phase * 1.2) * 1.0
		WALK:
			sway = 3.0; sway_f = 2.0
			bob = -absf(sin(phase * 2.0)) * 3.0
			legs = 3.0
		ATTACK:
			lunge = sin(clampf(atk, 0.0, 1.0) * PI) * 11.0
			bob = -sin(clampf(atk, 0.0, 1.0) * PI) * 2.0
		DEFEND:
			crouch = 0.85; lunge = -5.0
			bob = sin(phase * 1.5) * 0.6

	var dir := -1.0 if flip else 1.0
	var breathe := 1.0 + sin(phase * 0.9) * (0.03 if state == IDLE else 0.015)
	var h := dest.size.y * crouch * breathe
	var base_y := dest.position.y + dest.size.y - h
	for i in strips:
		var f0 := float(i) / float(strips)
		var f1 := float(i + 1) / float(strips)
		var wtop := 1.0 - (f0 + f1) * 0.5 # 1 no topo, ~0 nos pés
		var dx := sin(phase * sway_f + f0 * 1.2) * sway * wtop
		if state == WALK and f0 > 0.6: # pernas: passada alternada
			dx += sin(phase * 2.0 + (0.0 if f0 < 0.8 else PI)) * legs
		dx += (lunge) * dir + bob * 0.0
		var src := Rect2(0.0, f0 * th, tw, th / float(strips))
		var y := base_y + f0 * h + bob
		var hh := h / float(strips) + 1.0
		var x0 := cx - w * 0.5 + dx
		var drow := Rect2(x0 + w, y, -w, hh) if flip else Rect2(x0, y, w, hh)
		ci.draw_texture_rect_region(tex, drow, src, mod)


## Compat: balanço simples (respiração) — usado por torres-herói paradas.
static func draw_swayed(ci: CanvasItem, tex: Texture2D, dest: Rect2, phase: float,
		sway: float = 2.0, lean: float = 0.0, squash: float = 0.03,
		mod: Color = Color.WHITE, strips: int = 14) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var sq := 1.0 + sin(phase * 0.9) * squash
	var h := dest.size.y * sq
	var base_y := dest.position.y + dest.size.y - h
	for i in strips:
		var f0 := float(i) / float(strips)
		var f1 := float(i + 1) / float(strips)
		var weight := 1.0 - (f0 + f1) * 0.5
		var dx := sin(phase + f0 * 1.4) * sway * weight + lean * weight
		var src := Rect2(0.0, f0 * th, tw, th / float(strips))
		var drow := Rect2(dest.position.x + dx, base_y + f0 * h, dest.size.x, h / float(strips) + 1.0)
		ci.draw_texture_rect_region(tex, drow, src, mod)
