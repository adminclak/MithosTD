extends Node2D
## HeroView3D — mostra um herói 3D (HeroRig3D) como "sprite vivo" dentro da batalha
## 2D, via SubViewport com mundo 3D próprio + câmera fixa 3/4. Substitui o sprite 2D
## do Tower quando existe o modelo 3D do herói. O resto da batalha (mapa/inimigos/UI/
## lógica) continua 2D e intacto.
##
## Uso:
##   var v = preload("res://scripts/hero_view_3d.gd").new()
##   if v.setup("hercules"): add_child(v)   # senão, cai no desenho 2D do Tower

const HeroRig = preload("res://scripts/hero_rig_3d.gd")

var rig: Node3D = null
var _svp: SubViewport = null
var _spr: Sprite2D = null


## disp_h = altura de exibição do herói na tela da batalha (px).
func setup(char_id: String, disp_h: int = 100) -> bool:
	var glb := "res://assets/models/%s/%s.glb" % [char_id, char_id]
	if not FileAccess.file_exists(glb):
		return false
	# SubViewport com mundo 3D isolado (cada herói tem o seu). Render fixo em 240px
	# (supersample p/ nitidez); o Sprite2D reduz pro tamanho de exibição.
	_svp = SubViewport.new()
	var res := 240
	_svp.size = Vector2i(res, res)
	_svp.transparent_bg = true
	_svp.own_world_3d = true
	_svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_svp.msaa_3d = Viewport.MSAA_2X
	add_child(_svp)

	# Mundo 3D: luz + câmera 3/4 enquadrando ~1.8m + o herói.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -34, 0)
	sun.light_energy = 1.35
	_svp.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.68, 0.70, 0.76)
	e.ambient_light_energy = 1.0
	env.environment = e
	_svp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 34.0
	# look_at_from_position: funciona mesmo com a câmera ainda fora da árvore.
	cam.look_at_from_position(Vector3(0.0, 1.35, 3.4), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_svp.add_child(cam)

	rig = HeroRig.new()
	_svp.add_child(rig)
	if not rig.setup(glb):
		return false

	# Sprite 2D que mostra o viewport, reduzido p/ disp_h e ancorado pelos PÉS.
	_spr = Sprite2D.new()
	_spr.texture = _svp.get_texture()
	var s := float(disp_h) / float(res)
	_spr.scale = Vector2(s, s)
	_spr.offset = Vector2(0, -res * 0.40)  # sobe o boneco p/ os pés ficarem no chão
	add_child(_spr)
	return true


## Equipa um item (slot) usando o GLB do prop; ignora se não houver modelo.
func equip(slot: String, item_glb: String) -> void:
	if rig != null and FileAccess.file_exists(item_glb):
		rig.equip(slot, item_glb)
