class_name UiTheme
extends RefCounted

## Tema visual global (fonte de jogo + molduras 9-slice do kit Kenney CC0).
## Construído uma vez e aplicado à janela (todas as telas herdam). Mantém
## helpers antigos (style_button/panel_box) por compatibilidade.

const GOLD := Color(0.95, 0.78, 0.30)
const TEXT := Color(0.96, 0.93, 0.84)

static var _theme: Theme = null
static var _font_body: Font = null
static var _font_title: Font = null


static func _load(path: String):
	return load(path) if ResourceLoader.exists(path) else null


static func body_font() -> Font:
	if _font_body == null:
		_font_body = _load("res://assets/fonts/Jersey15-Regular.ttf")
	return _font_body


static func title_font() -> Font:
	if _font_title == null:
		_font_title = _load("res://assets/fonts/PressStart2P-Regular.ttf")
	return _font_title


## Fonte de título elegante (serifada, mitológica) para logos/cabeçalhos grandes.
static var _font_fancy: Font = null
static func fancy_font() -> Font:
	if _font_fancy == null:
		_font_fancy = _load("res://assets/fonts/CinzelDecorative-Bold.ttf")
	return _font_fancy


static func _sb(path: String, tm: int, cl: int, ct: int, cr: int, cb: int) -> StyleBox:
	var tex = _load(path)
	if tex == null:
		var fb := StyleBoxFlat.new()
		fb.bg_color = Color(0.16, 0.14, 0.20, 0.95)
		fb.set_corner_radius_all(8)
		fb.set_border_width_all(2)
		fb.border_color = GOLD
		return fb
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = tm
	sb.texture_margin_right = tm
	sb.texture_margin_top = tm
	sb.texture_margin_bottom = tm + 4
	sb.content_margin_left = cl
	sb.content_margin_top = ct
	sb.content_margin_right = cr
	sb.content_margin_bottom = cb
	return sb


static func build_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var bf := body_font()
	if bf != null:
		t.default_font = bf
	t.default_font_size = 20

	# Botões (molduras Kenney).
	t.set_stylebox("normal", "Button", _sb("res://assets/ui/btn.png", 22, 18, 10, 18, 18))
	t.set_stylebox("hover", "Button", _sb("res://assets/ui/btn_hover.png", 22, 18, 10, 18, 18))
	t.set_stylebox("pressed", "Button", _sb("res://assets/ui/btn_press.png", 22, 18, 12, 18, 14))
	t.set_stylebox("disabled", "Button", _sb("res://assets/ui/btn.png", 22, 18, 10, 18, 18))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.55, 0.58))
	t.set_font_size("font_size", "Button", 20)

	# CheckButton herda visual de botão simples.
	t.set_color("font_color", "CheckButton", TEXT)

	# Painéis.
	var panel_sb := _sb("res://assets/ui/panel.png", 24, 16, 16, 16, 16)
	t.set_stylebox("panel", "Panel", panel_sb)
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	# Labels.
	t.set_color("font_color", "Label", TEXT)

	# ScrollContainer mais discreto (sem moldura).
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	_theme = t
	return t


## Aplica o tema à janela (todas as telas herdam).
static func apply(win: Window) -> void:
	if win != null:
		win.theme = build_theme()


# --- Compat: agora o tema global cuida; mantido p/ não quebrar chamadas ---
static func style_button(_b: Button) -> void:
	pass


static func panel_box(_alpha: float = 0.82) -> StyleBox:
	return _sb("res://assets/ui/panel.png", 24, 16, 16, 16, 16)
