class_name Elements
extends RefCounted

## Tipos de dano (elementos). Ciclo: AGUA > FOGO > TERRA > AR > AGUA (cada um forte
## contra o próximo). LUZ e TREVAS são opostos fortes entre si. Forte = +50% dano;
## fraco (inverso) = -25%. Ponto único da regra elemental.

enum E { FOGO, AGUA, TERRA, AR, LUZ, TREVAS }

const NAMES := ["Fogo", "Agua", "Terra", "Ar", "Luz", "Trevas"]
const ICONS := ["🔥", "💧", "⛰", "🌪", "✨", "🌑"]
const STRONG_MULT := 1.5
const WEAK_MULT := 0.75

# Quem cada elemento VENCE (forte contra).
const BEATS := {
	E.AGUA: E.FOGO, E.FOGO: E.TERRA, E.TERRA: E.AR, E.AR: E.AGUA,
	E.LUZ: E.TREVAS, E.TREVAS: E.LUZ,
}

# Elemento de cada personagem (tema). Os que faltam usam um fallback determinístico.
const CHAR := {
	# Grega
	"zeus": E.AR, "poseidon": E.AGUA, "hades": E.TREVAS, "ares": E.FOGO,
	"artemis": E.TERRA, "hermes": E.AR, "hercules": E.TERRA, "atena": E.LUZ,
	"apolo": E.LUZ, "medusa": E.TREVAS,
	# Nordica
	"thor": E.AR, "odin": E.LUZ, "loki": E.TREVAS, "freya": E.LUZ, "tyr": E.TERRA,
	"heimdall": E.LUZ, "ullr": E.TERRA, "frigg": E.AGUA,
	# Egipcia
	"ra": E.FOGO, "anubis": E.TREVAS, "horus": E.AR, "set": E.TREVAS,
	"isis": E.AGUA, "thoth": E.LUZ, "sekhmet": E.FOGO, "neith": E.TERRA,
	# Brasileira
	"iara": E.AGUA, "boitata": E.FOGO, "saci": E.AR, "curupira": E.TERRA,
	"boto": E.AGUA, "cuca": E.TREVAS, "mapinguari": E.TERRA, "anhanga": E.TREVAS,
	# Chinesa
	"longwang": E.AGUA, "sunwukong": E.AR, "nezha": E.FOGO, "guanyu": E.TERRA,
	"houyi": E.LUZ, "nuwa": E.TERRA, "erlang": E.LUZ, "guanyin": E.AGUA,
	# Japonesa
	"amaterasu": E.LUZ, "susanoo": E.AR, "raijin": E.AR, "fujin": E.AR,
	"tsukuyomi": E.TREVAS, "benkei": E.TERRA, "hachiman": E.FOGO, "kannon": E.AGUA,
	# Asteca
	"huitzilo": E.FOGO, "quetzal": E.AR, "tlaloc": E.AGUA, "tezca": E.TREVAS,
	"mixcoatl": E.TERRA, "camazotz": E.TREVAS, "xochi": E.LUZ, "mictlan": E.TREVAS,
}


static func of_character(cid: String) -> int:
	if CHAR.has(cid):
		return CHAR[cid]
	# Fallback determinístico (todos têm um elemento).
	var h := 0
	for c in cid:
		h += c.unicode_at(0)
	return h % 6


## Multiplicador de dano do atacante (att) contra o defensor (def).
static func mult(att: int, defn: int) -> float:
	if att < 0 or defn < 0:
		return 1.0
	if BEATS.get(att, -1) == defn:
		return STRONG_MULT
	if BEATS.get(defn, -1) == att:
		return WEAK_MULT
	return 1.0


static func name_of(e: int) -> String:
	return NAMES[e] if e >= 0 and e < NAMES.size() else "?"


static func color_of(e: int) -> Color:
	match e:
		E.FOGO: return Color(1.0, 0.45, 0.2)
		E.AGUA: return Color(0.3, 0.6, 1.0)
		E.TERRA: return Color(0.6, 0.45, 0.25)
		E.AR: return Color(0.6, 0.95, 0.7)
		E.LUZ: return Color(1.0, 0.95, 0.5)
		E.TREVAS: return Color(0.6, 0.35, 0.85)
	return Color.WHITE
