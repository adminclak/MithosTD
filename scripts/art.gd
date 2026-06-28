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


static func hero(id: String) -> Texture2D:
	if id == "":
		return null
	return _load("res://assets/heroes/%s.png" % id)


static func enemy(id: String) -> Texture2D:
	if id == "":
		return null
	return _load("res://assets/enemies/%s.png" % id)


static func map(id: String) -> Texture2D:
	return _load("res://assets/map/%s.png" % id)
