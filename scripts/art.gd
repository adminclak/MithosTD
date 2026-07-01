class_name Art
extends RefCounted

## Carregador de sprites opcional. Se existir uma imagem em assets/, ela é usada;
## senão, a entidade desenha um placeholder (boneco) via código. Assim você pode
## ir adicionando arte aos poucos (ver assets/ARTE.md) sem mexer no código.
##
## Convenção:
##   res://assets/heroes/<id_do_personagem>.png   (ex.: zeus.png, artemis.png)
##   res://assets/enemies/<id_do_inimigo>.png      (ex.: lacaio.png, talos.png)

static var _cache: Dictionary = {}


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_cache[path] = tex
	return tex


## Carrega um PNG direto do disco (sem depender do import do Godot). Usado pelos
## retratos 3D gerados em runtime.
static func _load_disk(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	var f := FileAccess.open(path, FileAccess.READ)
	if f != null:
		var img := Image.new()
		if img.load_png_from_buffer(f.get_buffer(f.get_length())) == OK:
			tex = ImageTexture.create_from_image(img)
	_cache[path] = tex
	return tex


static func hero(id: String) -> Texture2D:
	if id == "":
		return null
	# Prioriza o RETRATO 3D (visual coeso com a batalha); senão a arte 2D antiga.
	var portrait := "res://assets/portraits/%s.png" % id
	if FileAccess.file_exists(portrait):
		return _load_disk(portrait)
	return _load("res://assets/heroes/%s.png" % id)


static func enemy(id: String) -> Texture2D:
	if id == "":
		return null
	return _load("res://assets/enemies/%s.png" % id)


static func map(id: String) -> Texture2D:
	return _load("res://assets/map/%s.png" % id)


static func item(icon_id: String) -> Texture2D:
	if icon_id == "":
		return null
	return _load("res://assets/items/%s.png" % icon_id)


static func ui(name: String) -> Texture2D:
	return _load("res://assets/ui/%s.png" % name)
