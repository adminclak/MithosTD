extends Node3D
## Validação de encaixe: carrega UM herói e veste TODOS os equipamentos (1 de cada
## slot) no mapa da fase 1. Salva _shot_equip_<hero>.png (frente) e _side.
## Uso: Godot ... res://proof3d/validate.tscn -- --hero ares [--live]

const HeroRig = preload("res://scripts/hero_rig_3d.gd")
const MAP_TEX := "res://assets/map/map_elis.png"
const PROPS := "res://assets/models/props/"
## slot -> item lendário
const LOADOUT := {
	"helmet": "helmet_legend", "armor": "armor_legend", "legs": "legs_legend",
	"boots": "boots_legend", "weapon": "sword_legend", "shield": "shield_legend",
	"amulet": "amulet_legend", "ring": "ring_legend",
}

var _cam: Camera3D
var _live := false
var _t := 0.0
var _rig: Node3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_live = args.has("--live")
	var hero := "hercules"
	for i in args.size():
		if args[i] == "--hero" and i + 1 < args.size():
			hero = args[i + 1]
	_setup_world()
	_rig = HeroRig.new()
	add_child(_rig)
	var ok: bool = _rig.setup("res://assets/models/%s/%s.glb" % [hero, hero])
	if ok:
		for slot in LOADOUT:
			var p: String = PROPS + LOADOUT[slot] + ".glb"
			if FileAccess.file_exists(p):
				_rig.equip(slot, p)
	print("VALIDATE: herói=%s equipado" % hero)
	if _live:
		return
	await _shoot(hero)


func _setup_world() -> void:
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
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7.1, 4.0)
	plane.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(MAP_TEX)
	mat.roughness = 1.0
	plane.material_override = mat
	add_child(plane)
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.position = Vector3(0.0, 1.95, 3.2)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_cam = cam


func _process(delta: float) -> void:
	if _live and _cam != null:
		_t += delta
		var r := 3.3
		_cam.position = Vector3(sin(_t * 0.5) * r, 2.0, cos(_t * 0.5) * r)
		_cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _shoot(hero: String) -> void:
	for _i in 45:
		await get_tree().process_frame
	_save("c:/projetos/jogoTD/_shot_equip_%s.png" % hero)
	if _cam != null:
		_cam.position = Vector3(2.6, 2.0, 1.7)
		_cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		for _i in 8:
			await get_tree().process_frame
		_save("c:/projetos/jogoTD/_shot_equip_%s_side.png" % hero)
	get_tree().quit()


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("VALIDATE: screenshot -> ", path)
