class_name Anim
extends RefCounted

## Animação de corpo por deformação (sem recortar o sprite em peças): desenha a
## textura em FATIAS horizontais, deslocando cada fatia lateralmente por uma onda.
## Isso curva/balança o personagem (andar, respirar) e permite "inclinar" ao
## atacar (lean). Funciona com qualquer sprite, em lote. Chamado de dentro do
## _draw() da entidade (passa `self` como CanvasItem).

## ci: o nó que desenha (self). dest: retângulo de destino. phase: avança no tempo.
## sway: amplitude do balanço (px). lean: deslocamento extra no topo (px) p/ golpe.
## squash: 0..0.1 leve compressão vertical (respiração). mod: modulação de cor.
static func draw_swayed(ci: CanvasItem, tex: Texture2D, dest: Rect2, phase: float,
		sway: float = 2.0, lean: float = 0.0, squash: float = 0.03,
		mod: Color = Color.WHITE, strips: int = 14) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	# Respiração: comprime/estica a altura de leve, mantendo os pés no lugar.
	var sq := 1.0 + sin(phase * 0.9) * squash
	var h := dest.size.y * sq
	var base_y := dest.position.y + dest.size.y - h # ancora na base
	for i in strips:
		var f0 := float(i) / float(strips)
		var f1 := float(i + 1) / float(strips)
		# Topo pesa mais no balanço (pés ~fixos).
		var weight := 1.0 - (f0 + f1) * 0.5
		var dx := sin(phase + f0 * 1.4) * sway * weight + lean * weight
		var src := Rect2(0.0, f0 * th, tw, th / float(strips))
		var drow := Rect2(dest.position.x + dx, base_y + f0 * h, dest.size.x, h / float(strips) + 1.0)
		ci.draw_texture_rect_region(tex, drow, src, mod)
