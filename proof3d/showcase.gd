extends Node3D
## SHOWCASE jogável: todos os heróis 3D equipados, de pé no mapa da fase 1.
## Câmera: setas ← → giram, ↑ ↓ zoom; sem input = giro lento automático. ESC sai.
## Uso: Godot ... res://proof3d/showcase.tscn

const HeroRig = preload("res://scripts/hero_rig_3d.gd")
const MAP_TEX := "res://assets/map/map_elis.png"
const PROPS := "res://assets/models/props/"
const HEROES := ["hercules", "artemis", "hermes", "ares", "atena", "apolo", "medusa", "zeus"]
const LOADOUT := {
	"helmet": "helmet_legend", "armor": "armor_legend", "legs": "legs_legend",
	"boots": "boots_legend", "weapon": "sword_legend", "shield": "shield_legend",
	"amulet": "amulet_legend", "ring": "ring_legend",
}

var _cam: Camera3D
var _yaw := 0.0
var _dist := 6.0
var _auto := true
var _frames := 0
var _shot_done := false


func _ready() -> void:
	_setup_world()
	# 2 fileiras de 4, viradas p/ a câmera, em cima do mapa.
	var xs := [-2.3, -0.8, 0.8, 2.3]
	for i in HEROES.size():
		var hero: String = HEROES[i]
		var glb := "res://assets/models/%s/%s.glb" % [hero, hero]
		if not FileAccess.file_exists(glb):
			continue
		var rig := HeroRig.new()
		add_child(rig)
		rig.position = Vector3(xs[i % 4], 0.0, -0.4 if i < 4 else 1.1)
		rig.rotation_degrees = Vector3(0, 0, 0)  # de frente p/ a câmera inicial
		if rig.setup(glb):
			for slot in LOADOUT:
				var p: String = PROPS + LOADOUT[slot] + ".glb"
				if FileAccess.file_exists(p):
					rig.equip(slot, p)
	print("SHOWCASE: heróis carregados")


func _setup_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -40, 0)
	sun.light_energy = 1.35
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.09, 0.11, 0.15)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.64, 0.70)
	e.ambient_light_energy = 1.0
	env.environment = e
	add_child(env)
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10.6, 6.0)
	plane.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(MAP_TEX)
	mat.roughness = 1.0
	plane.material_override = mat
	add_child(plane)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	add_child(_cam)
	_update_cam()


func _process(delta: float) -> void:
	if _auto:
		_yaw += delta * 0.25
	var move := 0.0
	if Input.is_key_pressed(KEY_LEFT): move -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): move += 1.0
	if move != 0.0:
		_yaw += move * delta * 1.2
		_auto = false
	if Input.is_key_pressed(KEY_UP): _dist = maxf(3.5, _dist - delta * 3.0); _auto = false
	if Input.is_key_pressed(KEY_DOWN): _dist = minf(11.0, _dist + delta * 3.0); _auto = false
	if Input.is_key_pressed(KEY_ESCAPE): get_tree().quit()
	_update_cam()
	# Screenshot único (pro report/verificação), sem fechar a janela.
	_frames += 1
	if not _shot_done and _frames == 120:
		_shot_done = true
		var img := get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("c:/projetos/jogoTD/_shot_showcase.png")
			print("SHOWCASE: screenshot -> _shot_showcase.png")


func _update_cam() -> void:
	var target := Vector3(0.0, 0.9, 0.35)
	_cam.position = target + Vector3(sin(_yaw) * _dist, 2.4, cos(_yaw) * _dist)
	_cam.look_at(target, Vector3.UP)
