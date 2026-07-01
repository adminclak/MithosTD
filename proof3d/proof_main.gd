extends Node3D
## PROVA DE CONCEITO 2.5D — herói 3D riggado sobre o mapa 2D, com um ITEM
## encaixado no osso da cabeça (BoneAttachment3D). Objetivo: validar que dá pra
## ter equipamento VESTIDO no corpo, em runtime, sem rig manual nem migrar tudo.
##
## Roda: Godot_console.exe --path . --rendering-driver opengl3 res://proof3d/proof.tscn
## Salva: _shot_proof3d.png e sai.

const MODEL_PATH := "res://proof3d/CesiumMan.glb"
## Quando o Hércules 3D real (Meshy) existir, a proof usa ELE no lugar do manequim.
const HERO_GLB := "res://assets/models/hercules/hercules.glb"
const HELMET_GLB := "res://assets/models/props/helmet_bronze.glb"
const MAP_TEX := "res://assets/map/map_elis.png"
## Ajuste fino do elmo sobre a cabeça (tunáveis).
const HELMET_WIDTH := 0.26   ## largura-alvo (m, eixo X = orelha a orelha)
const HELMET_YOFFSET := 0.13 ## sobe o elmo ao longo do EIXO da cabeça
const HELMET_YAW := 0.0      ## correção de giro do modelo do elmo
const HELMET_PITCH := 0.0    ## correção de inclinação do modelo do elmo

var _skel: Skeleton3D = null
var _anim: AnimationPlayer = null
var _helm: Node3D = null
var _helm_scale := 1.0
var _head_ba: BoneAttachment3D = null
var _cam: Camera3D = null
var _live := false  ## --live: janela fica aberta girando a câmera (não captura/sai)
var _t := 0.0


func _ready() -> void:
	_live = OS.get_cmdline_user_args().has("--live")
	_setup_world()
	var char_root := _load_model()
	if char_root != null:
		add_child(char_root)
		_find_nodes(char_root)
		_print_bones()
		_play_walk()
		_attach_helmet()
	if _live:
		return  # janela aberta; _process cuida do elmo + giro da câmera
	# Espera renderizar alguns frames (o renderer real precisa de tempo) e captura.
	await _capture_after_frames(40)


func _setup_world() -> void:
	# Luz + ambiente claro.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.3
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.12, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.68)
	e.ambient_light_energy = 1.0
	env.environment = e
	add_child(env)

	# CHÃO = o mapa 2D pintado, deitado no plano XZ (a "mesa" do tower defense).
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7.1, 4.0)  # proporção 16:9, dimensionado p/ ver o herói grande
	plane.mesh = pm
	var mat := StandardMaterial3D.new()
	var tex: Texture2D = load(MAP_TEX)
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 1.0
	plane.material_override = mat
	add_child(plane)

	# Câmera angulada estilo Kingdom Rush (de cima e de lado).
	# IMPORTANTE: entrar na árvore ANTES de look_at (precisa do transform global).
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.position = Vector3(0.0, 2.0, 2.7)
	cam.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	_cam = cam


func _load_model() -> Node3D:
	# Prefere o Hércules 3D real (Meshy) se já estiver na pasta; senão, o manequim.
	var is_hero := FileAccess.file_exists(HERO_GLB)
	var path := HERO_GLB if is_hero else MODEL_PATH
	print("PROOF: carregando ", path)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		push_error("Falha ao carregar glTF: %d" % err)
		return null
	var scene := doc.generate_scene(state)
	if scene == null:
		return null
	var n := scene as Node3D
	if n != null:
		# Rotação 0 = de frente p/ a câmera. CesiumMan (~1.6m) precisa de leve upscale.
		n.rotation_degrees = Vector3(0, 0, 0)
		n.scale = Vector3(1.0, 1.0, 1.0) if is_hero else Vector3(1.2, 1.2, 1.2)
		n.position = Vector3(0, 0, 0)
	return n


func _find_nodes(root: Node) -> void:
	for c in root.get_children():
		if c is Skeleton3D and _skel == null:
			_skel = c
		if c is AnimationPlayer and _anim == null:
			_anim = c
		_find_nodes(c)


func _print_bones() -> void:
	if _skel == null:
		print("PROOF: nenhum Skeleton3D encontrado")
		return
	print("PROOF: Skeleton3D com %d ossos:" % _skel.get_bone_count())
	for i in _skel.get_bone_count():
		print("  [%d] %s" % [i, _skel.get_bone_name(i)])


func _play_walk() -> void:
	if _anim == null:
		print("PROOF: nenhum AnimationPlayer")
		return
	var list := _anim.get_animation_list()
	print("PROOF: animacoes: ", list)
	if list.size() > 0:
		var a: String = list[0]
		var anim := _anim.get_animation(a)
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR
		_anim.play(a)
		# Avança a animação p/ uma pose de passada (não o frame 0 parado).
		_anim.seek(anim.length * 0.4 if anim != null else 0.4, true)


func _attach_helmet() -> void:
	if _skel == null:
		return
	# 1ª preferência: osso "head" de verdade (NÃO o "head_end", que é o topo do crânio).
	var head := -1
	for i in _skel.get_bone_count():
		var nm := _skel.get_bone_name(i).to_lower()
		if "head" in nm and not ("end" in nm):
			head = i
			break
	# Fallback: qualquer head/neck/skull mais alto (ex.: CesiumMan só tem "neck").
	if head < 0:
		var head_y := -INF
		for i in _skel.get_bone_count():
			var nm := _skel.get_bone_name(i).to_lower()
			if "head" in nm or "neck" in nm or "skull" in nm:
				var y := _skel.get_bone_global_pose(i).origin.y
				if y > head_y:
					head_y = y
					head = i
	if head < 0:
		head = _topmost_bone()
	print("PROOF: encaixando capacete no osso [%d] %s" % [head, _skel.get_bone_name(head)])

	var ba := BoneAttachment3D.new()
	ba.bone_name = _skel.get_bone_name(head)
	_skel.add_child(ba)
	_head_ba = ba

	# ELMO REAL (malha 3D do Meshy) encaixado na cabeça. Fica como filho da CENA e é
	# reposicionado em _process (posição do osso + up do MUNDO) -> assenta certo sem
	# depender da orientação do osso. Normaliza escala e recentraliza a malha.
	var helm_root := _load_glb(HELMET_GLB)
	if helm_root == null:
		print("PROOF: elmo nao encontrado, pulando")
		return
	var mi := _first_mesh(helm_root)
	var wrapper := Node3D.new()
	if mi != null and mi.mesh != null:
		var aabb := mi.mesh.get_aabb()
		# recentraliza a malha no origin do wrapper e guarda a escala (largura X).
		helm_root.position = -aabb.get_center()
		_helm_scale = HELMET_WIDTH / maxf(aabb.size.x, 0.001)
	wrapper.add_child(helm_root)
	add_child(wrapper)
	_helm = wrapper


func _process(delta: float) -> void:
	# O elmo segue a ORIENTAÇÃO COMPLETA do osso da cabeça (posição + rotação) ->
	# fica colado de qualquer ângulo e em qualquer animação. Offset ao longo do
	# eixo Y do PRÓPRIO osso (topo da cabeça), + correção de giro/inclinação do modelo.
	if _helm != null and _head_ba != null and is_instance_valid(_helm) and is_instance_valid(_head_ba):
		var bt := _head_ba.global_transform.orthonormalized()
		var corr := Basis.from_euler(Vector3(deg_to_rad(HELMET_PITCH), deg_to_rad(HELMET_YAW), 0.0))
		var basis := (bt.basis * corr).scaled(Vector3.ONE * _helm_scale)
		_helm.global_transform = Transform3D(basis, bt.origin + bt.basis.y * HELMET_YOFFSET)
	# Modo live: gira a câmera devagar em torno do herói pra ver em 3D.
	if _live and _cam != null:
		_t += delta
		var r := 3.0
		_cam.position = Vector3(sin(_t * 0.5) * r, 2.0, cos(_t * 0.5) * r)
		_cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _load_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D


func _first_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root
	for c in root.get_children():
		var m := _first_mesh(c)
		if m != null:
			return m
	return null


func _topmost_bone() -> int:
	# Heurística: o osso com maior Y na pose de repouso (cabeça costuma ser o mais alto).
	var best := 0
	var best_y := -INF
	for i in _skel.get_bone_count():
		var t := _skel.get_bone_global_pose(i)
		if t.origin.y > best_y:
			best_y = t.origin.y
			best = i
	return best


func _capture_after_frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
	await get_tree().process_frame
	_save("c:/projetos/jogoTD/_shot_proof3d.png")
	# Ângulo 3/4 lateral p/ conferir o elmo de outro lado.
	if _cam != null:
		_cam.position = Vector3(2.5, 2.0, 1.6)
		_cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		for _i in 8:
			await get_tree().process_frame
		_save("c:/projetos/jogoTD/_shot_proof3d_side.png")
	get_tree().quit()


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("PROOF: screenshot -> ", path)
