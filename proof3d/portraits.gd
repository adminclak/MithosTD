extends Node3D
## Renderiza um RETRATO 2D (PNG transparente) de cada herói 3D, p/ usar como ícone
## na lista/cards — assim o visual da UI fica IGUAL ao 3D da batalha (consistência).
## Salva em assets/portraits/<id>.png. Roda com --rendering-driver opengl3.

const HeroRig = preload("res://scripts/hero_rig_3d.gd")
const HEROES := ["hercules", "artemis", "hermes", "ares", "atena", "apolo", "medusa", "zeus"]
const OUT := "c:/projetos/jogoTD/assets/portraits/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for id in HEROES:
		await _render_one(id)
	print("PORTRAITS: pronto")
	get_tree().quit()


func _render_one(id: String) -> void:
	var glb := "res://assets/models/%s/%s.glb" % [id, id]
	if not FileAccess.file_exists(glb):
		return
	var svp := SubViewport.new()
	svp.size = Vector2i(512, 768)
	svp.transparent_bg = true
	svp.own_world_3d = true
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.msaa_3d = Viewport.MSAA_4X
	add_child(svp)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -32, 0)
	sun.light_energy = 1.4
	svp.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.72, 0.78)
	e.ambient_light_energy = 1.0
	env.environment = e
	svp.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 30.0
	# enquadra corpo inteiro de frente (proporção retrato 512x768).
	cam.look_at_from_position(Vector3(0.0, 1.0, 4.0), Vector3(0.0, 0.95, 0.0), Vector3.UP)
	svp.add_child(cam)

	var rig := HeroRig.new()
	svp.add_child(rig)
	if not rig.setup(glb):
		svp.queue_free()
		return

	for _i in 24:
		await get_tree().process_frame
	var img := svp.get_texture().get_image()
	if img != null:
		img.save_png(OUT + id + ".png")
		print("PORTRAITS: ", id)
	svp.queue_free()
	await get_tree().process_frame
