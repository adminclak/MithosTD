extends Node3D
## HeroRig3D — carrega um herói 3D (GLB do Meshy), toca idle e ENCAIXA equipamento
## por SLOT no osso certo. Base reutilizável (tela de Equipar + batalha 2.5D).
##
## Princípio: todos os heróis usam o MESMO esqueleto humanoide (mesmos nomes de osso:
## Head, Spine02, Hips, RightHand, LeftForeArm, LeftFoot...) e a MESMA altura
## (height_meters=1.8 no rig do Meshy). Por isso UMA config de encaixe por slot
## (MOUNT) serve pra TODOS os heróis — o equipamento é gerado 1x e veste todo mundo.
##
## Uso:
##   var rig = preload("res://scripts/hero_rig_3d.gd").new()
##   add_child(rig); rig.setup("res://assets/models/hercules/hercules.glb")
##   rig.equip("helmet", "res://assets/models/props/helmet_legend.glb")

## slot -> encaixe. `bones`: osso(s) alvo (botas = 2 pés). `w`: largura-alvo em metros
## (escala a malha). `off`: deslocamento em ESPAÇO DO OSSO (x=lado, y=eixo do osso,
## z=frente). `rot`: correção de giro do modelo (graus). Valores afinados por render.
## `w` = tamanho-alvo da MAIOR dimensão da malha (m). Afinado por render.
const MOUNT := {
	"helmet": {"bones": ["Head"],                 "w": 0.42, "off": Vector3(0, 0.20, 0.00), "rot": Vector3(0, 0, 0)},
	"armor":  {"bones": ["Spine02", "Spine01", "Spine"], "w": 0.55, "off": Vector3(0, 0.10, 0.09), "rot": Vector3(0, 0, 0)},
	"legs":   {"bones": ["Hips"],                 "w": 0.48, "off": Vector3(0, -0.16, 0.06), "rot": Vector3(0, 0, 0)},
	"boots":  {"bones": ["LeftFoot", "RightFoot"],"w": 0.22, "off": Vector3(0, 0.02, 0.03), "rot": Vector3(0, 0, 0)},
	"weapon": {"bones": ["RightHand"],            "w": 0.75, "off": Vector3(0, 0.02, 0.00), "rot": Vector3(0, 0, 90)},
	"shield": {"bones": ["LeftForeArm", "LeftArm"],"w": 0.45, "off": Vector3(0, 0.06, -0.08), "rot": Vector3(90, 0, 0)},
	"amulet": {"bones": ["Spine02", "Neck"],      "w": 0.16, "off": Vector3(0, 0.04, 0.11), "rot": Vector3(0, 0, 0)},
	"ring":   {"bones": ["RightHand"],            "w": 0.07, "off": Vector3(0, 0.03, 0.00), "rot": Vector3(0, 0, 0)},
	"bow":    {"bones": ["LeftHand"],             "w": 0.95, "off": Vector3(0, 0.03, 0.00), "rot": Vector3(0, 0, 0)},
}

var skeleton: Skeleton3D = null
var anim: AnimationPlayer = null
var _mounts: Array = []  ## [{ba, node, cfg, scale}]


func setup(hero_glb: String, play_idle: bool = true) -> bool:
	var root := _load_glb(hero_glb)
	if root == null:
		push_error("HeroRig3D: falha ao carregar " + hero_glb)
		return false
	add_child(root)
	skeleton = _find(root, "Skeleton3D")
	anim = _find(root, "AnimationPlayer")
	if play_idle and anim != null and anim.get_animation_list().size() > 0:
		var a: String = anim.get_animation_list()[0]
		var clip := anim.get_animation(a)
		if clip != null:
			clip.loop_mode = Animation.LOOP_LINEAR
		anim.play(a)
	return skeleton != null


## Encaixa (ou troca) o item no slot. glb vazio = só remove.
func equip(slot: String, item_glb: String) -> void:
	if not MOUNT.has(slot) or skeleton == null:
		return
	unequip(slot)
	var cfg: Dictionary = MOUNT[slot]
	var bone_name := _first_existing_bone(cfg["bones"])
	if bone_name == "":
		return
	# Botas: mesmo item nos dois pés.
	var targets: Array = cfg["bones"] if slot == "boots" else [bone_name]
	for bn in targets:
		if skeleton.find_bone(bn) < 0:
			continue
		var item := _load_glb(item_glb)
		if item == null:
			continue
		var scale := _fit_scale(item, cfg["w"])
		var ba := BoneAttachment3D.new()
		ba.bone_name = bn
		skeleton.add_child(ba)
		var wrapper := Node3D.new()
		wrapper.add_child(item)
		add_child(wrapper)  # filho da cena; seguimos o osso em _process
		_mounts.append({"slot": slot, "ba": ba, "node": wrapper, "cfg": cfg, "scale": scale})


func unequip(slot: String) -> void:
	for m in _mounts.duplicate():
		if m["slot"] == slot:
			if is_instance_valid(m["ba"]):
				m["ba"].queue_free()
			if is_instance_valid(m["node"]):
				m["node"].queue_free()
			_mounts.erase(m)


func _process(_delta: float) -> void:
	# Cada item segue a ORIENTAÇÃO COMPLETA do osso (posição + rotação) -> fica colado
	# de qualquer ângulo e em qualquer animação. Offset no espaço do próprio osso.
	for m in _mounts:
		if not (is_instance_valid(m["ba"]) and is_instance_valid(m["node"])):
			continue
		var cfg: Dictionary = m["cfg"]
		var bt: Transform3D = m["ba"].global_transform.orthonormalized()
		var corr := Basis.from_euler(Vector3(
			deg_to_rad(cfg["rot"].x), deg_to_rad(cfg["rot"].y), deg_to_rad(cfg["rot"].z)))
		var basis := (bt.basis * corr).scaled(Vector3.ONE * m["scale"])
		var origin: Vector3 = bt.origin + bt.basis * cfg["off"]
		m["node"].global_transform = Transform3D(basis, origin)


# ---------- helpers ----------
func _first_existing_bone(names: Array) -> String:
	for n in names:
		if skeleton.find_bone(n) >= 0:
			return n
	return ""


func _fit_scale(item_root: Node3D, target_w: float) -> float:
	var mi := _first_mesh(item_root)
	if mi == null or mi.mesh == null:
		return 1.0
	var aabb := mi.mesh.get_aabb()
	# recentraliza a malha no origin do item_root
	item_root.position = -aabb.get_center()
	var wdim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	return target_w / maxf(wdim, 0.001)


func _load_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D


func _find(root: Node, cls: String) -> Node:
	if root.get_class() == cls:
		return root
	for c in root.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null


func _first_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root
	for c in root.get_children():
		var m := _first_mesh(c)
		if m != null:
			return m
	return null
