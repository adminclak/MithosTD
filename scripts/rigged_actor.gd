class_name RiggedActor
extends Node2D

## Rig 2D "com ossos" (cutout): recorta o sprite do herói em partes (cabeça, tronco,
## 2 braços, 2 pernas) usando regiões da textura e ROTACIONA cada parte na sua junta
## conforme a ação — andar (pernas/braços alternam), atacar (braço da arma golpeia),
## defender (braços sobem), aguardar (respira). Desenha virado para a DIREITA; quem
## usa vira pelo scale.x do nó. Funciona com qualquer herói (sprites padronizados).

var tex: Texture2D = null
var height: float = 80.0
var state: int = Anim.IDLE
var atk: float = 0.0
var phase: float = 0.0
var modulate_c: Color = Color.WHITE

# Partes: região (frações rx,ry,rw,rh da textura) + junta (frações px,py). Ordem de
# desenho: trás (esq.) -> tronco -> cabeça -> frente (dir.).
const PARTS := [
	{"limb": "legB", "region": [0.37, 0.57, 0.15, 0.43], "pivot": [0.45, 0.58]},
	{"limb": "armB", "region": [0.27, 0.30, 0.16, 0.33], "pivot": [0.40, 0.32]},
	{"limb": "torso", "region": [0.34, 0.26, 0.32, 0.34], "pivot": [0.50, 0.58]},
	{"limb": "head", "region": [0.32, 0.02, 0.36, 0.27], "pivot": [0.50, 0.28]},
	{"limb": "legF", "region": [0.49, 0.57, 0.15, 0.43], "pivot": [0.55, 0.58]},
	{"limb": "armF", "region": [0.57, 0.30, 0.16, 0.33], "pivot": [0.60, 0.32]},
]


func setup(t: Texture2D, h: float = 80.0) -> void:
	tex = t
	height = h
	set_process(true)
	queue_redraw()


func set_pose(s: int, a: float) -> void:
	state = s
	atk = a


func _process(delta: float) -> void:
	var spd := 11.0 if state == Anim.WALK else (6.0 if state == Anim.ATTACK else 3.0)
	phase += delta * spd
	queue_redraw()


func _angle(limb: String) -> float:
	match state:
		Anim.WALK:
			var sw := sin(phase) * 0.55
			match limb:
				"legB": return sw
				"legF": return -sw
				"armB": return -sw * 0.8
				"armF": return sw * 0.8
		Anim.ATTACK:
			# atk vai de 1 (impacto) -> 0; faz recuar e golpear com o braço da frente.
			var e := 1.0 - clampf(atk, 0.0, 1.0)
			match limb:
				"armF": return lerp(-1.5, 0.9, e)
				"armB": return 0.3
				"torso": return lerp(-0.2, 0.15, e)
		Anim.DEFEND:
			match limb:
				"armF": return -1.1
				"armB": return -0.5
				"head": return 0.15
		_: # IDLE
			var b := sin(phase) * 0.09
			match limb:
				"armF": return -b
				"armB": return b
	return 0.0


func _draw() -> void:
	if tex == null:
		return
	var ts := tex.get_size()
	if ts.y <= 0.0:
		return
	var s := height / ts.y
	# Respiração/agacho global e bob de caminhada (deslocam a base das partes).
	var bob := 0.0
	var crouch := 1.0
	match state:
		Anim.WALK: bob = -absf(sin(phase)) * 2.0
		Anim.DEFEND: crouch = 0.86
		Anim.IDLE: bob = sin(phase * 0.9) * 0.8
	for part in PARTS:
		var r: Array = part["region"]
		var pv: Array = part["pivot"]
		var src := Rect2(r[0] * ts.x, r[1] * ts.y, r[2] * ts.x, r[3] * ts.y)
		# Junta em coords locais (pés na origem, para cima = -y).
		var piv := Vector2((pv[0] - 0.5) * ts.x * s, (pv[1] - 1.0) * ts.y * s * crouch + bob)
		# Canto sup-esq da região relativo à junta (já escalado).
		var rel := Vector2((r[0] - pv[0]) * ts.x * s, (r[1] - pv[1]) * ts.y * s * crouch)
		var size := Vector2(r[2] * ts.x * s, r[3] * ts.y * s * crouch)
		draw_set_transform(piv, _angle(part["limb"]), Vector2.ONE)
		draw_texture_rect_region(tex, Rect2(rel, size), src, modulate_c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
